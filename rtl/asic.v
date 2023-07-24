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
reg [7:0]   MODE_REG;
wire        OutVSYNC_Gray   ;
wire        OutHSYNC_Gray   ;
wire        OutEN_Gray      ;
wire [7:0]  OutData_Gray    ;

wire        OutVSYNC_HSV    ;
wire        OutHSYNC_HSV    ;
wire        OutEN_HSV       ;
wire [7:0]  OutData_HSV     ;


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
            OutVSYNC = OutVSYNC_Gray  ;
            OutHSYNC = OutHSYNC_Gray  ;
            OutEN   =  OutEN_Gray     ;
            OutData =  OutData_Gray   ;            
        end
        2'b10: begin //HSV
            OutVSYNC = OutVSYNC_HSV  ;
            OutHSYNC = OutHSYNC_HSV  ;
            OutEN   =  OutEN_HSV     ;
            OutData =  OutData_HSV   ;            
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
gray_scale gray_scale_inst(
        .clk_sys    (clk_sys  ),
        .reset_sys  (reset_sys),
        .InVSYNC    (InVSYNC  ),
        .InHSYNC    (InHSYNC  ),
        .InEN       (InEN     ),
        .InData     (InData   ),
    
        .OutVSYNC   (OutVSYNC_Gray),
        .OutHSYNC   (OutHSYNC_Gray),
        .OutEN      (OutEN_Gray   ),
        .OutData    (OutData_Gray )
	);
    
//RGB转HSV
    rgb2hsv rgb2hsv_inst(
        .clk_sys    (clk_sys      ),
        .reset_sys  (reset_sys    ),
        .InVSYNC    (InVSYNC      ),
        .InHSYNC    (InHSYNC      ),
        .InEN       (InEN         ),
        .InData     (InData       ),
                     
        .OutVSYNC   (OutVSYNC_HSV ),
        .OutHSYNC   (OutHSYNC_HSV ),
        .OutEN      (OutEN_HSV    ),
        .Outdata    (Outdata_HSV  )
    );
//---------------  作答区分割线  -------------------
endmodule
