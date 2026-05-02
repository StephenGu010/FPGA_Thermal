`timescale 1ns/1ps
module tb_packet_tx;
reg clk=0,rst_n=0,start=0; reg [7:0] payload_data=8'hA0; reg payload_valid=0,payload_last=0;
wire payload_ready,cs_n,sclk,mosi,done; integer rx_bits,rx_bytes; reg [7:0] shift; reg [7:0] bytes[0:63];
always #5 clk=~clk;
packet_tx_spi #(.CLK_DIV(1)) dut(.clk(clk),.rst_n(rst_n),.start(start),.frame_id(16'd1),.display_width(16'd2),.display_height(16'd1),.thumb_width(16'd1),.thumb_height(16'd1),.flags(16'd0),.raw_min(16'd1),.raw_max(16'd2),.raw_center(16'd3),.raw_hotspot(16'd4),.hotspot_x(16'd5),.hotspot_y(16'd6),.candidate_count(32'd7),.candidate_cx(16'd8),.candidate_cy(16'd9),.payload_len(32'd3),.header_checksum(16'd0),.payload_data(payload_data),.payload_valid(payload_valid),.payload_last(payload_last),.payload_ready(payload_ready),.spi_cs_n(cs_n),.spi_sclk(sclk),.spi_mosi(mosi),.busy(),.done(done),.crc_out());
always @(posedge sclk) if(!cs_n) begin shift={shift[6:0],mosi}; rx_bits=rx_bits+1; if(rx_bits==8) begin bytes[rx_bytes]={shift[6:0],mosi}; rx_bytes=rx_bytes+1; rx_bits=0; end end
always @(posedge clk) begin payload_valid<=0; payload_last<=0; if(payload_ready) begin payload_valid<=1; if(payload_data==8'hA0) payload_data<=8'hB1; else if(payload_data==8'hB1) begin payload_data<=8'hC2; payload_last<=1; end end end
initial begin rx_bits=0; rx_bytes=0; shift=0; #20 rst_n=1; @(posedge clk); start=1; @(posedge clk); start=0; wait(done); repeat(4) @(posedge clk); if(bytes[0]!==8'h55 || bytes[1]!==8'hAA) begin $display("FAIL magic"); $finish; end if(rx_bytes<45) begin $display("FAIL short %0d",rx_bytes); $finish; end $display("PASS tb_packet_tx bytes=%0d",rx_bytes); $finish; end
endmodule
