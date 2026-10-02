module vector_edge #(
	parameter	WIDTH	= 4,
	parameter	EDGE_T	= "POSE",	//"POSE" "NEGE" "BOTH"
	parameter	OUTREG	= "NOREG"	//"NOREG" "OUTREG"
) (
	input				I_clk,
	input				I_rstn,

	input	[WIDTH-1:0]	I_signal,
	output	[WIDTH-1:0]	O_edge
);

reg [WIDTH-1:0]	R_signal[1:0];

always @(posedge I_clk or negedge I_rstn) begin
	if(!I_rstn)
		R_signal[0] <= {WIDTH{1'b0}};
	else 
		R_signal[0] <= I_signal;
end

generate
	if(OUTREG == "NOREG")
		case (EDGE_T)
			"POSE":	assign O_edge = (~R_signal[0]) & I_signal;
			"NEGE":	assign O_edge = R_signal[0] & (~I_signal);
			"BOTH":	assign O_edge = (R_signal[0] ^ I_signal);
		endcase
	else begin
		always @(posedge I_clk or negedge I_rstn) begin
			if(!I_rstn)
				R_signal[1] <= {WIDTH{1'b0}};
			else 
				R_signal[1] <= R_signal[0];
		end

		case (EDGE_T)
			"POSE":	assign O_edge = (~R_signal[1]) & R_signal[0];
			"NEGE":	assign O_edge = R_signal[1] & (~R_signal[0]);
			"BOTH":	assign O_edge = (R_signal[1] ^ R_signal[0]);
		endcase
	end
endgenerate


endmodule
