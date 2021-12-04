module MtrDrv_tb();

logic clk, rst_n;					// clock and active low asynch reset
logic signed [10:0]lft_spd;			// signed left motor speed
logic signed [10:0]rght_spd;		// signed right motor speed
logic lftPWM1, lftPWM2;				// to power MOSFETs that drive lft motor
logic rghtPWM1, rghtPWM2;			// to power MOSFETs that drive right motor

MtrDrv iDUT(.clk(clk), .rst_n(rst_n), .lft_spd(lft_spd), .rght_spd(rght_spd), 
			.lftPWM1(lftPWM1), .lftPWM2(lftPWM2), .rghtPWM1(rghtPWM1), .rghtPWM2(rghtPWM2));

initial begin
	clk = 0;
	rst_n = 0;
	lft_spd = 11'h000;
	rght_spd = 11'h000;
	@(posedge clk);		// wait one clock cycle
    @(negedge clk) rst_n = 1;	// deassert reset on negative clock edge
	// check both motor stops
	repeat(2048)@(posedge clk);
	
	// check left motor going backward, right moter stops
	@(negedge clk) lft_spd = 11'h400;
	repeat(2048)@(posedge clk);
	
	// check left motor going backward, right moter going forward
	@(negedge clk) rght_spd = 11'h3FF;
	repeat(2048)@(posedge clk);
	
	// check both motor going forward, left moter faster
	@(negedge clk) lft_spd = 11'h200;
	rght_spd = 11'h100;
	repeat(2048)@(posedge clk);
	
	// check both motor going backward, right moter faster
	@(negedge clk) lft_spd = 11'h600;
	rght_spd = 11'h500;
	repeat(2048)@(posedge clk);
	
	$stop();
end

always
	#5 clk = ~clk;

endmodule
