// -----------------------------------------------------------------------------
// Module: roi_crop
// Function: rectangular ROI crop. Source x/y are absolute; output x/y are relative.
// Timing: one clock latency. Pixels outside ROI are dropped.
// -----------------------------------------------------------------------------
`timescale 1ns/1ps
module roi_crop #(
    parameter PIXEL_WIDTH = 8
) (
    input wire clk,
    input wire rst_n,
    input wire [PIXEL_WIDTH-1:0] pixel_in,
    input wire in_valid,
    input wire [15:0] in_x,
    input wire [15:0] in_y,
    input wire [15:0] roi_x0,
    input wire [15:0] roi_y0,
    input wire [15:0] roi_w,
    input wire [15:0] roi_h,
    output reg [PIXEL_WIDTH-1:0] pixel_out,
    output reg out_valid,
    output reg out_frame_start,
    output reg out_frame_end,
    output reg [15:0] out_x,
    output reg [15:0] out_y
);
wire inside = (in_x >= roi_x0) && (in_x < roi_x0 + roi_w) &&
              (in_y >= roi_y0) && (in_y < roi_y0 + roi_h);
wire first_pix = (in_x == roi_x0) && (in_y == roi_y0);
wire last_pix = (in_x == roi_x0 + roi_w - 1) && (in_y == roi_y0 + roi_h - 1);
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        pixel_out <= 0; out_valid <= 0; out_frame_start <= 0; out_frame_end <= 0; out_x <= 0; out_y <= 0;
    end else begin
        out_valid <= in_valid && inside;
        out_frame_start <= in_valid && inside && first_pix;
        out_frame_end <= in_valid && inside && last_pix;
        pixel_out <= pixel_in;
        out_x <= in_x - roi_x0;
        out_y <= in_y - roi_y0;
    end
end
endmodule
