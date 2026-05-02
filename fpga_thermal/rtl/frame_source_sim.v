// -----------------------------------------------------------------------------
// Module: frame_source_sim
// Function: simulation-only raw frame source reading one 16-bit hex word per line.
// Timing: one pixel per clk when enable is high; inserts FRAME_GAP after a frame.
// -----------------------------------------------------------------------------
`timescale 1ns/1ps
module frame_source_sim #(
    parameter FRAME_WIDTH = 256,
    parameter FRAME_HEIGHT = 192,
    parameter MEM_FILE = "test_frame.mem",
    parameter FRAME_GAP = 16
) (
    input wire clk,
    input wire rst_n,
    input wire enable,
    output reg [15:0] pixel_data,
    output reg pixel_valid,
    output reg frame_start,
    output reg frame_end,
    output reg [15:0] x,
    output reg [15:0] y
);
localparam TOTAL_PIXELS = FRAME_WIDTH * FRAME_HEIGHT;
reg [15:0] mem [0:TOTAL_PIXELS-1];
integer idx;
integer gap_cnt;
reg in_gap;
initial begin
    for (idx = 0; idx < TOTAL_PIXELS; idx = idx + 1) mem[idx] = 0;
    $readmemh(MEM_FILE, mem);
end
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        pixel_data <= 0; pixel_valid <= 0; frame_start <= 0; frame_end <= 0;
        x <= 0; y <= 0; idx <= 0; gap_cnt <= 0; in_gap <= 0;
    end else begin
        pixel_valid <= 0; frame_start <= 0; frame_end <= 0;
        if (enable) begin
            if (in_gap) begin
                if (gap_cnt == FRAME_GAP - 1) begin gap_cnt <= 0; in_gap <= 0; end
                else gap_cnt <= gap_cnt + 1;
            end else begin
                pixel_data <= mem[idx];
                pixel_valid <= 1'b1;
                frame_start <= (idx == 0);
                frame_end <= (idx == TOTAL_PIXELS - 1);
                x <= idx % FRAME_WIDTH;
                y <= idx / FRAME_WIDTH;
                if (idx == TOTAL_PIXELS - 1) begin idx <= 0; in_gap <= 1'b1; end
                else idx <= idx + 1;
            end
        end
    end
end
endmodule
