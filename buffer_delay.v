module buffer_delay #(
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


reg [DATAWIDTH-1:0]	R_data;
reg R_valid;

always @(posedge I_clk) begin
	if(O_ready)
		R_data <= I_data;
	else 
		R_data <= R_data;
end

always @(posedge I_clk or negedge I_rstn) begin
	if(!I_rstn)
		R_valid <= 1'b0;
	else case({I_ready, O_ready})
		2'b01:	R_valid <= 1'b1;
		2'b10:	R_valid <= 1'b0;
		default:R_valid <= R_valid;
	endcase
end

assign O_ready = ((!R_valid) || I_ready) && I_valid;
assign O_valid = R_valid;
assign O_data = R_data;


endmodule
