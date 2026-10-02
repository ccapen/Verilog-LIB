module vector_delay #(
	parameter WIDTH = 4,
	parameter DELAY = 2
)(
	input					I_clk,
	input					I_rstn,

	input	[WIDTH-1 : 0]	I_data,
	output	[WIDTH-1 : 0]	O_data
);

reg [WIDTH-1 : 0] R_data [DELAY : 1];

always@(posedge I_clk or negedge I_rstn)
if(!I_rstn)
	R_data[1] <= {WIDTH{1'b0}};
else 
	R_data[1] <= I_data;

genvar i;
generate
	for(i = 1; i < DELAY; i = i + 1)
	begin:delay_loop
		always@(posedge I_clk or negedge I_rstn)
		if(!I_rstn)
			R_data[i+1] <= {WIDTH{1'b0}};
		else 
			R_data[i+1] <= R_data[i];
	end
endgenerate

generate
	if(DELAY == 0)
		assign O_data = I_data;
	else
		assign O_data = R_data[DELAY];
endgenerate

endmodule
