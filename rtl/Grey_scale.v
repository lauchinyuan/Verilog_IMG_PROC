module Grey_scale(
	input wire          clk_sys ,
	input wire          reset_sys,
	input wire          InVSYNC,
	input wire          InHSYNC,
	input wire          InEN,
	input wire [7:0]    InData,

	output              OutVSYNC,
	output              OutHSYNC,
	output              OutEN,
	output reg [7:0]    OutData

	);

parameter R_P = 8'b01001100 ;
parameter G_P = 8'b10010111 ;
parameter B_P = 8'b00011100 ;

reg [7:0] r;
reg [7:0] g;


wire [23:0] r_out;
wire [23:0] g_out;
wire [23:0] b_out;

//计数
reg [1:0] cnt ;
always@(posedge clk_sys or negedge reset_sys) begin
	if(!reset_sys)
		cnt <= 'd0;
	else if (cnt == 'd2 && InEN)
		cnt <= 'd0 ;
	else if(InEN) 
		cnt <= cnt + 'd1 ;
end

//r*0.3
MUL U0(
.a 			(r),
.b 			(R_P),
.Data_out 	(r_out)
);

always@(posedge clk_sys or negedge reset_sys)begin
	if(!reset_sys)
		r <= 'd0;
	else if(cnt == 'd0)
		r <= InData;
	else 
		r <= r ;

end

//g*0.59

MUL U1(
.a 			(g),
.b 			(G_P),
.Data_out 	(g_out)
);

always@(posedge clk_sys or negedge reset_sys)begin
	if(!reset_sys)
		g <= 'd0;
	else if(cnt == 'd1)
		g <= InData;
	else 
		g <= g ;	
end

//b*0.11

MUL U2(
.a 			(InData),
.b 			(B_P),
.Data_out 	(b_out)
);

always@(posedge clk_sys or negedge reset_sys)begin
	if(!reset_sys)
		OutData <= 'd0;
	else if(cnt == 'd2)
		OutData <= r_out[23:16]+g_out[23:16]+b_out[23:16];
	else 
		OutData <= OutData ;	
end

//OutEN 打慢三拍 ；
reg OutEN0,OutEN1,OutEN2 ;
assign OutEN = OutEN2 ;
always@(posedge clk_sys or negedge reset_sys)begin
	if(!reset_sys) begin
		OutEN0 <= 'd0;
		OutEN1 <= 'd0 ;
		OutEN2 <= 'd0 ;
	end
	else begin 
		OutEN0 <= InEN ;
		OutEN1 <= OutEN0 ;
		OutEN2 <= OutEN1 ;
	end
end

//OutVSYNC 打慢三拍 ；
reg OutVSYNC0,OutVSYNC1,OutVSYNC2 ;
assign OutVSYNC = OutVSYNC2 ;
always@(posedge clk_sys or negedge reset_sys)begin
	if(!reset_sys) begin
		OutVSYNC0 <= 'd0;
		OutVSYNC1 <= 'd0 ;
		OutVSYNC2 <= 'd0 ;
	end
	else begin 
		OutVSYNC0 <= InVSYNC ;
		OutVSYNC1 <= OutVSYNC0 ;
		OutVSYNC2 <= OutVSYNC1 ;
	end
end

//OutHSYNC 打慢三拍 ；
reg OutHSYNC0,OutHSYNC1,OutHSYNC2 ;
assign OutHSYNC = OutHSYNC2 ;
always@(posedge clk_sys or negedge reset_sys)begin
	if(!reset_sys) begin
		OutHSYNC0 <= 'd0;
		OutHSYNC1 <= 'd0 ;
		OutHSYNC2 <= 'd0 ;
	end
	else begin 
		OutHSYNC0 <= InHSYNC ;
		OutHSYNC1 <= OutHSYNC0 ;
		OutHSYNC2 <= OutHSYNC1 ;
	end
end



endmodule
