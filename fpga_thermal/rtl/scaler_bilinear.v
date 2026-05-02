// -----------------------------------------------------------------------------
// Module: scaler_bilinear
// Function: P1 frame-buffered Q8.8 fixed-point bilinear scaler, no floating point.
// Timing: captures one ROI frame, then emits one scaled pixel per clk.
// -----------------------------------------------------------------------------
`timescale 1ns/1ps
module scaler_bilinear #(
    parameter MAX_IN_WIDTH = 256,
    parameter MAX_IN_HEIGHT = 192,
    parameter PIXEL_WIDTH = 8
) (
    input wire clk,
    input wire rst_n,
    input wire [PIXEL_WIDTH-1:0] pixel_in,
    input wire in_valid,
    input wire in_frame_start,
    input wire in_frame_end,
    input wire [15:0] in_x,
    input wire [15:0] in_y,
    input wire [15:0] in_width,
    input wire [15:0] in_height,
    input wire [15:0] out_width_cfg,
    input wire [15:0] out_height_cfg,
    output reg [PIXEL_WIDTH-1:0] pixel_out,
    output reg out_valid,
    output reg out_frame_start,
    output reg out_frame_end,
    output reg [15:0] out_x,
    output reg [15:0] out_y,
    output reg busy
);
localparam MEM_PIXELS = MAX_IN_WIDTH * MAX_IN_HEIGHT;
reg [PIXEL_WIDTH-1:0] frame_mem [0:MEM_PIXELS-1];
reg [15:0] src_w, src_h, dst_w, dst_h, ox, oy;
reg [31:0] scale_x_q8, scale_y_q8, src_x_q8, src_y_q8;
reg [15:0] x0, y0, x1, y1;
reg [7:0] fx, fy, p00, p01, p10, p11;
reg [8:0] fx_w, fy_w, ifx, ify;
reg [31:0] top_mix, bot_mix, value_mix;
reg output_active;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        pixel_out <= 0; out_valid <= 0; out_frame_start <= 0; out_frame_end <= 0; out_x <= 0; out_y <= 0;
        busy <= 0; src_w <= 1; src_h <= 1; dst_w <= 1; dst_h <= 1; scale_x_q8 <= 0; scale_y_q8 <= 0;
        ox <= 0; oy <= 0; output_active <= 0;
    end else begin
        out_valid <= 0; out_frame_start <= 0; out_frame_end <= 0;
        if (in_valid) begin
            frame_mem[in_y * MAX_IN_WIDTH + in_x] <= pixel_in;
            if (in_frame_start) begin
                src_w <= in_width; src_h <= in_height; dst_w <= out_width_cfg; dst_h <= out_height_cfg;
                scale_x_q8 <= (out_width_cfg > 1) ? (((in_width - 1) << 8) / (out_width_cfg - 1)) : 0;
                scale_y_q8 <= (out_height_cfg > 1) ? (((in_height - 1) << 8) / (out_height_cfg - 1)) : 0;
            end
            if (in_frame_end) begin ox <= 0; oy <= 0; output_active <= 1'b1; busy <= 1'b1; end
        end
        if (output_active) begin
            src_x_q8 = ox * scale_x_q8; src_y_q8 = oy * scale_y_q8;
            x0 = src_x_q8[23:8]; y0 = src_y_q8[23:8]; fx = src_x_q8[7:0]; fy = src_y_q8[7:0];
            if (x0 >= src_w - 1) begin x0 = src_w - 1; x1 = x0; fx = 0; end else x1 = x0 + 1'b1;
            if (y0 >= src_h - 1) begin y0 = src_h - 1; y1 = y0; fy = 0; end else y1 = y0 + 1'b1;
            fx_w = {1'b0, fx}; fy_w = {1'b0, fy};
            ifx = 9'd256 - fx_w; ify = 9'd256 - fy_w;
            p00 = frame_mem[y0 * MAX_IN_WIDTH + x0]; p01 = frame_mem[y0 * MAX_IN_WIDTH + x1];
            p10 = frame_mem[y1 * MAX_IN_WIDTH + x0]; p11 = frame_mem[y1 * MAX_IN_WIDTH + x1];
            top_mix = p00 * ifx + p01 * fx;
            bot_mix = p10 * ifx + p11 * fx;
            value_mix = top_mix * ify + bot_mix * fy;
            pixel_out <= value_mix[23:16];
            out_valid <= 1'b1;
            out_frame_start <= (ox == 0) && (oy == 0);
            out_frame_end <= (ox == dst_w - 1) && (oy == dst_h - 1);
            out_x <= ox; out_y <= oy;
            if ((ox == dst_w - 1) && (oy == dst_h - 1)) begin output_active <= 0; busy <= 0; end
            else if (ox == dst_w - 1) begin ox <= 0; oy <= oy + 1'b1; end
            else ox <= ox + 1'b1;
        end
    end
end
endmodule
