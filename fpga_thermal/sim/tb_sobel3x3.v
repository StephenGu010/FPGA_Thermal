`timescale 1ns/1ps
module tb_sobel3x3;
reg clk=0,rst_n=0,in_valid=0; reg [7:0] gray_in=0; reg [15:0] in_x=0,in_y=0;
wire [7:0] edge_strength; wire edge_mask,out_valid;
integer x,y,edge_hits;
always #5 clk=~clk;
sobel3x3 #(.WIDTH(5)) dut(.clk(clk),.rst_n(rst_n),.gray_in(gray_in),.in_valid(in_valid),.in_x(in_x),.in_y(in_y),.edge_threshold(8'd20),.center_gray(),.edge_strength(edge_strength),.edge_mask(edge_mask),.out_valid(out_valid),.out_x(),.out_y());
always @(posedge clk) if (out_valid && edge_mask) edge_hits<=edge_hits+1;
initial begin
 edge_hits=0; #20 rst_n=1;
 for(y=0;y<5;y=y+1) for(x=0;x<5;x=x+1) begin @(posedge clk); in_valid=1; in_x=x; in_y=y; gray_in=(x<2)?8'd0:8'd255; end
 @(posedge clk); in_valid=0; repeat(8) @(posedge clk);
 if(edge_hits==0) begin $display("FAIL no edges"); $finish; end
 $display("PASS tb_sobel3x3 edge_hits=%0d",edge_hits); $finish;
end
endmodule
