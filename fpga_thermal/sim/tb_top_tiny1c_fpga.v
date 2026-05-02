`timescale 1ns/1ps
module tb_top_tiny1c_fpga;
reg clk=0,rst_n=0; reg [15:0] direct_pixel=0,direct_x=0,direct_y=0; reg direct_valid=0,direct_frame_start=0,direct_frame_end=0;
wire packet_done,packet_busy; integer x,y;
always #5 clk=~clk;
top_tiny1c_fpga #(.RAW_WIDTH(16),.RAW_HEIGHT(12),.FULL_DISPLAY_WIDTH(8),.FULL_DISPLAY_HEIGHT(6),.OBS_DISPLAY_WIDTH(8),.OBS_DISPLAY_HEIGHT(6),.THUMB_WIDTH(4),.THUMB_HEIGHT(3),.USE_BILINEAR(0),.SPI_CLK_DIV(1)) dut(
 .clk(clk),.rst_n(rst_n),.tiny_spi_sclk(1'b0),.tiny_spi_cs_n(1'b1),.tiny_spi_mosi(1'b0),.tiny_frame_sync(1'b0),
 .direct_in_enable(1'b1),.direct_pixel(direct_pixel),.direct_valid(direct_valid),.direct_frame_start(direct_frame_start),.direct_frame_end(direct_frame_end),.direct_x(direct_x),.direct_y(direct_y),
 .cfg_we(1'b0),.cfg_addr(8'd0),.cfg_wdata(32'd0),.cfg_rdata(),.esp_spi_cs_n(),.esp_spi_sclk(),.esp_spi_mosi(),.packet_busy(packet_busy),.packet_done(packet_done),.frame_error());
initial begin
 #30 rst_n=1;
 for(y=0;y<12;y=y+1) for(x=0;x<16;x=x+1) begin @(posedge clk); direct_valid=1; direct_x=x; direct_y=y; direct_pixel={4'h3,y[5:0],x[5:0]}; direct_frame_start=(x==0&&y==0); direct_frame_end=(x==15&&y==11); end
 @(posedge clk); direct_valid=0; direct_frame_start=0; direct_frame_end=0;
 fork begin wait(packet_done); $display("PASS tb_top_tiny1c_fpga"); $finish; end begin repeat(5000) @(posedge clk); $display("FAIL top timeout busy=%0d",packet_busy); $finish; end join
end
endmodule
