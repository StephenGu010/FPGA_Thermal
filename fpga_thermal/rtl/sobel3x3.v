// -----------------------------------------------------------------------------
// Module: sobel3x3
// Function: streaming Sobel detector using shift/add weights.
// Formula: Gx=(p02+2p12+p22)-(p00+2p10+p20), Gy=(p20+2p21+p22)-(p00+2p01+p02).
// Timing: out_valid for interior pixels only; boundaries are handled by caller.
// -----------------------------------------------------------------------------
`timescale 1ns/1ps
module sobel3x3 #(
    parameter WIDTH = 294
) (
    input wire clk,
    input wire rst_n,
    input wire [7:0] gray_in,
    input wire in_valid,
    input wire [15:0] in_x,
    input wire [15:0] in_y,
    input wire [7:0] edge_threshold,
    output reg [7:0] center_gray,
    output reg [7:0] edge_strength,
    output reg edge_mask,
    output reg out_valid,
    output reg [15:0] out_x,
    output reg [15:0] out_y
);
wire [7:0] p00_w,p01_w,p02_w,p10_w,p11_w,p12_w,p20_w,p21_w,p22_w;
wire win_valid; wire [15:0] win_x, win_y;
window_3x3 #(.WIDTH(WIDTH), .PIXEL_WIDTH(8)) u_win (
    .clk(clk), .rst_n(rst_n), .pixel_in(gray_in), .in_valid(in_valid), .in_x(in_x), .in_y(in_y),
    .p00(p00_w), .p01(p01_w), .p02(p02_w), .p10(p10_w), .p11(p11_w), .p12(p12_w),
    .p20(p20_w), .p21(p21_w), .p22(p22_w), .out_valid(win_valid), .out_x(win_x), .out_y(win_y)
);
reg signed [11:0] gx, gy;
reg [11:0] abs_gx, abs_gy;
reg [12:0] edge_sum;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        center_gray <= 0; edge_strength <= 0; edge_mask <= 0; out_valid <= 0; out_x <= 0; out_y <= 0;
    end else begin
        out_valid <= win_valid; out_x <= win_x; out_y <= win_y; center_gray <= p11_w;
        gx = $signed({4'd0,p02_w}) + $signed({3'd0,p12_w,1'b0}) + $signed({4'd0,p22_w})
           - $signed({4'd0,p00_w}) - $signed({3'd0,p10_w,1'b0}) - $signed({4'd0,p20_w});
        gy = $signed({4'd0,p20_w}) + $signed({3'd0,p21_w,1'b0}) + $signed({4'd0,p22_w})
           - $signed({4'd0,p00_w}) - $signed({3'd0,p01_w,1'b0}) - $signed({4'd0,p02_w});
        abs_gx = gx[11] ? (~gx + 1'b1) : gx;
        abs_gy = gy[11] ? (~gy + 1'b1) : gy;
        edge_sum = abs_gx + abs_gy;
        edge_strength <= (edge_sum > 255) ? 8'd255 : edge_sum[7:0];
        edge_mask <= ((edge_sum > 255) ? 8'd255 : edge_sum[7:0]) >= edge_threshold;
    end
end
endmodule
