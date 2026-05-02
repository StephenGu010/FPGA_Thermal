// -----------------------------------------------------------------------------
// Module: meta_extract
// Function: raw_min/max/center/hotspot and threshold candidate centroid.
// Timing: meta_valid pulses with the final input pixel of each frame.
// -----------------------------------------------------------------------------
`timescale 1ns/1ps
module meta_extract #(
    parameter FRAME_WIDTH = 256,
    parameter FRAME_HEIGHT = 192
) (
    input wire clk,
    input wire rst_n,
    input wire [15:0] raw_in,
    input wire in_valid,
    input wire in_frame_start,
    input wire in_frame_end,
    input wire [15:0] in_x,
    input wire [15:0] in_y,
    input wire [15:0] raw_low_threshold,
    input wire [15:0] raw_high_threshold,
    output reg [15:0] raw_min,
    output reg [15:0] raw_max,
    output reg [15:0] raw_center,
    output reg [15:0] raw_hotspot,
    output reg [15:0] hotspot_x,
    output reg [15:0] hotspot_y,
    output reg [31:0] candidate_count,
    output reg [15:0] candidate_cx,
    output reg [15:0] candidate_cy,
    output reg meta_valid
);
reg [31:0] sum_x, sum_y;
wire is_center = (in_x == FRAME_WIDTH / 2) && (in_y == FRAME_HEIGHT / 2);
wire in_range = (raw_in >= raw_low_threshold) && (raw_in <= raw_high_threshold);
function [15:0] u32_to_u16;
    input [31:0] value;
begin
    u32_to_u16 = (value > 32'h0000FFFF) ? 16'hFFFF : value[15:0];
end
endfunction
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        raw_min <= 16'hFFFF; raw_max <= 0; raw_center <= 0; raw_hotspot <= 0; hotspot_x <= 0; hotspot_y <= 0;
        candidate_count <= 0; candidate_cx <= 0; candidate_cy <= 0; sum_x <= 0; sum_y <= 0; meta_valid <= 0;
    end else begin
        meta_valid <= 0;
        if (in_valid) begin
            if (in_frame_start) begin
                raw_min <= raw_in; raw_max <= raw_in; raw_hotspot <= raw_in; hotspot_x <= in_x; hotspot_y <= in_y;
                candidate_count <= 0; sum_x <= 0; sum_y <= 0;
            end else begin
                if (raw_in < raw_min) raw_min <= raw_in;
                if (raw_in > raw_max) begin raw_max <= raw_in; raw_hotspot <= raw_in; hotspot_x <= in_x; hotspot_y <= in_y; end
            end
            if (is_center) raw_center <= raw_in;
            if (in_range) begin candidate_count <= candidate_count + 1'b1; sum_x <= sum_x + in_x; sum_y <= sum_y + in_y; end
            if (in_frame_end) begin
                if (candidate_count != 0) begin candidate_cx <= u32_to_u16(sum_x / candidate_count); candidate_cy <= u32_to_u16(sum_y / candidate_count); end
                else begin candidate_cx <= 0; candidate_cy <= 0; end
                meta_valid <= 1'b1;
            end
        end
    end
end
endmodule
