// -----------------------------------------------------------------------------
// Module: edge_blend
// Function: I_enh = clip(I_scale + ((edge_strength * edge_gain) >> 4)).
// Timing: one clock latency; output valid/x/y align with gray_out.
// -----------------------------------------------------------------------------
`timescale 1ns/1ps
module edge_blend (
    input wire clk,
    input wire rst_n,
    input wire [7:0] gray_in,
    input wire [7:0] edge_strength,
    input wire edge_enable,
    input wire [7:0] edge_gain,
    input wire in_valid,
    input wire [15:0] in_x,
    input wire [15:0] in_y,
    output reg [7:0] gray_out,
    output reg out_valid,
    output reg [15:0] out_x,
    output reg [15:0] out_y
);
reg [15:0] boost, sum;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin gray_out <= 0; out_valid <= 0; out_x <= 0; out_y <= 0; end
    else begin
        out_valid <= in_valid; out_x <= in_x; out_y <= in_y;
        boost = edge_enable ? ((edge_strength * edge_gain) >> 4) : 0;
        sum = gray_in + boost;
        gray_out <= (sum > 255) ? 8'd255 : sum[7:0];
    end
end
endmodule
