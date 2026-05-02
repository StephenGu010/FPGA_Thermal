// -----------------------------------------------------------------------------
// Module: candidate_mask_gen
// Function: threshold raw pixels, emit downsampled 1-bit mask and full-res count.
// Timing: mask_valid aligns with selected source pixel; count_valid at frame end.
// -----------------------------------------------------------------------------
`timescale 1ns/1ps
module candidate_mask_gen #(
    parameter IN_WIDTH = 256,
    parameter IN_HEIGHT = 192,
    parameter MASK_WIDTH = 64,
    parameter MASK_HEIGHT = 48
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
    output reg candidate_mask,
    output reg mask_valid,
    output reg mask_frame_start,
    output reg mask_frame_end,
    output reg [15:0] mask_x,
    output reg [15:0] mask_y,
    output reg [31:0] candidate_count,
    output reg [31:0] candidate_sum_x,
    output reg [31:0] candidate_sum_y,
    output reg candidate_count_valid
);
localparam STEP_X = IN_WIDTH / MASK_WIDTH;
localparam STEP_Y = IN_HEIGHT / MASK_HEIGHT;
localparam STEP_X_SHIFT = 2;
localparam STEP_Y_SHIFT = 2;
wire in_range = (raw_in >= raw_low_threshold) && (raw_in <= raw_high_threshold);
wire select_pixel = ((in_x & (STEP_X - 1)) == 0) && ((in_y & (STEP_Y - 1)) == 0) &&
                    ((in_x >> STEP_X_SHIFT) < MASK_WIDTH) && ((in_y >> STEP_Y_SHIFT) < MASK_HEIGHT);
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        candidate_mask <= 0; mask_valid <= 0; mask_frame_start <= 0; mask_frame_end <= 0; mask_x <= 0; mask_y <= 0;
        candidate_count <= 0; candidate_sum_x <= 0; candidate_sum_y <= 0; candidate_count_valid <= 0;
    end else begin
        mask_valid <= 0; mask_frame_start <= 0; mask_frame_end <= 0; candidate_count_valid <= 0;
        if (in_valid) begin
            if (in_frame_start) begin candidate_count <= 0; candidate_sum_x <= 0; candidate_sum_y <= 0; end
            if (in_range) begin candidate_count <= candidate_count + 1'b1; candidate_sum_x <= candidate_sum_x + in_x; candidate_sum_y <= candidate_sum_y + in_y; end
            if (select_pixel) begin
                candidate_mask <= in_range; mask_valid <= 1'b1;
                mask_frame_start <= (in_x == 0) && (in_y == 0);
                mask_frame_end <= ((in_x >> STEP_X_SHIFT) == MASK_WIDTH - 1) && ((in_y >> STEP_Y_SHIFT) == MASK_HEIGHT - 1);
                mask_x <= in_x >> STEP_X_SHIFT; mask_y <= in_y >> STEP_Y_SHIFT;
            end
            if (in_frame_end) candidate_count_valid <= 1'b1;
        end
    end
end
endmodule
