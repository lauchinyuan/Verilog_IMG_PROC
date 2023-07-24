module MUL(
	input [7:0] a,
	input [7:0] b,

	output wire [23:0] Data_out
	);

wire [23:0] temp[7:0];


assign		temp[0] = (b[0])? {{8{1'b0}},a,{8{1'b0}}}:24'd0;
assign  	temp[1] = (b[1])? {{7{1'b0}},a,{9{1'b0}}}:24'd0;
assign		temp[2] = (b[2])? {{6{1'b0}},a,{10{1'b0}}}:24'd0;
assign		temp[3] = (b[3])? {{5{1'b0}},a,{11{1'b0}}}:24'd0;
assign		temp[4] = (b[4])? {{4{1'b0}},a,{12{1'b0}}}:24'd0;
assign		temp[5] = (b[5])? {{3{1'b0}},a,{13{1'b0}}}:24'd0;
assign		temp[6] = (b[6])? {{2{1'b0}},a,{14{1'b0}}}:24'd0;
assign		temp[7] = (b[7])? {{1{1'b0}},a,{15{1'b0}}}:24'd0;



assign Data_out = temp[0]+temp[1]+temp[2]+temp[3]+temp[4]+temp[5]+temp[6]+temp[7];
					

endmodule