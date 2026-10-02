module data_batch #(
	parameter DATAWIDTH		= 32,
	parameter BUFFERDEPTH	= 32,
	parameter BATCH_LENGTH	= 16,
	parameter MAX_DELAY		= 40	//if it == 0, means infinity
) (
	input					I_clk,
	input					I_rstn,

	input					I_we,

	output					O_re,
	input	[DATAWIDTH-1:0]	I_rdata,
	input					I_empty,

	output					O_valid,
	output	[DATAWIDTH-1:0]	O_data,
	input					I_ready
);

localparam DATACNTWIDTH	= $clog2(BUFFERDEPTH);


wire W_timeout;

begin
	if(MAX_DELAY == 0)
	begin
		assign W_timeout = 1'b0;
	end
	else if(MAX_DELAY == 1)
	begin
		assign W_timeout = 1'b1;
	end
	else begin
		localparam TIMECNTWIDTH	= $clog2(MAX_DELAY);

		reg [TIMECNTWIDTH-1:0] R_cnt_time;

		always@(posedge I_clk or negedge I_rstn)begin
			if(!I_rstn)
				R_cnt_time <= {TIMECNTWIDTH{1'b0}};
			else if(I_empty || O_valid)
				R_cnt_time <= {TIMECNTWIDTH{1'b0}};
			else if(W_timeout)
				R_cnt_time <= R_cnt_time;
			else 
				R_cnt_time <= R_cnt_time + 1'b1;
		end

		assign W_timeout = (R_cnt_time == (MAX_DELAY - 1));
	end
end


reg [DATACNTWIDTH-1:0] R_cnt_data;
reg R_valid;

always@(posedge I_clk or negedge I_rstn)begin
	if(!I_rstn)
		R_cnt_data <= {DATACNTWIDTH{1'b0}};
	else case({I_we, O_re})
		2'b01:	R_cnt_data <= R_cnt_data - 1'b1;
		2'b10:	R_cnt_data <= R_cnt_data + 1'b1;
		default:R_cnt_data <= R_cnt_data;
	endcase

	if(!I_rstn)
		R_valid <= 1'b0;
	else if(I_empty)
		R_valid <= 1'b0;
	else if((R_cnt_data >= BATCH_LENGTH) || W_timeout)
		R_valid <= 1'b1;
	else 
		R_valid <= R_valid;
end

assign O_re = I_ready && O_valid;
assign O_valid = (!I_empty) && R_valid;
assign O_data = I_rdata;


endmodule
