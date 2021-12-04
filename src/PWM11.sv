module PWM11(
	input clk, rst_n,					// clock and active low asynch reset
	input [10:0]duty,					// specifies duty cycle (unsigned 11-bit)
	output logic PWM_sig, PWM_sig_n		// PWM signal out
);

	logic [10:0]cnt;			// output from counter FF
	logic PWM_high;			// input to PWM FF

	// 11-bit unsigned counter FF, count from 0 to 2047 with roll overs
	always_ff @(posedge clk, negedge rst_n)
		if(!rst_n)
			cnt <= 11'h000;
		else
			cnt <= cnt + 1;
			
	// next PWM should be high when cnt < duty, otherwise low
	assign PWM_high = (cnt < duty);

	// PWM FF
	always_ff @(posedge clk, negedge rst_n)
		if(!rst_n)
			PWM_sig <= 0;
		else if(PWM_high)
			PWM_sig <= 1;
		else
			PWM_sig <= 0;
			
	// generate PWM_sig_n from PWM_sig
	not iNOT(PWM_sig_n, PWM_sig);

endmodule
