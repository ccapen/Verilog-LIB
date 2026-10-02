module timing_split #(
	parameter	DATAWIDTH	= 8
) (
	input					I_clk,
	input					I_rstn,

	input					I_valid,
	input	[DATAWIDTH-1:0]	I_data,
	output					O_ready,

	output					O_valid,
	output	[DATAWIDTH-1:0]	O_data,
	input					I_ready
);

reg [DATAWIDTH-1:0] R_data[1:0];
reg [1:0] R_waddr;
reg [1:0] R_raddr;
reg R_nfull;
reg R_valid;	//nempty


always @(posedge I_clk) begin
	if(O_ready && (R_waddr[0] == 1'b0))
		R_data[0] <= I_data;
	else 
		R_data[0] <= R_data[0];

	if(O_ready && (R_waddr[0] == 1'b1))
		R_data[1] <= I_data;
	else 
		R_data[1] <= R_data[1];
end

always @(posedge I_clk or negedge I_rstn) begin
	if(!I_rstn)
		R_waddr <= 2'b0;
	else if(O_ready)
		R_waddr <= R_waddr + 1'b1;
	else 
		R_waddr <= R_waddr;

	if(!I_rstn)
		R_raddr <= 2'b0;
	else if(O_valid && I_ready)
		R_raddr <= R_raddr + 1'b1;
	else 
		R_raddr <= R_raddr;

	if(!I_rstn)
		R_nfull <= 1'b1;
	else case({O_ready, (O_valid && I_ready)})
		2'b01:	R_nfull <= 1'b1;
		2'b10:	R_nfull <= !(R_waddr == (R_raddr - 2'b11));
		default:R_nfull <= !(R_waddr == (R_raddr - 2'b10));
	endcase

	if(!I_rstn)
		R_valid <= 1'b0;
	else case({O_ready, (O_valid && I_ready)})
		2'b01:	R_valid <= !(R_waddr == (R_raddr + 1'b1));
		2'b10:	R_valid <= 1'b1;
		default:R_valid <= !(R_waddr == R_raddr);
	endcase
end

assign O_ready = R_nfull && I_valid;
assign O_valid = R_valid;
assign O_data = R_data[R_raddr[0]];

endmodule
