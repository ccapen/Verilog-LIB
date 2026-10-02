module width_split #(
	parameter	WDATAWIDTH	= 32,
	parameter	RDATAWIDTH	= 8,	//must be (WDATAWIDTH / n), must be divisible
	parameter	ENDIAN		= "LITTLE",		//"BIG" "LITTLE"
	parameter	PREFETCH	= 0,
	parameter	SPLITMULT	= WDATAWIDTH / RDATAWIDTH,	//AUTO SET
	parameter	SMADDRWIDTH	= $clog2(SPLITMULT)			//AUTO SET
) (
	input						I_clk,
	input						I_rstn,

	input						I_wvalid,
	input	[WDATAWIDTH-1:0]	I_wdata,
	input	[SPLITMULT-1:0]		I_wmask,
	output						O_wready,

	output						O_rvalid,
	output	[RDATAWIDTH-1:0]	O_rdata,
	output	[SMADDRWIDTH-1:0]	O_raddr,
	output						O_rlast,
	input						I_rready
);


reg [RDATAWIDTH-1:0] R_wdata[SPLITMULT-1:0];
wire [SPLITMULT-1:0] W_le_i_wmask;
reg [SPLITMULT-1:0] W_wmask;
reg [SPLITMULT-1:0] R_wmask;
reg [SMADDRWIDTH-1:0] R_cnt_raddr;
reg R_is_buffered;

wire [SMADDRWIDTH-1:0] W_init_addr;
wire [SMADDRWIDTH-1:0] W_next_addr;

width_split_prefetch #(
	// .ADDRORDER		(ADDRORDER),
	.PREFETCH		(PREFETCH),
	.SPLITMULT		(SPLITMULT),
	.SMADDRWIDTH	(SMADDRWIDTH)
) width_split_prefetch_u(
	.I_cur_addr		(R_cnt_raddr),
	.I_mask			(O_wready ? W_le_i_wmask : W_wmask),

	.O_init_addr	(W_init_addr),
	.O_next_addr	(W_next_addr)
);

genvar k;
generate
	for(k = 0; k < SPLITMULT; k = k + 1)
	begin:WDATA_BUFFER
		localparam integer sorted_k = (ENDIAN == "LITTLE") ? k : (SPLITMULT - 1 - k);
		assign W_le_i_wmask[k] = I_wmask[sorted_k];
		always @(posedge I_clk)begin
			if(O_wready)
				R_wdata[k] <= I_wdata[(sorted_k+1)*RDATAWIDTH-1:sorted_k*RDATAWIDTH];
			else 
				R_wdata[k] <= R_wdata[k];
		end
		always @(*)begin
			if(I_rready && (k == R_cnt_raddr))
				W_wmask[k] = 1'b1;
			else 
				W_wmask[k] = R_wmask[k];
		end
	end
endgenerate

always @(posedge I_clk or negedge I_rstn)begin
	if(!I_rstn)
		R_wmask <= {SPLITMULT{1'b1}};
	else if(O_wready)
		R_wmask <= W_le_i_wmask;
	else 
		R_wmask <= W_wmask;

	if(!I_rstn)
		R_cnt_raddr <= {SMADDRWIDTH{1'b0}};
	else if(O_wready)
		R_cnt_raddr <= W_init_addr;
	else if(I_rready || R_wmask[R_cnt_raddr])
		R_cnt_raddr <= W_next_addr;
	else 
		R_cnt_raddr <= R_cnt_raddr;
	
	if(!I_rstn)
		R_is_buffered <= 1'b0;
	else if(O_wready)
		R_is_buffered <= 1'b1;
	else if(O_rlast && (I_rready || R_wmask[R_cnt_raddr]))
		R_is_buffered <= 1'b0;
	else 
		R_is_buffered <= R_is_buffered;
end

assign O_wready = I_wvalid && ((O_rlast && I_rready) || (!R_is_buffered));
assign O_rvalid = (!R_wmask[R_cnt_raddr]) && R_is_buffered;
assign O_rdata  = R_wdata[R_cnt_raddr];
assign O_raddr = R_cnt_raddr;
assign O_rlast = (&W_wmask);


endmodule
