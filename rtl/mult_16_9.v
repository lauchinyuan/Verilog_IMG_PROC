`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Author: lauchinyuan
// Email: lauchinyuan@yeah.net
// Create Date: 2023/07/24 11:09:26
// Module Name: mult_16_9
// Description: 16位乘9位无符号乘法器,非流水线
//////////////////////////////////////////////////////////////////////////////////
module mult_16_9(
        input [15:0]    a_16b   ,
        input [8:0]     b_9b    ,
        
        output [24:0]   c
    );
    
    wire [24:0] PP[8:0];
    
    assign PP[0] = b_9b[0]?{9'b0,a_16b}:25'b0;
    assign PP[1] = b_9b[1]?{8'b0,a_16b,1'b0}:25'b0;
    assign PP[2] = b_9b[2]?{7'b0,a_16b,2'b0}:25'b0;
    assign PP[3] = b_9b[3]?{6'b0,a_16b,3'b0}:25'b0;
    assign PP[4] = b_9b[4]?{5'b0,a_16b,4'b0}:25'b0;
    assign PP[5] = b_9b[5]?{4'b0,a_16b,5'b0}:25'b0;
    assign PP[6] = b_9b[6]?{3'b0,a_16b,6'b0}:25'b0;
    assign PP[7] = b_9b[7]?{2'b0,a_16b,7'b0}:25'b0;
    assign PP[8] = b_9b[8]?{1'b0,a_16b,8'b0}:25'b0;
    
    assign c = PP[0]+PP[1]+PP[2]+PP[3]+PP[4]+PP[5]+PP[6]+PP[7]+PP[8];
endmodule
