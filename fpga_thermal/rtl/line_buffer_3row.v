// -----------------------------------------------------------------------------
// Module: line_buffer_3row
// Function: previous two row pixels plus current pixel at the same x.
// Timing: one clock latency; assumes raster x from 0 to WIDTH-1.
// -----------------------------------------------------------------------------
`timescale 1ns/1ps
module line_buffer_3row #(
    parameter WIDTH = 294,
    parameter PIXEL_WIDTH = 8
) (
    input wire clk,
    input wire rst_n,
    input wire [PIXEL_WIDTH-1:0] pixel_in,
    input wire in_valid,
    input wire [15:0] in_x,
    input wire [15:0] in_y,
    output reg [PIXEL_WIDTH-1:0] row0_pixel,
    output reg [PIXEL_WIDTH-1:0] row1_pixel,
    output reg [PIXEL_WIDTH-1:0] row2_pixel,
    output reg out_valid,
    output reg [15:0] out_x,
    output reg [15:0] out_y
);
reg [PIXEL_WIDTH-1:0] line0 [0:WIDTH-1];
reg [PIXEL_WIDTH-1:0] line1 [0:WIDTH-1];
integer i;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        row0_pixel <= 0; row1_pixel <= 0; row2_pixel <= 0; out_valid <= 0; out_x <= 0; out_y <= 0;
        for (i = 0; i < WIDTH; i = i + 1) begin line0[i] <= 0; line1[i] <= 0; end
    end else begin
        out_valid <= 0;
        if (in_valid) begin
            row0_pixel <= (in_y >= 2) ? line1[in_x] : 0;
            row1_pixel <= (in_y >= 1) ? line0[in_x] : 0;
            row2_pixel <= pixel_in;
            line1[in_x] <= line0[in_x];
            line0[in_x] <= pixel_in;
            out_valid <= 1'b1; out_x <= in_x; out_y <= in_y;
        end
    end
end
endmodule
