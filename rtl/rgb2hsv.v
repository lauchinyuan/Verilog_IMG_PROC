`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: lauchinyuan
// Email: lauchinyuan@yeah.net
// Create Date: 2023/07/21 11:29:05
// Design Name: 
// Module Name: rgb2hsv
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: RGB转HSV,
// 由于除法计算需要16个周期,为了实现对数据的实时处理,本设计将6组RGB共18个周期的数据视为一族
// 使用多个除法器对输入的一族数据进行并行HSV计算,其中计算6个H值需要6个除法器
// 计算6个S值需要6个除法器,考虑量化,计算V无需除法器
//////////////////////////////////////////////////////////////////////////////////
module rgb2hsv(
        input wire       clk_sys    ,
        input wire       reset_sys  ,
        input wire       InVSYNC    ,
        input wire       InHSYNC    ,
        input wire       InEN       ,
        input wire [7:0] InData     ,

        output wire      OutVSYNC   ,
        output wire      OutHSYNC   ,
        output wire      OutEN      ,
        output reg [7:0] Outdata
    );
    
    //一族RGB的序列计数器
    reg [4:0] rgb_cnt;
    //一族HSV轮询输出选择计数器
    reg [4:0] hsv_cnt;
    //缓存RGB值的三原色寄存器,输入到相应计算单元进行处理
    reg [7:0] R[5:0];
    reg [7:0] G[5:0];
    reg [7:0] B[5:0];

    
    //计算一族共18个rgb数据,产生18个hsv信号,其中计算6个H值需要6个除法器,需要6个同步高电平复位信号控制除法器
    reg         H_reset[5:0];
    
    //计算6个S值需要6个除法器,需要6个同步高电平复位信号控制除法器
    reg         S_reset[5:0];
     
    
    //计算H时,用到的三原色数据R、G来自缓存器Rx、Gx,而B直接来自InData
    //需要通过电路得出这三种数据的最大值,最小值来计算H
    wire [7:0]  max_rgbr[5:0];  //R、G、B(InData)中的最大值
    wire [7:0]  min_rgbr[5:0];  //R、G、B(InData)中的最小值
    
    //计算S时,用到的三原色数据都来自寄存器Rx、Gx、Bx
    //需要通过电路得出这三种数据的最大值,最小值来计算H
    wire [7:0]  max_rgb[5:0];  //R、G、B中的最大值
    wire [7:0]  min_rgb[5:0];  //R、G、B中的最小值
    
    //计算V需要额外缓存一轮RGB三原色中的最大值
    reg [7:0]  max_rgb_reg[5:0];

    //计算H时用到g-b,b-r,r-g,以及max-min,R、G来自寄存器,B来自输入数据
    //由于本设计中使用的除法器均为无符号除法器,故当g-b,b-r,r-g,操作数为它们的相反数
    wire [7:0] g_minus_b[5:0];         //G-B(InData)
    wire [7:0] b_minus_r[5:0];         //B(InData)-R
    wire [7:0] r_minus_g[5:0];         //R-G
    wire [7:0] b_minus_g[5:0];         //B(InData)-G
    wire [7:0] r_minus_b[5:0];         //R-B(InData)
    wire [7:0] g_minus_r[5:0];         //G-R
    wire [7:0] max_minus_min_r[5:0];   //max_rgbr-min_rgbr

    
    //计算S时用到max-min,其中max、min都是三原色寄存器里的值
    wire [7:0] max_minus_min[5:0];  //max_rgb-min_rgb
    
    
    //计算H时可能的除法器的被除数输入都先乘以60,再进行除法,这样可以有更高的精度
    wire [15:0] g_minus_b_x60[5:0]      ;      
    wire [15:0] b_minus_r_x60[5:0]      ;      
    wire [15:0] r_minus_g_x60[5:0]      ; 
    wire [15:0] b_minus_g_x60[5:0]      ;      
    wire [15:0] r_minus_b_x60[5:0]      ;      
    wire [15:0] g_minus_r_x60[5:0]      ;    
    
    
    //计算S时max-min提前乘以8bit小数位宽的定点量化系数8'hff
    //乘过之后的值作为除法器输入的被除数,保证更高的精度
    wire [15:0] max_minus_min_q[5:0]   ;

    
    //计算H时,除法器的被除数,需要依据情况选择
    reg [15:0] divident_H[5:0]         ;  
    
    //计算S时,除法器的被除数,需要依据情况选择
    reg [15:0] divident_S[5:0]         ;  

    
    //计算H时的选择条件,对正在计算的RGB数据(实际上已经存到三原色寄存器中)的大小关系进行判断
    //当除法结果计算完成时,依据条件对H角度进行操作
    reg flag_g_leq_b[5:0]   ;  //G >=  B
    reg flag_max_eq_g[5:0]  ;  //max == G
    reg flag_max_eq_b[5:0]  ;  //max == B
    reg flag_max_eq_r[5:0]  ;  //max == R
    reg flag_b_leq_r[5:0]   ;  //B >= R
    reg flag_r_leq_g[5:0]   ;  //R >= G
    
    wire test_g_leq_b   ;  //G >=  B
    wire test_max_eq_g  ;  //max == G
    wire test_max_eq_b  ;  //max == B
    wire test_max_eq_r  ;  //max == R
    wire test_b_leq_r   ;  //B >= R
    wire test_r_leq_g   ;  //R >= G
    
    assign test_g_leq_b  =  flag_g_leq_b[2] ;
    assign test_max_eq_g =  flag_max_eq_g[2];
    assign test_max_eq_b =  flag_max_eq_b[2];
    assign test_max_eq_r =  flag_max_eq_r[2];
    assign test_b_leq_r  =  flag_b_leq_r[2] ;
    assign test_r_leq_g  =  flag_r_leq_g[2] ;


    //计算H时除法器计算的商
    wire [15:0] q_h[5:0];
    
    //计算S时除法器计算的商
    wire [15:0] q_s[5:0];  
    
    //计算H时除法器的有效信号标志
    wire       valid_h[5:0];
  
    //计算S时除法器的有效信号标志
    wire       valid_s[5:0];   
    
    //V输出有效标志信号
    reg       valid_v[5:0];
    
    //只要有一个计算单元算出H有效,则valid_h_all拉高
    //正常情况下valid_h_all间隔三个周期出现一次,s、v同理
    wire        valid_h_all;
    wire        valid_s_all;
    wire        valid_v_all;
    //hsv输出有效信号,其实就是OutEn
    wire       valid_hsv;

    //量化前以角度为单位的H值
    reg [8:0] H_ANG[5:0];
    wire [8:0] HANG_test; //test
    
    //H量化所用的乘法器的输出
    wire [24:0] H_Q[5:0];

    //计算得到的一族六组HSV值
    wire [7:0] H[5:0];
    wire [7:0] S[5:0];
    wire [7:0] V[5:0];
    
    //正常情况下RGB数据帧和对应的HSV数据帧相差19个时钟周期
    //将InVSYNC和InHSYNC打19拍即可得到OutVSYNC和OutHSYNC
    reg VSYNC_d[18:0];
    reg HSYNC_d[18:0];
    //同样将输入有效信号打19拍得到输出有效信号
    reg En_d   [18:0];
    
    //rgb_cnt
    always@(posedge clk_sys or negedge reset_sys) begin
        if(!reset_sys) begin
            rgb_cnt <= 5'd0;
/*         end else if(InHSYNC) begin
            rgb_cnt <= 5'd0; */
        end else if(InEN && rgb_cnt == 5'd17) begin
            rgb_cnt <= 5'd0;
        end else if(InEN) begin
            rgb_cnt <= rgb_cnt + 5'd1;
        end else begin
            rgb_cnt <= rgb_cnt;
        end
    end
    
    //暂存RGB一共18个值,因为本例中除法运算需要16个周期完成
    genvar i;
    //暂存RGB
    generate 
        for(i=0;i<=5;i=i+1) begin : RGB_REG
            
            //R寄存
            always@(posedge clk_sys or negedge reset_sys) begin
                if(!reset_sys) begin
                    R[i] <= 8'b0;
                end else if(rgb_cnt == (5'd0 + 3*i)) begin
                    R[i] <= InData;
                end else begin
                    R[i] <= R[i];
                end
            end

            //G寄存
            always@(posedge clk_sys or negedge reset_sys) begin
                if(!reset_sys) begin
                    G[i] <= 8'b0;
                end else if(rgb_cnt == (5'd1 + 3*i)) begin
                    G[i] <= InData;
                end else begin
                    G[i] <= G[i];
                end
            end

            //B寄存
            always@(posedge clk_sys or negedge reset_sys) begin
                if(!reset_sys) begin
                    B[i] <= 8'b0;
                end else if(rgb_cnt == (5'd2 + 3*i)) begin
                    B[i] <= InData;
                end else begin
                    B[i] <= B[i];
                end
            end            

        end
    endgenerate
    
    
    //除法器复位信号设置
    generate 
        for(i=0;i<=5;i=i+1) begin: DIV_RESET
        
            //H_reset
            always@(posedge clk_sys or negedge reset_sys) begin
                if(!reset_sys) begin
                    H_reset[i] <= 1'b0;
                end else if(rgb_cnt == (5'd0 + 3*i)) begin
                    H_reset[i] <= 1'b1;
                end else begin
                    H_reset[i] <= 1'b0;
                end
            end
            
            //S_reset
            always@(posedge clk_sys or negedge reset_sys) begin
                if(!reset_sys) begin
                    S_reset[i] <= 1'b0;
                end else if(rgb_cnt == (5'd1 + 3*i)) begin
                    S_reset[i] <= 1'b1;
                end else begin
                    S_reset[i] <= 1'b0;
                end
            end            
        end
    endgenerate
    
    //得到最大最小值
    generate 
        for(i=0;i<=5;i=i+1) begin: MAX_MIN
            assign max_rgbr[i] = ((R[i] >= G[i]) && (R[i] >= InData))?R[i]:(G[i] >= InData)?G[i]:InData;
            assign max_rgb[i] = ((R[i] >= G[i]) && (R[i] >= B[i]))?R[i]:(G[i] >= B[i])?G[i]:B[i];
            assign min_rgbr[i] = ((R[i] <= G[i]) && (R[i] <= InData))?R[i]:(G[i] <= InData)?G[i]:InData;
            assign min_rgb[i] = ((R[i] <= G[i]) && (R[i] <= B[i]))?R[i]:(G[i] <= B[i])?G[i]:B[i];
        end
    endgenerate
 
    //计算H、S时用到的数据
    generate 
        for(i=0;i<=5;i=i+1) begin: H_DATA
            assign g_minus_b[i] = G[i] - InData;
            assign b_minus_r[i] = InData - R[i];
            assign r_minus_g[i] = R[i] - G[i];
            assign b_minus_g[i] = InData - G[i];
            assign r_minus_b[i] = R[i] - InData;
            assign g_minus_r[i] = G[i] - R[i];
            assign max_minus_min_r[i] = max_rgbr[i] - min_rgbr[i];
            assign max_minus_min[i] = max_rgb[i] - min_rgb[i];
        end
    endgenerate 
    
    //H计算时除法器可能的被除数先乘以60
    generate 
        for(i=0;i<=5;i=i+1) begin: MULT_60_INST
        
            mult_8_8 mult_g_minus_b_x60(
                .a(g_minus_b[i]  ),
                .b(8'd60         ),
        
                .c(g_minus_b_x60[i])
            );
            
            mult_8_8 mult_b_minus_r_x60(
                .a(b_minus_r[i]      ),
                .b(8'd60             ),
        
                .c(b_minus_r_x60[i]  )
            ); 
            
            mult_8_8 mult_r_minus_g_x60(
                .a(r_minus_g[i]      ),
                .b(8'd60             ),
        
                .c(r_minus_g_x60[i]  )
            ); 

            mult_8_8 mult_b_minus_g_x60(
                .a(b_minus_g[i]      ),
                .b(8'd60             ),
        
                .c(b_minus_g_x60[i]  )
            ); 

            mult_8_8 mult_r_minus_b_x60(
                .a(r_minus_b[i]      ),
                .b(8'd60             ),
        
                .c(r_minus_b_x60[i]  )
            ); 
            
            mult_8_8 mult_g_minus_r_x60(
                .a(g_minus_r[i]      ),
                .b(8'd60             ),
        
                .c(g_minus_r_x60[i]  )
            ); 
        end
    endgenerate   

    //依据情况选择计算H时的被除数数据
    //H除法运算的被除数
    generate
        for(i=0;i<=5;i=i+1) begin : H_DIVIDENT
            always@(*) begin
                if(!reset_sys) begin
                    divident_H[i] = 16'b0;
                end else if(max_minus_min_r[i] == 8'd0) begin
                    divident_H[i] = 16'b0;
                end else if((max_rgbr[i] == R[i])&&(G[i] >= InData)) begin
                    divident_H[i] = g_minus_b_x60[i];
                end else if((max_rgbr[i] == R[i])&&(G[i] < InData)) begin
                    divident_H[i] = b_minus_g_x60[i];                
                end else if((max_rgbr[i] == G[i])&&(InData >= R[i])) begin
                    divident_H[i] = b_minus_r_x60[i];
                end else if((max_rgbr[i] == G[i])&&(InData < R[i])) begin
                    divident_H[i] = r_minus_b_x60[i];  
                end else if((max_rgbr[i] == InData) && (R[i] >= G[i])) begin
                    divident_H[i] = r_minus_g_x60[i];
                end else if((max_rgbr[i] == InData) && (R[i] < G[i])) begin
                    divident_H[i] = g_minus_r_x60[i];       
                end else begin
                    divident_H[i] = divident_H[i];
                end
            end 
        end
    endgenerate
       
    
    //计算S时,max_minus_min先乘以量化系数8'hff
    generate
        for(i=0;i<=5;i=i+1) begin : S_Q
            mult_8_8 mult_max_minus_min_q(
                .a(max_minus_min[i] ),
                .b(8'hff            ),
        
                .c(max_minus_min_q[i])
            );
        end
    endgenerate    
        
    //依据情况选择计算S时的被除数数据
    generate
        for(i=0;i<=5;i=i+1) begin : S_DIVIDENT
            always@(*) begin
                if(!reset_sys) begin
                    divident_S[i] <= 16'b0;
                end else if(max_rgb[i] == 8'd0) begin
                    divident_S[i] <= 16'b0;
                end else begin
                    divident_S[i] <= max_minus_min_q[i];
                end
            end            
        
        end
    endgenerate
    
    //处理S的除法器
    generate 
        for(i=0;i<=5;i=i+1) begin: S_DIV
            div_16d8 div_16d8_S(
                .clk_sys          (clk_sys      ),
                .reset_sys        (reset_sys    ),
                .reset_sync       (S_reset[i]   ), //同步高电平复位端口
                .divident         (divident_S[i]),
                .divisor          (max_rgb[i]   ),
        
                .q                (q_s[i]       ),
                .out_valid        (valid_s[i]   )
            );   

            //由于已经乘过量化系数,除法器计算结果的低8位就是S的值
            assign S[i] = q_s[i][7:0] & {8{valid_s[i]}};            
        end
    endgenerate
    
    //处理H的除法器
    generate
        for(i=0;i<=5;i=i+1) begin : H_DIV
            div_16d8 div_16d8_H(
                .clk_sys          (clk_sys          ),
                .reset_sys        (reset_sys        ),
                .reset_sync       (H_reset[i]       ), //同步高电平复位端口
                .divident         (divident_H[i]    ),
                .divisor          (max_minus_min_r[i]),
        
                .q                (q_h[i]           ),
                .out_valid        (valid_h[i]       )
            );  
        end
    endgenerate 
    
    //对H进行后处理,首先需要锁存RGB大小关系标志信号,用于后处理的判断条件
    generate
        for(i=0;i<=4;i=i+1) begin: CONDITION
        
            //G >= B?
            always@(posedge clk_sys or reset_sys) begin
                if(!reset_sys) begin
                    flag_g_leq_b[i] <= 1'b0;
                //第一组RGB值在rgb_cnt为3时全部输入寄存器中,则第i组RGB值在rgb_cnt为(3+3*i)时输入到寄存器
                //可以取得数据并进行大小关系判断
                //对于第5组RGB值,按照以上公式运算应该是rgb_cnt=18时输入到寄存器
                //但实际上rgb_cnt最大计数到17,18对应的是下一个计数周期rgb_cnt为0的位置 
                //故对i=5的条件判断不使用generate语句
                end else if((rgb_cnt==(5'd3+3*i))&&(G[i] >= B[i])) begin
                    flag_g_leq_b[i] <= 1'b1;
                end else if((rgb_cnt==(5'd3+3*i))&&(G[i] < B[i])) begin
                    flag_g_leq_b[i] <= 1'b0;
                end else begin
                    flag_g_leq_b[i] <= flag_g_leq_b[i];
                end
            end
            
            //B >= R?
            always@(posedge clk_sys or reset_sys) begin
                if(!reset_sys) begin
                    flag_b_leq_r[i] <= 1'b0;
                end else if((rgb_cnt==(5'd3+3*i))&&(B[i] >= R[i])) begin
                    flag_b_leq_r[i] <= 1'b1;
                end else if((rgb_cnt==(5'd3+3*i))&&(B[i] < R[i])) begin
                    flag_b_leq_r[i] <= 1'b0;
                end else begin
                    flag_b_leq_r[i] <= flag_b_leq_r[i];
                end
            end
 
            //R >= G?
            always@(posedge clk_sys or reset_sys) begin
                if(!reset_sys) begin
                    flag_r_leq_g[i] <= 1'b0;
                end else if((rgb_cnt==(5'd3+3*i))&&(R[i] >= G[i])) begin
                    flag_r_leq_g[i] <= 1'b1;
                end else if((rgb_cnt==(5'd3+3*i))&&(R[i] < G[i])) begin
                    flag_r_leq_g[i] <= 1'b0;
                end else begin
                    flag_r_leq_g[i] <= flag_r_leq_g[i];
                end
            end 
            
            //max == R?
            always@(posedge clk_sys or reset_sys) begin
                if(!reset_sys) begin
                    flag_max_eq_r[i] <= 1'b0;
                end else if((rgb_cnt==(5'd3+3*i))&&(max_rgb[i] == R[i])) begin
                    flag_max_eq_r[i] <= 1'b1;
                end else if((rgb_cnt==(5'd3+3*i))&&(max_rgb[i] != R[i])) begin
                    flag_max_eq_r[i] <= 1'b0;
                end else begin
                    flag_max_eq_r[i] <= flag_max_eq_r[i];
                end
            end            

            //max == B?
            always@(posedge clk_sys or reset_sys) begin
                if(!reset_sys) begin
                    flag_max_eq_b[i] <= 1'b0;
                end else if((rgb_cnt==(5'd3+3*i))&&(max_rgb[i] == B[i])) begin
                    flag_max_eq_b[i] <= 1'b1;
                end else if((rgb_cnt==(5'd3+3*i))&&(max_rgb[i] != B[i])) begin
                    flag_max_eq_b[i] <= 1'b0;
                end else begin
                    flag_max_eq_b[i] <= flag_max_eq_b[i];
                end
            end  

             //max == G?
            always@(posedge clk_sys or reset_sys) begin
                if(!reset_sys) begin
                    flag_max_eq_g[i] <= 1'b0;
                end else if((rgb_cnt==(5'd3+3*i))&&(max_rgb[i] == G[i])) begin
                    flag_max_eq_g[i] <= 1'b1;
                end else if((rgb_cnt==(5'd3+3*i))&&(max_rgb[i] != G[i])) begin
                    flag_max_eq_g[i] <= 1'b0;
                end else begin
                    flag_max_eq_g[i] <= flag_max_eq_g[i];
                end
            end  
        
        end
    
    endgenerate
    
    
    //对于i=5的条件进行锁存
    //G >= B?
    always@(posedge clk_sys or reset_sys) begin
        if(!reset_sys) begin
            flag_g_leq_b[5] <= 1'b0;
        //第一组RGB值在rgb_cnt为3时全部输入寄存器中,则第i组RGB值在rgb_cnt为(3+3*i)时输入到寄存器
        //可以取得数据并进行大小关系判断
        //对于第5组RGB值,按照以上公式运算应该是rgb_cnt=18时输入到寄存器
        //但实际上rgb_cnt最大计数到17,18对应的是下一个计数周期rgb_cnt为0的位置 
        //故对i=5的条件判断不使用generate语句
        end else if((rgb_cnt==(5'd0))&&(G[5] >= B[5])) begin
            flag_g_leq_b[5] <= 1'b1;
        end else if((rgb_cnt==(5'd0))&&(G[5] < B[5])) begin
            flag_g_leq_b[5] <= 1'b0;
        end else begin
            flag_g_leq_b[5] <= flag_g_leq_b[5];
        end
    end
    
    //B >= R?
    always@(posedge clk_sys or reset_sys) begin
        if(!reset_sys) begin
            flag_b_leq_r[5] <= 1'b0;
        end else if((rgb_cnt==(5'd0))&&(B[5] >= R[5])) begin
            flag_b_leq_r[5] <= 1'b1;
        end else if((rgb_cnt==(5'd0))&&(B[5] < R[5])) begin
            flag_b_leq_r[5] <= 1'b0;
        end else begin
            flag_b_leq_r[5] <= flag_b_leq_r[5];
        end
    end
    
    //R >= G?
    always@(posedge clk_sys or reset_sys) begin
        if(!reset_sys) begin
            flag_r_leq_g[5] <= 1'b0;
        end else if((rgb_cnt==(5'd0))&&(R[5] >= G[5])) begin
            flag_r_leq_g[5] <= 1'b1;
        end else if((rgb_cnt==(5'd0))&&(R[5] < G[5])) begin
            flag_r_leq_g[5] <= 1'b0;
        end else begin
            flag_r_leq_g[5] <= flag_r_leq_g[5];
        end
    end 
    
    //max == R?
    always@(posedge clk_sys or reset_sys) begin
        if(!reset_sys) begin
            flag_max_eq_r[5] <= 1'b0;
        end else if((rgb_cnt==(5'd0))&&(max_rgb[5] == R[5])) begin
            flag_max_eq_r[5] <= 1'b1;
        end else if((rgb_cnt==(5'd0))&&(max_rgb[5] != R[5])) begin
            flag_max_eq_r[5] <= 1'b0;
        end else begin
            flag_max_eq_r[5] <= flag_max_eq_r[5];
        end
    end            
    
    //max == B?
    always@(posedge clk_sys or reset_sys) begin
        if(!reset_sys) begin
            flag_max_eq_b[5] <= 1'b0;
        end else if((rgb_cnt==(5'd0))&&(max_rgb[5] == B[5])) begin
            flag_max_eq_b[5] <= 1'b1;
        end else if((rgb_cnt==(5'd0))&&(max_rgb[5] != B[5])) begin
            flag_max_eq_b[5] <= 1'b0;
        end else begin
            flag_max_eq_b[5] <= flag_max_eq_b[5];
        end
    end  
    
     //max == G?
    always@(posedge clk_sys or reset_sys) begin
        if(!reset_sys) begin
            flag_max_eq_g[5] <= 1'b0;
        end else if((rgb_cnt==(5'd0))&&(max_rgb[5] == G[5])) begin
            flag_max_eq_g[5] <= 1'b1;
        end else if((rgb_cnt==(5'd0))&&(max_rgb[5] != G[5])) begin
            flag_max_eq_g[5] <= 1'b0;
        end else begin
            flag_max_eq_g[5] <= flag_max_eq_g[5];
        end
    end  



    //H后处理
    generate
        for(i=0;i<=5;i=i+1) begin: H_POST
            //H_ANG
            always@(*) begin
                if(!reset_sys) begin
                    H_ANG[i] = 9'd0;
                end else if(flag_g_leq_b[i] && flag_max_eq_r[i]) begin
                    H_ANG[i] = q_h[i];
                end else if(!flag_g_leq_b[i] && flag_max_eq_r[i]) begin
                    H_ANG[i] = 9'd360 - q_h[i];
                end else if(flag_max_eq_g[i] && flag_b_leq_r[i]) begin
                    H_ANG[i] = q_h[i] + 9'd120;
                end else if(flag_max_eq_g[i] && !flag_b_leq_r[i]) begin
                    H_ANG[i] = 9'd120 - q_h[i];
                end else if(flag_max_eq_b[i] && flag_r_leq_g[i]) begin
                    H_ANG[i] = q_h[i] + 9'd240;
                end else if(flag_max_eq_b[i] && !flag_r_leq_g[i]) begin
                    H_ANG[i] = 9'd240 - q_h[i];
                end else begin
                    H_ANG[i] = H_ANG[i];
                end
            end
            
            //量化得到H,HANG是9位的,使用9位*16位(8位整数+8位小数)的无符号乘法器
            mult_16_9 mult_16_9_H_Q(
                    .a_16b   (16'hb5),
                    .b_9b    (H_ANG[i]),

                    .c       (H_Q[i])
                );  

            //截取量化后的整数部分并与对应的输出有效信号相与
            assign H[i] = H_Q[i][15:8] & {8{valid_h[i]}};
        end
    endgenerate
    
    //test
    assign HANG_test = H_ANG[2];
    
    
    //依据V计算公式,V值量化后就是max
    generate 
        for(i=0;i<=5;i=i+1) begin: V_PROCESSING
            //当V输出时,三原色寄存器里的值已经更新为新数据
            //故需要额外的max寄存器保存上一组三原色中的最大值
            if(i!=5) begin
                always@(posedge clk_sys or negedge reset_sys) begin
                    if(!reset_sys) begin
                        max_rgb_reg[i] <= 8'b0; 
                        //在确定的时钟时刻保存RGB中大最大值结果
                    end else if(rgb_cnt == (5'd3 + 3*i)) begin
                        max_rgb_reg[i] <= max_rgb[i];
                    end else begin
                        max_rgb_reg[i] <= max_rgb_reg[i];
                    end
                end                
            end else begin  //由于i=5时,3*i+3已经超过rgb_cnt的计数范围,实际上是下一个周期的0
                            //故使用额外的判断逻辑
                always@(posedge clk_sys or negedge reset_sys) begin
                    if(!reset_sys) begin
                        max_rgb_reg[i] <= 8'b0; 
                        //在确定的时钟时刻保存RGB中大最大值结果
                    end else if(rgb_cnt == (5'd0)) begin
                        max_rgb_reg[i] <= max_rgb[i];
                    end else begin
                        max_rgb_reg[i] <= max_rgb_reg[i];
                    end
                end            
            
            end

            
            //V无需额外运算资源,故认为当S计算完成的下一个时钟周期就是其有效信号
            //valid_v对valid_s打一拍
            always@(posedge clk_sys or negedge reset_sys) begin
                if(!reset_sys) begin
                    valid_v[i] <= 1'b0;
                end else begin
                    valid_v[i] <= valid_s[i];
                end
            end
            
            assign V[i] = max_rgb_reg[i] & {8{valid_v[i]}};
            
       end
    
    endgenerate
    
    //HSV有效信号
    assign valid_h_all = valid_h[0] | valid_h[1] | valid_h[2] | valid_h[3] | valid_h[4] | valid_h[5];
    assign valid_s_all = valid_s[0] | valid_s[1] | valid_s[2] | valid_s[3] | valid_s[4] | valid_s[5];
    assign valid_v_all = valid_v[0] | valid_v[1] | valid_v[2] | valid_v[3] | valid_v[4] | valid_v[5];
    
    assign valid_hsv = valid_h_all | valid_s_all | valid_v_all;
    
    //HSV信号循环输出计数器
    always@(posedge clk_sys or reset_sys) begin
        if(!reset_sys) begin
            hsv_cnt <= 5'd0;
        end else if(OutEN && hsv_cnt == 5'd17) begin
            hsv_cnt <= 5'd0;
        end else if(OutEN) begin
            hsv_cnt <= hsv_cnt + 5'd1;
        end else begin
            hsv_cnt <= hsv_cnt;
        end
    end
    
    
    //打拍得到HSYNC、VSYNC、En
    //打一拍
    always@(posedge clk_sys or negedge reset_sys) begin
        if(!reset_sys) begin
            HSYNC_d[0] <= 1'b0;
            VSYNC_d[0] <= 1'b0;
            En_d[0]    <= 1'b0;
        end else begin
            HSYNC_d[0] <= InHSYNC;
            VSYNC_d[0] <= InVSYNC;
            En_d[0]    <= InEN;
        end
    end
    
    //继续打18拍
    generate
        for(i=1;i<=18;i=i+1) begin: HVSYNC
            always@(posedge clk_sys or negedge reset_sys) begin
                if(!reset_sys) begin
                    HSYNC_d[i] <= 1'b0;
                    VSYNC_d[i] <= 1'b0;
                    En_d[i]    <= 1'b0;
                end else begin
                    HSYNC_d[i] <= HSYNC_d[i-1];
                    VSYNC_d[i] <= VSYNC_d[i-1];
                    En_d[i]    <= En_d[i-1];
                end
            end        
        
        end
    endgenerate
    
    //OutHSYNC
    assign OutHSYNC = HSYNC_d[18];
    assign OutVSYNC = VSYNC_d[18];
    
    //OutEN
    assign OutEN = En_d[18];
    
    //Outdata
    always@(*) begin
        if(!reset_sys) begin
            Outdata = 8'b0;
        end case(hsv_cnt) 
            5'd0: begin
                Outdata = H[0];
            end
            5'd1: begin
                Outdata = S[0];
            end            
            5'd2: begin
                Outdata = V[0];
            end              
            5'd3: begin
                Outdata = H[1];
            end
            5'd4: begin
                Outdata = S[1];
            end            
            5'd5: begin
                Outdata = V[1];
            end  
            5'd6: begin
                Outdata = H[2];
            end
            5'd7: begin
                Outdata = S[2];
            end            
            5'd8: begin
                Outdata = V[2];
            end              
            5'd9: begin
                Outdata = H[3];
            end
            5'd10: begin
                Outdata = S[3];
            end            
            5'd11: begin
                Outdata = V[3];
            end             
            5'd12: begin
                Outdata = H[4];
            end
            5'd13: begin
                Outdata = S[4];
            end            
            5'd14: begin
                Outdata = V[4];
            end              
            5'd15: begin
                Outdata = H[5];
            end
            5'd16: begin
                Outdata = S[5];
            end            
            5'd17: begin
                Outdata = V[5];
            end  
            default: begin
                Outdata = 8'b0;
            end
        endcase
    end
    
    
    
endmodule
