module reset_synch(
	input RST_n,			// raw input from push button
	input clk,				// clock, and we use negative edge
	output logic rst_n			// synchronized output which will form the global reset to the rest of our chip
);
	
	logic ff1;				// intermediate signal between the two flops
	
	// asynch reset when RST_n asserted, other wise, double flop 1'b1 to deassert rst_n on negedge clk
	always_ff @(negedge clk, negedge RST_n)
		if(!RST_n) begin
			ff1 <= 1'b0;
			rst_n <= 1'b0;
		end
		else begin
			ff1 <= 1'b1;
			rst_n <= ff1;
		end

endmodule