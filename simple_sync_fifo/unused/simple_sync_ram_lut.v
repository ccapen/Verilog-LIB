module simple_sync_ram_lut #(
	parameter	DATAWIDTH	= 8,
	parameter	DATADEPTH	= 256,	//must be 2**n
	parameter	ADDRWIDTH	= $clog2(DATADEPTH),
	parameter	DATARESET	= "DISABLE"	//"ENABLE" "DISABLE"
) (
	input					I_clk,
	input					I_rstn,

	input					I_we,
	input	[ADDRWIDTH-1:0]	I_waddr,
	input	[DATAWIDTH-1:0]	I_wdata,

	input					I_re,
	input	[ADDRWIDTH-1:0]	I_raddr,
	output	[DATAWIDTH-1:0]	O_rdata
);

reg [DATAWIDTH-1:0] R_data[DATADEPTH-1:0];

integer i;

generate
	if(DATARESET == "ENABLE")
	begin
		always @(posedge I_clk or negedge I_rstn) begin
			if(!I_rstn)begin
				for(i = 0; i < DATADEPTH; i = i + 1)begin
					R_data[i] <= {DATAWIDTH{1'b0}};
				end
			end
			else if(I_we)
				R_data[I_waddr] <= I_wdata;
		end
	end
	else 
	begin
		always @(posedge I_clk) begin
			if(I_we)
				R_data[I_waddr] <= I_wdata;
		end
	end
endgenerate

wire [DATAWIDTH-1:0] W_rdata = R_data[I_raddr];

reg [DATAWIDTH-1:0]	R_rdata;

always @(posedge I_clk or negedge I_rstn) begin
	if(!I_rstn)
		R_rdata <= {DATAWIDTH{1'b0}};
	else if(I_re)
		R_rdata <= W_rdata;
	else 
		R_rdata <= R_rdata;
end

assign O_rdata = R_rdata;

endmodule
