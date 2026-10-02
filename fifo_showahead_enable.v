module fifo_showahead_enable #(
	parameter	DATAWIDTH	= 8
) (
	input						I_clk,
	input						I_rstn,

	output						O_re,
	input	[DATAWIDTH-1:0]		I_rdata,
	input						I_empty,

	input						I_re,
	output	[DATAWIDTH-1:0]		O_rdata,
	output						O_empty
);


reg R_empty;

always @(posedge I_clk or negedge I_rstn)begin
	if(!I_rstn)
		R_empty <= 1'b1;
	else if(I_re && (!O_re))
		R_empty <= 1'b1;
	else if((!I_re) && O_re)
		R_empty <= 1'b0;
	else 
		R_empty <= R_empty;
end

assign O_re = (R_empty || I_re) && (!I_empty);
assign O_rdata = I_rdata;
assign O_empty = R_empty;


endmodule
