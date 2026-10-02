module time_delay_ms #(
	parameter	CLK_FREQ	= 50_000_000,
	parameter	DELAY_MS	= 50
) (
	input			I_clk,

	input			I_rstn,
	output			O_rstn
);

localparam	MSCNTWIDTH	= $clog2(CLK_FREQ / 1000);
localparam	DLCNTWIDTH	= $clog2(DELAY_MS + 1);

reg [MSCNTWIDTH-1:0] R_cnt_ms;
reg [DLCNTWIDTH-1:0] R_cnt_dl;

wire W_ms_trig = (R_cnt_ms >= ((CLK_FREQ / 1000) - 1));
wire W_dl_end  = (R_cnt_dl >= DELAY_MS);

reg R_rstn;

always @(posedge I_clk or negedge I_rstn) begin
	if(!I_rstn)
		R_cnt_ms <= {MSCNTWIDTH{1'b0}};
	else if(W_ms_trig || W_dl_end)
		R_cnt_ms <= {MSCNTWIDTH{1'b0}};
	else 
		R_cnt_ms <= R_cnt_ms + 1'b1;
	
	if(!I_rstn)
		R_cnt_dl <= {DLCNTWIDTH{1'b0}};
	else if(W_ms_trig && (!W_dl_end))
		R_cnt_dl <= R_cnt_dl + 1'b1;
	else 
		R_cnt_dl <= R_cnt_dl;
	
	if(!I_rstn)
		R_rstn <= 1'b0;
	else 
		R_rstn <= W_dl_end;
end

assign O_rstn = R_rstn;


endmodule
