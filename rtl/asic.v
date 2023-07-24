/*
    文件明： asic.v
    文件描述： 可配置图像预处理ASIC模块顶层文件
*/
module asic(
   input          clk_sys      // |<s
  ,input          reset_sys    // |<s
  ,input          InVSYNC      // |<i
  ,input          InHSYNC      // |<i
  ,input          InEN         // |<i
  ,input  [7:0]   InData       // |<i
  ,input          CFG_VALID    // |<i
  ,input  [7:0]   CFG_REG      // |<i
  ,output         OutVSYNC     // |>o
  ,output         OutHSYNC     // |>o
  ,output         OutEN        // |>o
  ,output [7:0]   OutData      // |>o
);
//--------------  参赛选手作答区  ------------------
reg [7:0] MODE_REG;
wire        OutVSYNC_Grey;
wire        OutHSYNC_Grey;
wire        OutEN_Grey;
wire [7:0]  OutData_Grey ;


//MODE_REG
always@(posedge clk_sys or negedge reset_sys) begin
    if(!reset_sys) begin
        MODE_REG <= 8'd0;
    end else if(CFG_VALID) begin
        MODE_REG <= CFG_REG;
    end else begin
        MODE_REG <= MODE_REG;
    end
end

//选择输出通道
always@(*) begin    
    case(MODE_REG[1:0]) 
        2'b00: begin //不处理
            OutVSYNC = InVSYNC;
            OutHSYNC = InHSYNC;
            OutEN = InEN;
            OutData = InData;
        end 
        2'b01: begin //灰度化
            OutVSYNC = OutVSYNC_Grey  ;
            OutHSYNC = OutHSYNC_Grey  ;
            OutEN   = OutEN_Grey      ;
            OutData = OutData_Grey    ;            
        end
        default: begin //默认不处理
            OutVSYNC = InVSYNC;
            OutHSYNC = InHSYNC;
            OutEN = InEN;
            OutData = InData;        
        end
    endcase
end




//灰度化
Grey_scale Grey_scale_inst(
        .clk_sys    (clk_sys  ),
        .reset_sys  (reset_sys),
        .InVSYNC    (InVSYNC  ),
        .InHSYNC    (InHSYNC  ),
        .InEN       (InEN     ),
        .InData     (InData   ),
    
        .OutVSYNC   (OutVSYNC_Grey),
        .OutHSYNC   (OutHSYNC_Grey),
        .OutEN      (OutEN_Grey   ),
        .OutData    (OutData_Grey )
	);



//---------------  作答区分割线  -------------------
endmodule
