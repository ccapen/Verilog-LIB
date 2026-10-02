module simple_sync_fifo #(
	parameter	DATAWIDTH	= 8,
	parameter	DATADEPTH	= 256,		//must be 2**n
	parameter	SHOWAHEAD	= "ENABLE",	//"ENABLE" "DISABLE"
	parameter	TIM_PRIOR	= "DATA"	//"DATA" "ADDRESS"
) (
	input					I_clk,
	input					I_rstn,

	input					I_we,
	input	[DATAWIDTH-1:0]	I_wdata,
	output					O_full,

	input					I_re,
	output	[DATAWIDTH-1:0]	O_rdata,
	output					O_empty
);

localparam ADDRWIDTH = $clog2(DATADEPTH);

wire W_is_showahead = (SHOWAHEAD == "ENABLE");
wire [ADDRWIDTH:0] W_datadepth = DATADEPTH;


reg [ADDRWIDTH:0] R_waddr;
reg [ADDRWIDTH:0] R_raddr;
reg R_full;
reg R_empty;


wire [ADDRWIDTH:0] W_raddr;
wire [DATAWIDTH-1:0] W_rdata;

simple_async_ram_reg #(
	.DATAWIDTH		(DATAWIDTH),
	.DATADEPTH		(DATADEPTH),
	.ADDRWIDTH		(ADDRWIDTH),
	.DATARESET		("DISABLE")
) simple_async_ram_u(
	.I_wclk			(I_clk),
	.I_wrstn		(I_rstn),
	.I_we			(I_we && (!R_full)),
	.I_waddr		(R_waddr[ADDRWIDTH-1:0]),
	.I_wdata		(I_wdata),

	.I_raddr		(W_raddr[ADDRWIDTH-1:0]),
	.O_rdata		(W_rdata)
);


begin
	if(TIM_PRIOR == "DATA")begin
		assign W_raddr = (I_re && (!R_empty)) ? (R_raddr + 1'b1) : R_raddr;
		reg [DATAWIDTH-1:0]	R_rdata;

		always @(posedge I_clk) begin
			R_rdata <= W_rdata;
		end

		assign O_rdata = R_rdata;
	end
	else begin
		assign W_raddr = R_raddr;
		assign O_rdata = W_rdata;
	end
end

wire W_we_readside;

begin
	if((SHOWAHEAD == "ENABLE") && (TIM_PRIOR == "DATA"))begin
		reg R_we_d;
		always @(posedge I_clk or negedge I_rstn) begin
			if(!I_rstn)
				R_we_d <= 1'b0;
			else 
				R_we_d <= I_we;
		end
		assign W_we_readside = R_we_d;
	end
	else begin
		assign W_we_readside = I_we;
	end
end


always @(posedge I_clk or negedge I_rstn) begin
	if(!I_rstn)
		R_waddr <= {(ADDRWIDTH+1){1'b0}};
	else if(I_we && (!R_full))
		R_waddr <= R_waddr + 1'b1;
	else 
		R_waddr <= R_waddr;
	
	if(!I_rstn)
		R_raddr <= {(ADDRWIDTH+1){(!W_is_showahead)}};
	else if(I_re && (!R_empty))
		R_raddr <= R_raddr + 1'b1;
	else 
		R_raddr <= R_raddr;
	
	if(!I_rstn)
		R_full <= 1'b0;
	else case({I_we, I_re})
		2'b01:	R_full <= 1'b0;
		2'b10:	R_full <= (R_waddr == (R_raddr + W_datadepth - W_is_showahead));
		default:R_full <= (R_waddr == (R_raddr + W_datadepth + 1'b1 - W_is_showahead));
	endcase
	
	if(!I_rstn)
		R_empty <= 1'b1;
	else case({W_we_readside, I_re})
		2'b01:	R_empty <= (R_waddr == (R_raddr + 2'd2 - W_is_showahead));
		2'b10:	R_empty <= 1'b0;
		default:R_empty <= (R_waddr == (R_raddr + 1'b1 - W_is_showahead));
	endcase
end


assign O_full = R_full;
assign O_empty = R_empty;


endmodule
