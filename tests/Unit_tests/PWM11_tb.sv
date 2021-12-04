module PWM11_tb();

logic clk, rst_n;			// clock and active low asynch reset
logic [10:0]duty;			// specifies duty cycle (unsigned 11-bit)
logic PWM_sig, PWM_sig_n;	// PWM signal out

PWM11 iDUT(.clk(clk), .rst_n(rst_n), .duty(duty), .PWM_sig(PWM_sig), .PWM_sig_n(PWM_sig_n));

initial begin
	clk = 0;
	rst_n = 0;
	duty = 11'h000;
	@(posedge clk);		// wait one clock cycle
    @(negedge clk) rst_n = 1;	// deassert reset on negative clock edge
	// check 0% duty cycle
	repeat(2048)@(posedge clk);
	
	// check 25% duty cycle
	@(negedge clk) duty = 11'h200;
	repeat(2048)@(posedge clk);
	
	// check 50% duty cycle
	@(negedge clk) duty = 11'h400;
	repeat(2048)@(posedge clk);
	
	// check 75% duty cycle
	@(negedge clk) duty = 11'h600;
	repeat(2048)@(posedge clk);
	
	// check 100% duty cycle
	@(negedge clk) duty = 11'h7FF;
	repeat(2048)@(posedge clk);
	
	$stop();
end

always
	#5 clk = ~clk;

endmodule
