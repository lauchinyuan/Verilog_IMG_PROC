`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/07/24 12:41:42
// Design Name: 
// Module Name: tb_mult_16_9
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module tb_mult_16_9(

    );
    reg [15:0]  a_16b   ;
    reg [8:0]   b_9b    ;
    
    wire [24:0] c       ;
    wire [24:0] c_real  ;
    
    integer i;
    initial begin
       a_16b <= $random;
       b_9b <= $random;
       for(i=0;i<=65535;i=i+1) begin
        #20
            a_16b <= $random;
            b_9b <= $random;
       end
    end   
    
    
    assign c_real = a_16b*b_9b;
    
    assign correct = (c_real == c)?1'b1:1'b0;   
    
    
    
    
    mult_16_9 mult_16_9_inst(
        .a_16b   (a_16b),
        .b_9b    (b_9b ),
                  
        .c       (c    )
    );
endmodule
