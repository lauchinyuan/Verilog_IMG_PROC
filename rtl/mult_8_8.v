`timescale 1ns / 1ps
////////////////////////////////////////////////////////////////////////////////// 
// Author: lauchinyuan 
// Email: lauchinyuan@yeah.net
// Create Date: 2023/07/23 10:41:27
// Module Name: mult_8_8
// Description: 8位乘8位无符号乘法器,非流水线
//////////////////////////////////////////////////////////////////////////////////


module mult_8_8(
        input wire [7:0] a,
        input wire [7:0] b,
        
        output wire [15:0] c
    );
    
    wire [15:0] PP0;
    wire [15:0] PP1;
    wire [15:0] PP2;
    wire [15:0] PP3;
    wire [15:0] PP4;
    wire [15:0] PP5;
    wire [15:0] PP6;
    wire [15:0] PP7;
    
    assign PP0 = b[0]?{8'b0,a}:16'b0;
    assign PP1 = b[1]?{7'b0,a,1'b0}:16'b0;
    assign PP2 = b[2]?{6'b0,a,2'b0}:16'b0;
    assign PP3 = b[3]?{5'b0,a,3'b0}:16'b0;
    assign PP4 = b[4]?{4'b0,a,4'b0}:16'b0;
    assign PP5 = b[5]?{3'b0,a,5'b0}:16'b0;
    assign PP6 = b[6]?{2'b0,a,6'b0}:16'b0;
    assign PP7 = b[7]?{1'b0,a,7'b0}:16'b0;
    
    assign c = PP0+PP1+PP2+PP3+PP4+PP5+PP6+PP7;
    
endmodule
