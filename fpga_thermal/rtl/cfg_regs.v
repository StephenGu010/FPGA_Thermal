// -----------------------------------------------------------------------------
// Module: cfg_regs
// Function: simple clk-domain configuration bank.
// Map: 0x00 mode, 0x04 edge_en, 0x08 edge_gain, 0x0C edge_threshold,
//      0x10 raw_low, 0x14 raw_high, 0x18 roi_x0, 0x1C roi_y0, 0x20 roi_w, 0x24 roi_h.
// -----------------------------------------------------------------------------
`timescale 1ns/1ps
module cfg_regs #(
    parameter RAW_WIDTH = 256,
    parameter RAW_HEIGHT = 192
) (
    input wire clk,
    input wire rst_n,
    input wire cfg_we,
    input wire [7:0] cfg_addr,
    input wire [31:0] cfg_wdata,
    output reg [31:0] cfg_rdata,
    output reg display_mode,
    output reg edge_enable,
    output reg [7:0] edge_gain,
    output reg [7:0] edge_threshold,
    output reg [15:0] raw_low_threshold,
    output reg [15:0] raw_high_threshold,
    output reg [15:0] roi_x0,
    output reg [15:0] roi_y0,
    output reg [15:0] roi_w,
    output reg [15:0] roi_h
);
localparam [15:0] RAW_WIDTH_U16 = RAW_WIDTH;
localparam [15:0] RAW_HEIGHT_U16 = RAW_HEIGHT;
localparam [15:0] DEFAULT_ROI_Y = (RAW_HEIGHT > 112) ? ((RAW_HEIGHT - 112) / 2) : 16'd0;
localparam [15:0] DEFAULT_ROI_H = (RAW_HEIGHT > 112) ? 16'd112 : RAW_HEIGHT_U16;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        display_mode <= 0; edge_enable <= 1; edge_gain <= 8'd4; edge_threshold <= 8'd32;
        raw_low_threshold <= 16'h3000; raw_high_threshold <= 16'hFFFF;
        roi_x0 <= 0; roi_y0 <= DEFAULT_ROI_Y;
        roi_w <= RAW_WIDTH_U16; roi_h <= DEFAULT_ROI_H;
    end else if (cfg_we) begin
        case (cfg_addr)
            8'h00: display_mode <= cfg_wdata[0];
            8'h04: edge_enable <= cfg_wdata[0];
            8'h08: edge_gain <= cfg_wdata[7:0];
            8'h0C: edge_threshold <= cfg_wdata[7:0];
            8'h10: raw_low_threshold <= cfg_wdata[15:0];
            8'h14: raw_high_threshold <= cfg_wdata[15:0];
            8'h18: roi_x0 <= cfg_wdata[15:0];
            8'h1C: roi_y0 <= cfg_wdata[15:0];
            8'h20: roi_w <= cfg_wdata[15:0];
            8'h24: roi_h <= cfg_wdata[15:0];
            default: ;
        endcase
    end
end
always @(*) begin
    case (cfg_addr)
        8'h00: cfg_rdata = {31'd0, display_mode};
        8'h04: cfg_rdata = {31'd0, edge_enable};
        8'h08: cfg_rdata = {24'd0, edge_gain};
        8'h0C: cfg_rdata = {24'd0, edge_threshold};
        8'h10: cfg_rdata = {16'd0, raw_low_threshold};
        8'h14: cfg_rdata = {16'd0, raw_high_threshold};
        8'h18: cfg_rdata = {16'd0, roi_x0};
        8'h1C: cfg_rdata = {16'd0, roi_y0};
        8'h20: cfg_rdata = {16'd0, roi_w};
        8'h24: cfg_rdata = {16'd0, roi_h};
        default: cfg_rdata = 0;
    endcase
end
endmodule
