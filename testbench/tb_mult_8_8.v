`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/07/23 10:48:26
// Design Name: 
// Module Name: tb_mult_8_8
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
//////////////////////////////////////////////////////////////////////////////////


module tb_mult_8_8(

    );
    reg [7:0] a;
    reg [7:0] b;
    
    wire [15:0] c;
    wire [15:0] c_real;
    wire correct;
    
    integer i;
    initial begin
       a <= $random;
       b <= $random;
       for(i=0;i<=100;i=i+1) begin
        #20
            a <= $random;
            b <= $random;
       end
    end
    
    
    assign c_real = a*b;
    
    assign correct = (c_real == c)?1'b1:1'b0;
    
    mult_8_8 mult_8_8_inst(
        .a(a),
        .b(b),

        .c(c)
    );
   
endmodule
