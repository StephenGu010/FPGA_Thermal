// -----------------------------------------------------------------------------
// Module: thumb_gen
// Function: P0 thumbnail generator using pixel skipping.
// Timing: thumb_valid aligns with selected source pixel.
// -----------------------------------------------------------------------------
`timescale 1ns/1ps
module thumb_gen #(
    parameter IN_WIDTH = 256,
    parameter IN_HEIGHT = 192,
    parameter THUMB_WIDTH = 64,
    parameter THUMB_HEIGHT = 48
) (
    input wire clk,
    input wire rst_n,
    input wire [7:0] gray_in,
    input wire in_valid,
    input wire [15:0] in_x,
    input wire [15:0] in_y,
    output reg [7:0] thumb_gray,
    output reg thumb_valid,
    output reg thumb_frame_start,
    output reg thumb_frame_end,
    output reg [15:0] thumb_x,
    output reg [15:0] thumb_y
);
localparam STEP_X = IN_WIDTH / THUMB_WIDTH;
localparam STEP_Y = IN_HEIGHT / THUMB_HEIGHT;
localparam STEP_X_SHIFT = 2;
localparam STEP_Y_SHIFT = 2;
wire select_pixel = ((in_x & (STEP_X - 1)) == 0) && ((in_y & (STEP_Y - 1)) == 0) &&
                    ((in_x >> STEP_X_SHIFT) < THUMB_WIDTH) && ((in_y >> STEP_Y_SHIFT) < THUMB_HEIGHT);
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        thumb_gray <= 0; thumb_valid <= 0; thumb_frame_start <= 0; thumb_frame_end <= 0; thumb_x <= 0; thumb_y <= 0;
    end else begin
        thumb_valid <= in_valid && select_pixel;
        thumb_frame_start <= in_valid && select_pixel && (in_x == 0) && (in_y == 0);
        thumb_frame_end <= in_valid && select_pixel && ((in_x >> STEP_X_SHIFT) == THUMB_WIDTH - 1) && ((in_y >> STEP_Y_SHIFT) == THUMB_HEIGHT - 1);
        thumb_gray <= gray_in; thumb_x <= in_x >> STEP_X_SHIFT; thumb_y <= in_y >> STEP_Y_SHIFT;
    end
end
endmodule
