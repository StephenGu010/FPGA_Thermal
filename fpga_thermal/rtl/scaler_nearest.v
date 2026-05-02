// -----------------------------------------------------------------------------
// Module: scaler_nearest
// Function: P0 frame-buffered nearest-neighbor scaler.
// Timing: captures one ROI frame, then emits one scaled pixel per clk.
// -----------------------------------------------------------------------------
`timescale 1ns/1ps
module scaler_nearest #(
    parameter MAX_IN_WIDTH = 256,
    parameter MAX_IN_HEIGHT = 192,
    parameter PIXEL_WIDTH = 8
) (
    input wire clk,
    input wire rst_n,
    input wire [PIXEL_WIDTH-1:0] pixel_in,
    input wire in_valid,
    input wire in_frame_start,
    input wire in_frame_end,
    input wire [15:0] in_x,
    input wire [15:0] in_y,
    input wire [15:0] in_width,
    input wire [15:0] in_height,
    input wire [15:0] out_width_cfg,
    input wire [15:0] out_height_cfg,
    output reg [PIXEL_WIDTH-1:0] pixel_out,
    output reg out_valid,
    output reg out_frame_start,
    output reg out_frame_end,
    output reg [15:0] out_x,
    output reg [15:0] out_y,
    output reg busy
);
localparam MEM_PIXELS = MAX_IN_WIDTH * MAX_IN_HEIGHT;
reg [PIXEL_WIDTH-1:0] frame_mem [0:MEM_PIXELS-1] /* synthesis syn_ramstyle="block_ram" */;
reg [15:0] src_w, src_h, dst_w, dst_h, ox, oy;
reg [15:0] src_x_idx, src_y_idx;
reg [31:0] err_x, err_y, err_tmp;
reg [31:0] addr;
reg output_active;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        pixel_out <= 0; out_valid <= 0; out_frame_start <= 0; out_frame_end <= 0; out_x <= 0; out_y <= 0;
        busy <= 0; src_w <= 1; src_h <= 1; dst_w <= 1; dst_h <= 1; ox <= 0; oy <= 0;
        src_x_idx <= 0; src_y_idx <= 0; err_x <= 0; err_y <= 0; output_active <= 0;
    end else begin
        out_valid <= 0; out_frame_start <= 0; out_frame_end <= 0;
        if (in_valid) begin
            frame_mem[in_y * MAX_IN_WIDTH + in_x] <= pixel_in;
            if (in_frame_start) begin src_w <= in_width; src_h <= in_height; dst_w <= out_width_cfg; dst_h <= out_height_cfg; end
            if (in_frame_end) begin
                ox <= 0; oy <= 0; src_x_idx <= 0; src_y_idx <= 0; err_x <= 0; err_y <= 0;
                output_active <= 1'b1; busy <= 1'b1;
            end
        end
        if (output_active) begin
            addr = src_y_idx * MAX_IN_WIDTH + src_x_idx;
            pixel_out <= frame_mem[addr];
            out_valid <= 1'b1;
            out_frame_start <= (ox == 0) && (oy == 0);
            out_frame_end <= (ox == dst_w - 1) && (oy == dst_h - 1);
            out_x <= ox; out_y <= oy;
            if ((ox == dst_w - 1) && (oy == dst_h - 1)) begin
                output_active <= 0; busy <= 0;
            end else if (ox == dst_w - 1) begin
                ox <= 0; oy <= oy + 1'b1; src_x_idx <= 0; err_x <= 0;
                err_tmp = err_y + src_h;
                if (err_tmp >= dst_h) begin err_tmp = err_tmp - dst_h; src_y_idx <= src_y_idx + 1'b1; end
                if (err_tmp >= dst_h) begin err_tmp = err_tmp - dst_h; src_y_idx <= src_y_idx + 2'd2; end
                err_y <= err_tmp;
            end else begin
                ox <= ox + 1'b1;
                err_tmp = err_x + src_w;
                if (err_tmp >= dst_w) begin err_tmp = err_tmp - dst_w; src_x_idx <= src_x_idx + 1'b1; end
                if (err_tmp >= dst_w) begin err_tmp = err_tmp - dst_w; src_x_idx <= src_x_idx + 2'd2; end
                err_x <= err_tmp;
            end
        end
    end
end
endmodule
