`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Author: lauchinyuan
// Email: lauchinyuan@yeah.net
// Create Date: 2023/07/25 02:29:36
// Module Name: mult_16_8
// Description: 16bit*8bit无符号乘法器,非流水
//////////////////////////////////////////////////////////////////////////////////
module mult_16_8(
        input wire [15:0]   a_16b ,
        input wire [7:0]    b_8b  ,
        
        output wire [23:0]  c   
    );
    
    wire [23:0] PP[7:0];
    //部分积
    assign PP[0] = b_8b[0]?{8'b0,a_16b}:24'b0;
    assign PP[1] = b_8b[1]?{7'b0,a_16b,1'b0}:24'b0;
    assign PP[2] = b_8b[2]?{6'b0,a_16b,2'b0}:24'b0;
    assign PP[3] = b_8b[3]?{5'b0,a_16b,3'b0}:24'b0;
    assign PP[4] = b_8b[4]?{4'b0,a_16b,4'b0}:24'b0;
    assign PP[5] = b_8b[5]?{3'b0,a_16b,5'b0}:24'b0;
    assign PP[6] = b_8b[6]?{2'b0,a_16b,6'b0}:24'b0;
    assign PP[7] = b_8b[7]?{1'b0,a_16b,7'b0}:24'b0;    
    
    assign c = PP[0] + PP[1] + PP[2] + PP[3] + PP[4] + PP[5] + PP[6] + PP[7];
    
endmodule
