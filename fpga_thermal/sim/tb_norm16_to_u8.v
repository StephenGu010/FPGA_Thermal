`timescale 1ns/1ps
module tb_norm16_to_u8;
reg clk=0,rst_n=0,in_valid=0,in_frame_start=0,in_frame_end=0,minmax_enable=0;
reg [15:0] raw_in=0,in_x=0,in_y=0;
wire [7:0] gray_out; wire out_valid;
always #5 clk=~clk;
norm16_to_u8 dut(.clk(clk),.rst_n(rst_n),.raw_in(raw_in),.in_valid(in_valid),.in_frame_start(in_frame_start),.in_frame_end(in_frame_end),.in_x(in_x),.in_y(in_y),.minmax_enable(minmax_enable),.raw_min(16'h1000),.raw_max(16'h9000),.gray_out(gray_out),.out_valid(out_valid),.out_frame_start(),.out_frame_end(),.out_x(),.out_y());
initial begin
  #20 rst_n=1; @(posedge clk); raw_in=16'h5000; in_valid=1; minmax_enable=1;
  @(posedge clk); in_valid=0; @(posedge clk);
  if (gray_out<120 || gray_out>130) begin $display("FAIL minmax %0d",gray_out); $finish; end
  @(posedge clk); raw_in=16'hABCD; in_valid=1; minmax_enable=0;
  @(posedge clk); in_valid=0; @(posedge clk);
  if (gray_out!==8'hAB) begin $display("FAIL high byte %h",gray_out); $finish; end
  $display("PASS tb_norm16_to_u8"); $finish;
end
endmodule
