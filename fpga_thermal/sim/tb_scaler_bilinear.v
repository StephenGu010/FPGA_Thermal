`timescale 1ns/1ps
module tb_scaler_bilinear;
reg clk=0,rst_n=0,in_valid=0,in_frame_start=0,in_frame_end=0; reg [7:0] pixel_in=0; reg [15:0] in_x=0,in_y=0;
wire [7:0] pixel_out; wire out_valid; wire [15:0] out_x,out_y; integer out_count; reg center_seen;
always #5 clk=~clk;
scaler_bilinear #(.MAX_IN_WIDTH(2),.MAX_IN_HEIGHT(2),.PIXEL_WIDTH(8)) dut(.clk(clk),.rst_n(rst_n),.pixel_in(pixel_in),.in_valid(in_valid),.in_frame_start(in_frame_start),.in_frame_end(in_frame_end),.in_x(in_x),.in_y(in_y),.in_width(16'd2),.in_height(16'd2),.out_width_cfg(16'd3),.out_height_cfg(16'd3),.pixel_out(pixel_out),.out_valid(out_valid),.out_frame_start(),.out_frame_end(),.out_x(out_x),.out_y(out_y),.busy());
always @(posedge clk) if(out_valid) begin out_count<=out_count+1; if(out_x==1&&out_y==1) begin center_seen<=1; if(pixel_out<108||pixel_out>116) begin $display("FAIL center %0d",pixel_out); $finish; end end end
initial begin
 out_count=0; center_seen=0; #20 rst_n=1;
 @(posedge clk); in_valid=1; in_x=0; in_y=0; pixel_in=8'd0; in_frame_start=1; in_frame_end=0;
 @(posedge clk); in_x=1; in_y=0; pixel_in=8'd64; in_frame_start=0;
 @(posedge clk); in_x=0; in_y=1; pixel_in=8'd128;
 @(posedge clk); in_x=1; in_y=1; pixel_in=8'd255; in_frame_end=1;
 @(posedge clk); in_valid=0; in_frame_end=0; repeat(30) @(posedge clk);
 if(out_count!=9 || !center_seen) begin $display("FAIL count=%0d center=%0d",out_count,center_seen); $finish; end
 $display("PASS tb_scaler_bilinear"); $finish;
end
endmodule
