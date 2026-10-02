module width_split_prefetch #(
	// parameter	ADDRORDER	= "INCREASE",	//"INCREASE" "DECREASE"
	parameter	PREFETCH	= 0,
	parameter	SPLITMULT	= 4,
	parameter	SMADDRWIDTH	= $clog2(SPLITMULT)			//AUTO SET
) (
	input	[SMADDRWIDTH-1:0]	I_cur_addr,
	input	[SPLITMULT-1:0]		I_mask,

	output	[SMADDRWIDTH-1:0]	O_init_addr,
	output	[SMADDRWIDTH-1:0]	O_next_addr
);

localparam LOCAL_PREFETCH = (PREFETCH >= SPLITMULT) ? (SPLITMULT - 1) : PREFETCH;


begin
	if(LOCAL_PREFETCH == 0)begin
		assign O_init_addr	= {SMADDRWIDTH{1'b0}};
		assign O_next_addr	= (I_cur_addr + 1'b1);
		// assign O_init_addr	= (ADDRORDER == "INCREASE") ? {SMADDRWIDTH{1'b0}} : (SPLITMULT - 1'b1);
		// assign O_next_addr	= (ADDRORDER == "INCREASE") ? (I_cur_addr + 1'b1) : (I_cur_addr - 1'b1);
	end
	else begin
	// else if(ADDRORDER == "INCREASE")begin
		reg	[SMADDRWIDTH-1:0]	W_init_addr;
		reg	[SMADDRWIDTH-1:0]	W_next_addr;
		reg W_init_lock;
		reg W_next_lock;
		integer i;
		always @(*)begin
			W_init_lock = 1'b0;
			W_next_lock = 1'b0;
			W_init_addr = {SMADDRWIDTH{1'b0}};
			W_next_addr = (I_cur_addr + 1'b1);
			for(i = 0; i <= LOCAL_PREFETCH; i = i + 1)begin
				if((!W_init_lock) && (!I_mask[i]))
				begin
					W_init_lock = 1'b1;
					W_init_addr = i;
				end
				if((!W_next_lock) && (i + I_cur_addr + 1'b1 < SPLITMULT) && (!I_mask[i + I_cur_addr + 1'b1]))
				begin
					W_next_lock = 1'b1;
					W_next_addr = i + I_cur_addr + 1'b1;
				end
			end
		end
		assign O_init_addr	= W_init_addr;
		assign O_next_addr	= W_next_addr;
	end
	// else begin
	// 	reg	[SMADDRWIDTH-1:0]	W_init_addr;
	// 	reg	[SMADDRWIDTH-1:0]	W_next_addr;
	// 	reg W_init_lock;
	// 	reg W_next_lock;
	// 	integer i;
	// 	always @(*)begin
	// 		W_init_lock = 1'b0;
	// 		W_next_lock = 1'b0;
	// 		W_init_addr = (SPLITMULT - 1'b1);
	// 		W_next_addr = (I_cur_addr - 1'b1);
	// 		for(i = (SPLITMULT - 1); i >= 0; i = i - 1)begin
	// 			if((!W_init_lock) && (!I_mask[i]))
	// 			begin
	// 				W_init_lock = 1'b1;
	// 				W_init_addr = i;
	// 			end
	// 			if((!W_next_lock) && (I_cur_addr >= (i + 1)) && (!I_mask[I_cur_addr - 1'b1 - i]))
	// 			begin
	// 				W_next_lock = 1'b1;
	// 				W_next_addr = I_cur_addr - 1'b1 - i;
	// 			end
	// 		end
	// 	end
	// 	assign O_init_addr	= W_init_addr;
	// 	assign O_next_addr	= W_next_addr;
	// end
end


endmodule
