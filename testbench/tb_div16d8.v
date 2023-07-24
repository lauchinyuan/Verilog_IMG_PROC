`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/07/21 16:46:05
// Design Name: 
// Module Name: tb_div16d8
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


module tb_div16d8(

    );
    reg        clk_sys   ;
    reg        reset_sys ;
    reg        reset_sync;
    reg [15:0] divident  ;
    reg [7:0]  divisor   ;
    reg [15:0] q_sample  ;
    reg [7:0]  remain_sample;
    
    reg [15:0] divident_d1;
    reg [7:0]  divisor_d1;
    reg [15:0] divident_d2;
    reg [7:0]  divisor_d2;   
    
    
    wire [15:0] q           ;
    wire [7:0]  remain      ;
    wire        in_valid    ;
    wire        out_valid   ;
    
    reg         correct     ;

    //寄存输入除法器的除数和被除数
    always@(posedge clk_sys or negedge reset_sys) begin
        if(!reset_sys) begin
            divident_d1 <= 16'b0;
            divident_d2 <= 16'b0;
            divisor_d1 <= 16'b0;
            divisor_d2 <= 16'b0;
        end else if(in_valid) begin  //in_valid为高时
        //正好下一次除法运算的数据已经准备好进行采集,并多打15拍保持(每个in_valid间隔15拍)
            divident_d1 <= divident;
            divident_d2 <= divident_d1;
            divisor_d1 <= divisor;
            divisor_d2 <= divisor_d1;
        end
    end
    
    //获取除法计算的余数和商
    //q_sample
    always@(posedge clk_sys or reset_sys) begin
        if(!reset_sys) begin
            q_sample <= 16'b0;
            remain_sample <= 8'b0;
        end else if(out_valid) begin
            q_sample <= q;
            remain_sample <= remain;
        end else begin
            q_sample <= q_sample;
            remain_sample <= remain_sample;
        end
    end
    

    integer i;
    initial begin
        clk_sys = 1'b1;
        reset_sys <= 1'b0;
        reset_sync <= 1'b0;
        divident <= 16'd80;
        divisor <= 8'd5;
    #30
        reset_sys <= 1'b1;  //正常计算
    
    
    #320
        divisor <= 8'd4;  //正常计算
    #320
        divisor <= 8'd10;  //正常计算
    #320
        divident <= 8'd123;  //正常计算
    #320
        divident <= 8'd111;  
    #320
        divident <= 8'd112;
    #20
        reset_sync <= 1'b1;  
    #20
        reset_sync <= 1'b0;
        divident <= 16'b10101010;
        divisor <= 8'b0001;
    for(i=0;i<=65535;i=i+1) begin
       #320
       divisor <= $random;
       divident <= $random;
    end
    
    end
    
    
    //判断是否计算正确标志
    always@(*) begin
        if(!reset_sys) begin
            correct = 1'b0;
        //当out_valid高电平时,商和余数样本还没有更新,此时判断结果correct低电平
        //为了方便观察correct信号是否连贯为1,将out_valid为1也当作计算结果正确(correct = 1)
        end else if(out_valid) begin
            correct = 1'b1;
        end else if((divisor_d2 == 8'b0) && (q_sample == 16'hffff)) begin
            correct = 1'b1; //当除数为0时,只要商为16'hffff则认为是对的,实际上是无效的除法运算
        end else if((q_sample*divisor_d2+remain_sample) == divident_d2) begin
            correct = 1'b1;
        end else begin
            correct = 1'b0;
        end
    end

    always #10 clk_sys = ~clk_sys;
    
    div_16d8 div_16d8_inst(
        .clk_sys          (clk_sys     ),
        .reset_sys        (reset_sys   ),
        .reset_sync       (reset_sync  ), //同步高电平复位端口
        .divident         (divident    ),
        .divisor          (divisor     ),

        .q                (q           ),
        .remain           (remain      ), //余数,位宽为16+(8-1)=23位
        .out_valid        (out_valid   ),
        .in_valid         (in_valid    )
    );
endmodule
