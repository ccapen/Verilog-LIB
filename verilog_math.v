function integer int_ceil_div(
	input	integer dividend,
	input	integer divisor
);

begin
	int_ceil_div = (dividend + divisor - 1) / divisor;
end

endfunction


