module en_clk_divider #(
	parameter	CLK_FREQ	= 50_000_000,
	parameter	EN_FREQ		= 50,
	parameter	CLK_DIVIDE	= (CLK_FREQ / EN_FREQ),
	parameter	EN_POSITION	= "END"	//"START" "END"
) (
	input			I_clk,
	input			I_rstn,

	output			O_clk_en
);

localparam CNTWIDTH	= $clog2(CLK_DIVIDE);
reg R_clk_en;

begin
	if(CNTWIDTH > 16)
	begin
		localparam	PRECNTWIDTH		= (CNTWIDTH / 2);
		localparam	POSTCNTWIDTH	= (CNTWIDTH - PRECNTWIDTH);
		localparam	POSTCNTMAX		= ((CLK_DIVIDE - 1) >> PRECNTWIDTH);
		localparam	POSTCNTLEFT		= ((CLK_DIVIDE - 1) & {PRECNTWIDTH{1'b1}});
		reg [PRECNTWIDTH:0] R_cnt_pre;
		reg [POSTCNTWIDTH-1:0] R_cnt_post;
		wire W_carry = (R_cnt_post == POSTCNTMAX) && (R_cnt_pre == (POSTCNTLEFT + 1));
		always @(posedge I_clk or negedge I_rstn) begin
			if(!I_rstn)
				R_cnt_pre <= {(PRECNTWIDTH+1){1'b0}};
			else if(W_carry)
				R_cnt_pre <= {(PRECNTWIDTH+1){1'b0}};
			else 
				R_cnt_pre <= R_cnt_pre[PRECNTWIDTH-1:0] + 1'b1;
			
			if(!I_rstn)
				R_cnt_post <= {POSTCNTWIDTH{1'b0}};
			else if(W_carry)
				R_cnt_post <= {POSTCNTWIDTH{1'b0}};
			else if(!R_cnt_pre[PRECNTWIDTH])
				R_cnt_post <= R_cnt_post;
			else 
				R_cnt_post <= R_cnt_post + 1'b1;
			
			if(!I_rstn)
				R_clk_en <= 1'b0;
			else if(EN_POSITION == "END")
				R_clk_en <= W_carry;
			else 
				R_clk_en <= (R_cnt_pre == {(PRECNTWIDTH+1){1'b0}});
		end
	end
	else 
	begin
		reg [CNTWIDTH-1:0] R_cnt;
		always @(posedge I_clk or negedge I_rstn) begin
			if(!I_rstn)
				R_cnt <= {CNTWIDTH{1'b0}};
			else if(R_cnt == (CLK_DIVIDE - 1))
				R_cnt <= {CNTWIDTH{1'b0}};
			else 
				R_cnt <= R_cnt + 1'b1;
			
			if(!I_rstn)
				R_clk_en <= 1'b0;
			else if(EN_POSITION == "END")
				R_clk_en <= (R_cnt == (CLK_DIVIDE - 1));
			else 
				R_clk_en <= (R_cnt == {CNTWIDTH{1'b0}});
		end
	end
end

assign O_clk_en = R_clk_en;

endmodule
