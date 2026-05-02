// -----------------------------------------------------------------------------
// Module: top_tangnano9k
// Function:
//   Board-level wrapper for Tang Nano 9K synthesis/P&R. It keeps the public IO
//   count small enough for GW1NR-LV9QN88 by tying simulation-only direct stream
//   inputs and the simple cfg bus to defaults.
// Timing:
//   - clk is the Tang Nano 9K 27 MHz clock.
//   - rst_n is active-low reset.
// -----------------------------------------------------------------------------
`timescale 1ns/1ps

module top_tangnano9k (
    input  wire clk,
    input  wire rst_n,
    input  wire tiny_spi_sclk,
    input  wire tiny_spi_cs_n,
    input  wire tiny_spi_mosi,
    input  wire tiny_frame_sync,
    output wire esp_spi_cs_n,
    output wire esp_spi_sclk,
    output wire esp_spi_mosi,
    output wire packet_busy,
    output wire packet_done,
    output wire frame_error
);

top_tiny1c_fpga #(
    .RAW_WIDTH(256),
    .RAW_HEIGHT(192),
    .FULL_DISPLAY_WIDTH(168),
    .FULL_DISPLAY_HEIGHT(126),
    .OBS_DISPLAY_WIDTH(294),
    .OBS_DISPLAY_HEIGHT(126),
    .THUMB_WIDTH(64),
    .THUMB_HEIGHT(48),
    .USE_BILINEAR(0),
    .SPI_CLK_DIV(2),
    .PACKET_BUFFER_DISPLAY(0)
) u_core (
    .clk(clk),
    .rst_n(rst_n),
    .tiny_spi_sclk(tiny_spi_sclk),
    .tiny_spi_cs_n(tiny_spi_cs_n),
    .tiny_spi_mosi(tiny_spi_mosi),
    .tiny_frame_sync(tiny_frame_sync),
    .direct_in_enable(1'b0),
    .direct_pixel(16'd0),
    .direct_valid(1'b0),
    .direct_frame_start(1'b0),
    .direct_frame_end(1'b0),
    .direct_x(16'd0),
    .direct_y(16'd0),
    .cfg_we(1'b0),
    .cfg_addr(8'd0),
    .cfg_wdata(32'd0),
    .cfg_rdata(),
    .esp_spi_cs_n(esp_spi_cs_n),
    .esp_spi_sclk(esp_spi_sclk),
    .esp_spi_mosi(esp_spi_mosi),
    .packet_busy(packet_busy),
    .packet_done(packet_done),
    .frame_error(frame_error)
);

endmodule
