module simple_sync_ram_reg #(
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

genvar k;

generate
	if(DATARESET == "ENABLE")
	begin
		for(k = 0; k < DATADEPTH; k = k+1)
		begin:data_write
			always @(posedge I_clk or negedge I_rstn) begin
				if(!I_rstn)
					R_data[k] <= {DATAWIDTH{1'b0}};
				else if(I_we && (I_waddr == k))
					R_data[k] <= I_wdata;
				else 
					R_data[k] <= R_data[k];
			end
		end
	end
	else 
	begin
		for(k = 0; k < DATADEPTH; k = k+1)
		begin:data_write
			always @(posedge I_clk) begin
				if(I_we && (I_waddr == k))
					R_data[k] <= I_wdata;
				else 
					R_data[k] <= R_data[k];
			end
		end
	end
endgenerate


reg [DATAWIDTH-1:0]	R_rdata;

always @(posedge I_clk or negedge I_rstn) begin
	if(!I_rstn)
		R_rdata <= {DATAWIDTH{1'b0}};
	else if(I_re)
		R_rdata <= R_data[I_raddr];
	else 
		R_rdata <= R_rdata;
end

assign O_rdata = R_rdata;

endmodule
