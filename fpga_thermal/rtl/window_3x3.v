// -----------------------------------------------------------------------------
// Module: window_3x3
// Function: builds a complete 3x3 window from raster gray stream.
// Boundary: out_valid only for interior pixels; out_x/out_y are center coords.
// -----------------------------------------------------------------------------
`timescale 1ns/1ps
module window_3x3 #(
    parameter WIDTH = 294,
    parameter PIXEL_WIDTH = 8
) (
    input wire clk,
    input wire rst_n,
    input wire [PIXEL_WIDTH-1:0] pixel_in,
    input wire in_valid,
    input wire [15:0] in_x,
    input wire [15:0] in_y,
    output reg [PIXEL_WIDTH-1:0] p00, p01, p02,
    output reg [PIXEL_WIDTH-1:0] p10, p11, p12,
    output reg [PIXEL_WIDTH-1:0] p20, p21, p22,
    output reg out_valid,
    output reg [15:0] out_x,
    output reg [15:0] out_y
);
wire [PIXEL_WIDTH-1:0] lb0, lb1, lb2;
wire lb_valid;
wire [15:0] lb_x, lb_y;
line_buffer_3row #(.WIDTH(WIDTH), .PIXEL_WIDTH(PIXEL_WIDTH)) u_lb (
    .clk(clk), .rst_n(rst_n), .pixel_in(pixel_in), .in_valid(in_valid),
    .in_x(in_x), .in_y(in_y), .row0_pixel(lb0), .row1_pixel(lb1), .row2_pixel(lb2),
    .out_valid(lb_valid), .out_x(lb_x), .out_y(lb_y)
);
reg [PIXEL_WIDTH-1:0] r0_c0, r0_c1, r1_c0, r1_c1, r2_c0, r2_c1;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        p00 <= 0; p01 <= 0; p02 <= 0; p10 <= 0; p11 <= 0; p12 <= 0; p20 <= 0; p21 <= 0; p22 <= 0;
        r0_c0 <= 0; r0_c1 <= 0; r1_c0 <= 0; r1_c1 <= 0; r2_c0 <= 0; r2_c1 <= 0;
        out_valid <= 0; out_x <= 0; out_y <= 0;
    end else begin
        out_valid <= 0;
        if (lb_valid) begin
            p00 <= r0_c1; p01 <= r0_c0; p02 <= lb0;
            p10 <= r1_c1; p11 <= r1_c0; p12 <= lb1;
            p20 <= r2_c1; p21 <= r2_c0; p22 <= lb2;
            r0_c1 <= r0_c0; r0_c0 <= lb0;
            r1_c1 <= r1_c0; r1_c0 <= lb1;
            r2_c1 <= r2_c0; r2_c0 <= lb2;
            out_valid <= (lb_x >= 2) && (lb_y >= 2);
            out_x <= lb_x - 1'b1; out_y <= lb_y - 1'b1;
        end
    end
end
endmodule
