// -----------------------------------------------------------------------------
// Module: spi_rx_tiny1c
// Function: generic SPI-like 16-bit raw pixel receiver for Tiny1-C bring-up.
// Timing: clk must oversample spi_sclk; mosi is sampled on spi_sclk rising edge.
// Outputs: pixel_valid aligns with pixel_data/x/y; frame_start/end are pulses.
// -----------------------------------------------------------------------------
`timescale 1ns/1ps
module spi_rx_tiny1c #(
    parameter FRAME_WIDTH = 256,
    parameter FRAME_HEIGHT = 192,
    parameter BITS_PER_PIXEL = 16
) (
    input wire clk,
    input wire rst_n,
    input wire spi_sclk,
    input wire spi_cs_n,
    input wire spi_mosi,
    input wire frame_sync,
    output reg [15:0] pixel_data,
    output reg pixel_valid,
    output reg frame_start,
    output reg frame_end,
    output reg frame_error,
    output reg [15:0] x,
    output reg [15:0] y
);
reg [2:0] sclk_sync;
reg [2:0] cs_sync;
reg [2:0] fs_sync;
wire sclk_rise = (sclk_sync[2:1] == 2'b01);
wire cs_active = ~cs_sync[2];
wire fs_rise = (fs_sync[2:1] == 2'b01);
reg [15:0] shreg;
reg [5:0] bit_count;
reg frame_full;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        sclk_sync <= 3'b000; cs_sync <= 3'b111; fs_sync <= 3'b000;
    end else begin
        sclk_sync <= {sclk_sync[1:0], spi_sclk};
        cs_sync <= {cs_sync[1:0], spi_cs_n};
        fs_sync <= {fs_sync[1:0], frame_sync};
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        pixel_data <= 0; pixel_valid <= 0; frame_start <= 0; frame_end <= 0;
        frame_error <= 0; x <= 0; y <= 0; shreg <= 0; bit_count <= 0; frame_full <= 0;
    end else begin
        pixel_valid <= 0; frame_start <= 0; frame_end <= 0; frame_error <= 0;
        if (fs_rise) begin
            x <= 0; y <= 0; bit_count <= 0; frame_full <= 0;
        end
        if (!cs_active) begin
            bit_count <= 0;
        end else if (sclk_rise) begin
            shreg <= {shreg[14:0], spi_mosi};
            if (bit_count == BITS_PER_PIXEL - 1) begin
                pixel_data <= {shreg[14:0], spi_mosi};
                pixel_valid <= 1'b1;
                frame_start <= (x == 0) && (y == 0);
                frame_end <= (x == FRAME_WIDTH - 1) && (y == FRAME_HEIGHT - 1);
                if (frame_full) frame_error <= 1'b1;
                if ((x == FRAME_WIDTH - 1) && (y == FRAME_HEIGHT - 1)) begin
                    frame_full <= 1'b1; x <= 0; y <= 0;
                end else if (x == FRAME_WIDTH - 1) begin
                    x <= 0; y <= y + 1'b1;
                end else begin
                    x <= x + 1'b1;
                end
                bit_count <= 0;
            end else begin
                bit_count <= bit_count + 1'b1;
            end
        end
    end
end
endmodule
