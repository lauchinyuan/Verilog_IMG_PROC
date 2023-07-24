`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Create Date: 2023/07/21 16:22:29
// Design Name: 
// Module Name: div_16d8
// Description: 16位除以8位的无符号除法器,自动锁存输入,计算过程中的输入变化将无效
// 请在有效数据到来的前一个时钟提前复位,才能确保输入是有效的。
//////////////////////////////////////////////////////////////////////////////////


module div_16d8(
        input wire          clk_sys          ,
        input wire          reset_sys        ,
        input wire          reset_sync       , //同步高电平复位端口
        input wire [15:0]   divident         ,
        input wire [7:0]    divisor          ,
                     
        output reg [15:0]   q                , //商
        output reg [7:0]    remain           , //余数
        output wire         out_valid        ,
        output wire         in_valid            //给testbench作测试用,有效数据输入标志
    );
    
    reg [22:0] remain_s         ; //逐级递减的剩余数,位宽为16+(8-1)=23位
    reg [22:0] divident_shift   ;  //右移的比较数,与remain位宽保持一致
    
    reg [7:0] divisor_r;
    
    //需要16个时钟周期才能计算出结果
    reg [4:0] cnt;
    
    //初始化标志,为高时代表是初始化的第一个周期,此时输出有效信号in_valid会被屏蔽
    reg     flag_init;
    
    
    //cnt
    always@(posedge clk_sys or negedge reset_sys) begin
        if(!reset_sys) begin
            cnt <= 5'd0;
        end else if(reset_sync) begin
            cnt <= 5'd0;
        end else if(cnt == 5'd15) begin
            cnt <= 5'd0;
        end else begin
            cnt <= cnt + 5'd1;
        end
    end
    
    //flag_init
    always@(posedge clk_sys or negedge reset_sys) begin
        if(!reset_sys) begin
            flag_init <= 1'b1;
        end else if(reset_sync) begin
            flag_init <= 1'b1;
        end else if(cnt == 5'd15) begin
            flag_init <= 1'b0;
        end else begin
            flag_init <= flag_init;
        end
    end
    
    //divisor_r
    always@(posedge clk_sys or negedge reset_sys) begin
        if(!reset_sys) begin
            divisor_r <= 8'b0;
        end else if(reset_sync) begin
            divisor_r <= 8'b0;
        end else if(cnt == 5'd0) begin
            divisor_r <= divisor;  //锁存除数
        end else begin
            divisor_r <= divisor_r;
        end
    end
    
    //divident_shift
    always@(posedge clk_sys or negedge reset_sys) begin
        if(!reset_sys) begin
            divident_shift <= 23'b0;
        end else if(reset_sync) begin
            divident_shift <= 23'b0;        
        end else if(cnt == 5'd0) begin  //一开始从输入端口获得数据
            divident_shift <= {divisor,15'b0};  //末端补(16-1)个0
        end else if(cnt == 5'd1) begin  //后面从寄存器获得锁存的数据
            divident_shift <= {1'b0,divisor_r,14'b0};  //右移一位
        end else begin
            divident_shift <= {1'b0,divident_shift[22:1]};
        end 
    end
    
    //remain_s,逐级递减的剩余数,最后不能直接得到余数,因为在原本完成余数计算的时钟周期被更新为新的被除数
    //可能需要再减一次才能得到余数
    always@(posedge clk_sys or negedge reset_sys) begin
        if(!reset_sys) begin
            remain_s <= 23'b0;
        end else if(reset_sync) begin
            remain_s <= 23'b0;   
        end else if(cnt == 5'd0) begin
            remain_s <= {7'b0,divident};  //一开始补(8-1个0)
        end else if(remain_s >= divident_shift) begin
            remain_s <= remain_s - divident_shift;
        end else begin
            remain_s <= remain_s;
        end 
    end
    
    
    
    //q 商输出
    always@(posedge clk_sys or negedge reset_sys) begin
        if(!reset_sys) begin
            q <= 16'b0;
        end else if(reset_sync) begin
            q <= 16'b0;   
        end else if(remain_s >= divident_shift) begin
            q <= {q[14:0],1'b1};
        end else begin
            q <= {q[14:0],1'b0};
        end
    end
    
    //remain
    always@(posedge clk_sys or negedge reset_sys) begin
        if(!reset_sys) begin
            remain <= 8'b0;
        end else if(reset_sync) begin
            remain <= 8'b0;
        end else if((cnt == 5'd0) && (remain_s >= divident_shift)) begin
            remain <= remain_s - divident_shift;
        end else if((cnt == 5'd0) && (remain_s < divident_shift)) begin
            remain <= remain_s;
        end else begin
            remain <= remain;
        end
    
    end
    
    //out_valid
    assign out_valid = ((cnt == 5'd1)&&(!flag_init))?1'b1:1'b0;
    
    //in_valid
    assign in_valid = (cnt == 5'd0)?1'b1:1'b0;
    
endmodule
