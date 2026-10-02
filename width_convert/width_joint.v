module width_joint #(
	parameter	WDATAWIDTH	= 8,
	parameter	RDATAWIDTH	= 32,	//must be (WDATAWIDTH * n)
	parameter	ENDIAN		= "LITTLE",		//"BIG" "LITTLE"
	parameter	ADDRORDER	= "INCREASE",	//"INCREASE" "DECREASE"
	parameter	JOINTMULT	= RDATAWIDTH / WDATAWIDTH,	//AUTO SET
	parameter	JMADDRWIDTH	= $clog2(JOINTMULT)			//AUTO SET
) (
	input						I_clk,
	input						I_rstn,

	input						I_wvalid,
	input	[WDATAWIDTH-1:0]	I_wdata,
	input	[JMADDRWIDTH-1:0]	I_waddr,
	input						I_wlast,
	output						O_wready,

	output						O_rvalid,
	output	[RDATAWIDTH-1:0]	O_rdata,
	output	[JOINTMULT-1:0]		O_rmask,
	input						I_rready
);


reg [WDATAWIDTH-1:0] R_rdata[JOINTMULT-1:0];
reg [JOINTMULT-1:0] R_rmask;
reg R_is_buffered;
wire [JMADDRWIDTH-1:0] W_final_addr	= (ADDRORDER == "INCREASE") ? (JOINTMULT - 1'b1) : {JMADDRWIDTH{1'b0}};

genvar k;
generate
	for(k = 0; k < JOINTMULT; k = k + 1)
	begin:RDATA_BUFFER
		always @(posedge I_clk)begin
			if(O_wready && (I_waddr == ((ENDIAN == "LITTLE") ? k : (JOINTMULT-1-k))))
				R_rdata[k] <= I_wdata;
			else 
				R_rdata[k] <= R_rdata[k];
		end
		always @(posedge I_clk or negedge I_rstn)begin
			if(!I_rstn)
				R_rmask[k] <= 1'b1;
			else if(O_wready && (I_waddr == ((ENDIAN == "LITTLE") ? k : (JOINTMULT-1-k))))
				R_rmask[k] <= 1'b0;
			else if(I_rready)
				R_rmask[k] <= 1'b1;
			else 
				R_rmask[k] <= R_rmask[k];
		end
		assign O_rdata[(k+1)*WDATAWIDTH-1:k*WDATAWIDTH] = R_rdata[k];
	end
endgenerate

always @(posedge I_clk or negedge I_rstn)begin
	if(!I_rstn)
		R_is_buffered <= 1'b0;
	else if(O_wready && ((I_waddr == W_final_addr) || I_wlast))
		R_is_buffered <= 1'b1;
	else if(I_rready)
		R_is_buffered <= 1'b0;
	else 
		R_is_buffered <= R_is_buffered;
end

assign O_wready = I_wvalid && (I_rready || (!R_is_buffered));
assign O_rvalid = R_is_buffered;
assign O_rmask = R_rmask;


endmodule
