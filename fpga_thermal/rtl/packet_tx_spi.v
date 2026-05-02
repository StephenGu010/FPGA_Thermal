// -----------------------------------------------------------------------------
// Module: packet_tx_spi
// Function: SPI master sends 40-byte header, payload stream, CRC16-CCITT tail.
// Timing: payload_ready asks for one byte; payload_data stable with valid+ready.
// -----------------------------------------------------------------------------
`timescale 1ns/1ps
module packet_tx_spi #(
    parameter CLK_DIV = 2
) (
    input wire clk,
    input wire rst_n,
    input wire start,
    input wire [15:0] frame_id,
    input wire [15:0] display_width,
    input wire [15:0] display_height,
    input wire [15:0] thumb_width,
    input wire [15:0] thumb_height,
    input wire [15:0] flags,
    input wire [15:0] raw_min,
    input wire [15:0] raw_max,
    input wire [15:0] raw_center,
    input wire [15:0] raw_hotspot,
    input wire [15:0] hotspot_x,
    input wire [15:0] hotspot_y,
    input wire [31:0] candidate_count,
    input wire [15:0] candidate_cx,
    input wire [15:0] candidate_cy,
    input wire [31:0] payload_len,
    input wire [15:0] header_checksum,
    input wire [7:0] payload_data,
    input wire payload_valid,
    input wire payload_last,
    output reg payload_ready,
    output reg spi_cs_n,
    output reg spi_sclk,
    output reg spi_mosi,
    output reg busy,
    output reg done,
    output reg [15:0] crc_out
);
localparam HEADER_BYTES = 40;
localparam ST_IDLE=0, ST_HEADER=1, ST_PAYLOAD=2, ST_CRC_H=3, ST_CRC_L=4, ST_DONE=5;
reg [2:0] state;
reg [7:0] tx_byte, header_idx;
reg [2:0] bit_idx;
reg [15:0] div_cnt, crc;
reg [31:0] payload_count;
reg byte_active;
function [7:0] header_byte; input [7:0] idx; begin
    case (idx)
        0: header_byte=8'h55; 1: header_byte=8'hAA;
        2: header_byte=frame_id[15:8]; 3: header_byte=frame_id[7:0];
        4: header_byte=display_width[15:8]; 5: header_byte=display_width[7:0];
        6: header_byte=display_height[15:8]; 7: header_byte=display_height[7:0];
        8: header_byte=thumb_width[15:8]; 9: header_byte=thumb_width[7:0];
        10: header_byte=thumb_height[15:8]; 11: header_byte=thumb_height[7:0];
        12: header_byte=flags[15:8]; 13: header_byte=flags[7:0];
        14: header_byte=raw_min[15:8]; 15: header_byte=raw_min[7:0];
        16: header_byte=raw_max[15:8]; 17: header_byte=raw_max[7:0];
        18: header_byte=raw_center[15:8]; 19: header_byte=raw_center[7:0];
        20: header_byte=raw_hotspot[15:8]; 21: header_byte=raw_hotspot[7:0];
        22: header_byte=hotspot_x[15:8]; 23: header_byte=hotspot_x[7:0];
        24: header_byte=hotspot_y[15:8]; 25: header_byte=hotspot_y[7:0];
        26: header_byte=candidate_count[31:24]; 27: header_byte=candidate_count[23:16];
        28: header_byte=candidate_count[15:8]; 29: header_byte=candidate_count[7:0];
        30: header_byte=candidate_cx[15:8]; 31: header_byte=candidate_cx[7:0];
        32: header_byte=candidate_cy[15:8]; 33: header_byte=candidate_cy[7:0];
        34: header_byte=payload_len[31:24]; 35: header_byte=payload_len[23:16];
        36: header_byte=payload_len[15:8]; 37: header_byte=payload_len[7:0];
        38: header_byte=header_checksum[15:8]; 39: header_byte=header_checksum[7:0];
        default: header_byte=0;
    endcase
end endfunction
function [15:0] crc16_next; input [15:0] crc_in; input [7:0] data; integer i; reg [15:0] c; begin
    c = crc_in ^ {data, 8'd0};
    for (i=0; i<8; i=i+1) c = c[15] ? ((c << 1) ^ 16'h1021) : (c << 1);
    crc16_next = c;
end endfunction
task load_byte; input [7:0] b; input update_crc; begin
    tx_byte <= b; spi_mosi <= b[7]; bit_idx <= 3'd7; div_cnt <= 0; spi_sclk <= 0; byte_active <= 1'b1;
    if (update_crc) crc <= crc16_next(crc, b);
end endtask
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state <= ST_IDLE; tx_byte <= 0; bit_idx <= 0; div_cnt <= 0; byte_active <= 0; header_idx <= 0;
        payload_count <= 0; crc <= 16'hFFFF; crc_out <= 16'hFFFF; payload_ready <= 0;
        spi_cs_n <= 1; spi_sclk <= 0; spi_mosi <= 0; busy <= 0; done <= 0;
    end else begin
        done <= 0; payload_ready <= 0;
        if (byte_active) begin
            if (div_cnt == CLK_DIV - 1) begin
                div_cnt <= 0;
                if (!spi_sclk) spi_sclk <= 1'b1;
                else begin
                    spi_sclk <= 1'b0;
                    if (bit_idx == 0) byte_active <= 1'b0;
                    else begin bit_idx <= bit_idx - 1'b1; spi_mosi <= tx_byte[bit_idx - 1]; end
                end
            end else div_cnt <= div_cnt + 1'b1;
        end else begin
            case (state)
                ST_IDLE: begin
                    spi_cs_n <= 1; busy <= 0;
                    if (start) begin
                        spi_cs_n <= 0; busy <= 1; header_idx <= 0; payload_count <= 0; state <= ST_HEADER;
                        load_byte(header_byte(0), 1'b0);
                        crc <= crc16_next(16'hFFFF, header_byte(0));
                    end
                end
                ST_HEADER: begin
                    if (header_idx == HEADER_BYTES - 1) begin
                        if (payload_len == 0) begin crc_out <= crc; state <= ST_CRC_H; end
                        else state <= ST_PAYLOAD;
                    end else begin header_idx <= header_idx + 1'b1; load_byte(header_byte(header_idx + 1'b1), 1'b1); end
                end
                ST_PAYLOAD: begin
                    payload_ready <= 1'b1;
                    if (payload_valid) begin
                        load_byte(payload_data, 1'b1);
                        payload_count <= payload_count + 1'b1;
                        if (payload_last || payload_count == payload_len - 1) begin crc_out <= crc16_next(crc, payload_data); state <= ST_CRC_H; end
                    end
                end
                ST_CRC_H: begin state <= ST_CRC_L; load_byte(crc_out[15:8], 1'b0); end
                ST_CRC_L: begin state <= ST_DONE; load_byte(crc_out[7:0], 1'b0); end
                ST_DONE: begin spi_cs_n <= 1; busy <= 0; done <= 1'b1; state <= ST_IDLE; end
                default: state <= ST_IDLE;
            endcase
        end
    end
end
endmodule
