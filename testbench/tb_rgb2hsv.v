`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Author: lauchinyuan
// Emain: lauchinyuan@yeah.net
// Create Date: 2023/07/24 14:09:20
// Description: testbench for rgb2hsv
//////////////////////////////////////////////////////////////////////////////////


module tb_rgb2hsv(

    );
    reg       clk_sys   ;
    reg       reset_sys ;
    reg       InVSYNC   ;
    reg       InHSYNC   ;
    reg       InEN      ;
    reg [7:0] InData    ;
    
    wire      OutVSYNC  ;
    wire      OutHSYNC  ;
    wire      OutEN     ;
    wire[7:0] Outdata   ;
    
    
    reg [7:0] mem[0:79199];
    reg [7:0] hsv[0:79199];  //hsv结果
    
    //样本计数器
    reg [16:0] sample_cnt;   

    
    
    //读取原始数据
    initial begin
        $readmemh("C:/Users/Lau Chinyuan/Desktop/mem/rgb_large.mem",mem);
    end
    
    
    integer i,j,k;
    
    
    initial begin
        clk_sys = 1'b1;
        reset_sys <= 1'b0;
        InData <= 8'd0;
        InEN <= 1'b0;
        InVSYNC <= 1'b0;
        InHSYNC <= 1'b0;
    #20
        reset_sys <= 1'b1;  
    #60  
    for (k=0;k<=0;k=k+1) begin  //一共只有1帧图像
        #60
           for(j=0;j<=131;j=j+1) begin //一共132行数据
             #60
             InHSYNC <= 1'b1;
             if(j==0) begin //第一行时,帧同步信号也要同时有效
                 InVSYNC <= 1'b1;
             end
             #20
             InHSYNC <= 1'b0;
             if(j==0) begin //第一行时,帧同步信号也要同时有效
                 InVSYNC <= 1'b0;
             end
             for(i=0;i<=599;i=i+1) begin  //一行数据200个像素点,共600个rgb值
                 #20
                 InEN <= 1'b1;
                 InData <= mem[k*132*600+j*600+i];
             end
             #20
             InEN <= 1'b0; 
             if(j==131&&k==0) begin  //最后一帧的最后一行需要额外补充一个行同步信号以及帧同步信号
                #60
                InHSYNC <= 1'b1;
                InVSYNC <= 1'b1;
                #20
                InHSYNC <= 1'b0;
                InVSYNC <= 1'b0;
             end
           end
    
    end
     wait(sample_cnt >= 17'd79200)
        $writememh("C:/Users/Lau Chinyuan/Desktop/mem/hsv_result_large.mem",hsv); 
    end
    
   //时钟信号
    always #10 clk_sys = ~clk_sys;
    
    
    //采样过程
    //sample_cnt
    always@(posedge clk_sys or negedge reset_sys) begin
        if(!reset_sys) begin
            sample_cnt <= 17'd0;
        end else if(OutEN) begin
            sample_cnt <= sample_cnt + 17'd1;
        end else begin
            sample_cnt <= sample_cnt;
        end
    end
    
    //采集输出存储到mem中
    always@(posedge clk_sys or reset_sys) begin
        if(OutEN) begin
            hsv[sample_cnt] <= Outdata;
        end
    end
    
    rgb2hsv rgb2hsv_inst(
        .clk_sys    (clk_sys   ),
        .reset_sys  (reset_sys ),
        .InVSYNC    (InVSYNC   ),
        .InHSYNC    (InHSYNC   ),
        .InEN       (InEN      ),
        .InData     (InData    ),

        .OutVSYNC   (OutVSYNC  ),
        .OutHSYNC   (OutHSYNC  ),
        .OutEN      (OutEN     ),
        .Outdata    (Outdata   )
    );
endmodule
