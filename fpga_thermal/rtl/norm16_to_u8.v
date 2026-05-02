// -----------------------------------------------------------------------------
// Module: norm16_to_u8
// Function: 16-bit raw container to 8-bit gray. P0 uses raw[15:8].
// Timing: one clock latency; valid/frame flags/x/y align with gray_out.
// -----------------------------------------------------------------------------
`timescale 1ns/1ps
module norm16_to_u8 (
    input wire clk,
    input wire rst_n,
    input wire [15:0] raw_in,
    input wire in_valid,
    input wire in_frame_start,
    input wire in_frame_end,
    input wire [15:0] in_x,
    input wire [15:0] in_y,
    input wire minmax_enable,
    input wire [15:0] raw_min,
    input wire [15:0] raw_max,
    output reg [7:0] gray_out,
    output reg out_valid,
    output reg out_frame_start,
    output reg out_frame_end,
    output reg [15:0] out_x,
    output reg [15:0] out_y
);
function [7:0] normalize_minmax;
    input [15:0] value;
    input [15:0] min_v;
    input [15:0] max_v;
    reg [31:0] scaled;
    reg [15:0] range_v;
begin
    if (max_v <= min_v || value <= min_v) normalize_minmax = 8'd0;
    else if (value >= max_v) normalize_minmax = 8'd255;
    else begin
        range_v = max_v - min_v;
        scaled = (value - min_v) * 32'd255;
        normalize_minmax = scaled / range_v;
    end
end
endfunction
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        gray_out <= 0; out_valid <= 0; out_frame_start <= 0; out_frame_end <= 0; out_x <= 0; out_y <= 0;
    end else begin
        out_valid <= in_valid;
        out_frame_start <= in_valid & in_frame_start;
        out_frame_end <= in_valid & in_frame_end;
        out_x <= in_x; out_y <= in_y;
        gray_out <= minmax_enable ? normalize_minmax(raw_in, raw_min, raw_max) : raw_in[15:8];
    end
end
endmodule
