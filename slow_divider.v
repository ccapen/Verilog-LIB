module slow_divider #(
	parameter DIVIDENDWIDTH	= 16,
	parameter DIVISORWIDTH	= 8,
	parameter OUTPUT_KEEP	= "DISABLE"	//"ENABLE" "DISABLE"
)(
	input						I_clk,
	input						I_rstn,

	input						I_valid,
	input	[DIVIDENDWIDTH-1:0]	I_dividend,
	input	[DIVISORWIDTH-1:0]	I_divisor,
	output						O_ready,

	output						O_valid,
	output	[DIVIDENDWIDTH-1:0]	O_quotient,
	output	[DIVISORWIDTH-1:0]	O_reminder
);

localparam CNTWIDTH = $clog2(DIVIDENDWIDTH);

reg [CNTWIDTH-1:0] R_cnt;
reg [DIVIDENDWIDTH-1:0] R_dividend;
reg [DIVISORWIDTH-1:0] R_divisor;
reg R_ready;
reg R_valid;
reg [DIVIDENDWIDTH-1:0] R_quotient;
reg [DIVISORWIDTH:0] R_reminder;


always@(posedge I_clk or negedge I_rstn)begin
	if(!I_rstn)
		R_cnt <= {CNTWIDTH{1'b0}};
	else if(I_valid && O_ready)
		R_cnt <= (DIVIDENDWIDTH - 1'b1);
	else if(R_cnt == {CNTWIDTH{1'b0}})
		R_cnt <= {CNTWIDTH{1'b0}};
	else 
		R_cnt <= R_cnt - 1'b1;

	if(!I_rstn)
		R_dividend <= {DIVIDENDWIDTH{1'b0}};
	else if(I_valid && O_ready)
		R_dividend <= {I_dividend[DIVIDENDWIDTH-2:0], 1'b0};
	else 
		R_dividend <= R_dividend;

	if(!I_rstn)
		R_divisor <= {DIVISORWIDTH{1'b0}};
	else if(I_valid && O_ready)
		R_divisor <= I_divisor;
	else 
		R_divisor <= R_divisor;

	if(!I_rstn)
		R_ready <= 1'b1;
	else if(I_valid && O_ready)
		R_ready <= 1'b0;
	else if(R_cnt == {CNTWIDTH{1'b0}})
		R_ready <= 1'b1;
	else 
		R_ready <= R_ready;

	if(!I_rstn)
		R_valid <= 1'b0;
	else if((R_cnt == {CNTWIDTH{1'b0}}) && (!R_ready))
		R_valid <= 1'b1;
	else 
		R_valid <= 1'b0;

	if(!I_rstn)
		R_quotient <= {DIVIDENDWIDTH{1'b0}};
	else if(!R_ready)
		R_quotient[R_cnt] <= (R_reminder >= R_divisor);

	if(!I_rstn)
		R_reminder <= {(DIVISORWIDTH+1){1'b0}};
	else if(I_valid && O_ready)
		R_reminder <= I_dividend[DIVIDENDWIDTH-1];
	else if(!R_ready)
		R_reminder <= {((R_reminder >= R_divisor) ? (R_reminder - R_divisor) : R_reminder), R_dividend[R_cnt]};
	else 
		R_reminder <= R_reminder;
end

assign O_ready = R_ready;

begin
	if(OUTPUT_KEEP == "DISABLE")
	begin
		assign O_valid = R_valid;
		assign O_quotient = R_quotient;
		assign O_reminder = R_reminder[DIVISORWIDTH:1];
	end
	else begin
		reg R_out_valid;
		reg [DIVIDENDWIDTH-1:0] R_out_quotient;
		reg [DIVISORWIDTH:0] R_out_reminder;
		always@(posedge I_clk or negedge I_rstn)begin
			if(!I_rstn)
				R_out_valid <= 1'b0;
			else 
				R_out_valid <= R_valid;
			
			if(!I_rstn)
				R_out_quotient <= {DIVIDENDWIDTH{1'b0}};
			else if(R_valid)
				R_out_quotient <= R_quotient;
			else 
				R_out_quotient <= R_out_quotient;
			
			if(!I_rstn)
				R_out_reminder <= {DIVISORWIDTH{1'b0}};
			else if(R_valid)
				R_out_reminder <= R_reminder[DIVISORWIDTH-1:0];
			else 
				R_out_reminder <= R_out_reminder;
		end
		assign O_valid = R_out_valid;
		assign O_quotient = R_out_quotient;
		assign O_reminder = R_out_reminder;
	end
end


endmodule
