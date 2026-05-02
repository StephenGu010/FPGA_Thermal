`timescale 1ns/1ps
module tb_scaler_nearest;
reg clk=0,rst_n=0,in_valid=0,in_frame_start=0,in_frame_end=0; reg [7:0] pixel_in=0; reg [15:0] in_x=0,in_y=0;
wire [7:0] pixel_out; wire out_valid; integer x,y,out_idx; reg [7:0] expv[0:3];
always #5 clk=~clk;
scaler_nearest #(.MAX_IN_WIDTH(4),.MAX_IN_HEIGHT(4),.PIXEL_WIDTH(8)) dut(.clk(clk),.rst_n(rst_n),.pixel_in(pixel_in),.in_valid(in_valid),.in_frame_start(in_frame_start),.in_frame_end(in_frame_end),.in_x(in_x),.in_y(in_y),.in_width(16'd4),.in_height(16'd4),.out_width_cfg(16'd2),.out_height_cfg(16'd2),.pixel_out(pixel_out),.out_valid(out_valid),.out_frame_start(),.out_frame_end(),.out_x(),.out_y(),.busy());
always @(posedge clk) if(out_valid) begin if(pixel_out!==expv[out_idx]) begin $display("FAIL nearest idx=%0d got=%0d exp=%0d",out_idx,pixel_out,expv[out_idx]); $finish; end out_idx<=out_idx+1; end
initial begin
 expv[0]=0; expv[1]=2; expv[2]=8; expv[3]=10; out_idx=0; #20 rst_n=1;
 for(y=0;y<4;y=y+1) for(x=0;x<4;x=x+1) begin @(posedge clk); in_valid=1; in_x=x; in_y=y; pixel_in=y*4+x; in_frame_start=(x==0&&y==0); in_frame_end=(x==3&&y==3); end
 @(posedge clk); in_valid=0; in_frame_start=0; in_frame_end=0; repeat(20) @(posedge clk);
 if(out_idx!=4) begin $display("FAIL count %0d",out_idx); $finish; end
 $display("PASS tb_scaler_nearest"); $finish;
end
endmodule
