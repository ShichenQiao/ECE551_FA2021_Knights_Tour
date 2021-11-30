module inert_intf_tb();
	logic clk, rst_n;
	logic MISO;						// SPI input from inertial sensor
	logic INT;						// goes high when measurement ready
	logic strt_cal;					// initiate claibration of yaw readings
	logic moving;					// Only integrate yaw when going
	logic lftIR,rghtIR;				// gaurdrail sensors

	logic cal_done;					// pulses high for 1 clock when calibration done
	logic signed [11:0] heading;	// heading of robot.  000 = Orig dir 3FF = 90 CCW 7FF = 180 CCW
	logic rdy;						// goes high for 1 clock when new outputs ready (from inertial_integrator)
	logic SS_n,SCLK,MOSI;			// SPI outputs
	
	inert_intf iDUT(.clk(clk), .rst_n(rst_n), .strt_cal(strt_cal), .cal_done(cal_done), .heading(heading), .rdy(rdy), .lftIR(lftIR),
					.rghtIR(rghtIR), .SS_n(SS_n), .SCLK(SCLK), .MOSI(MOSI), .MISO(MISO), .INT(INT), .moving(moving));
	SPI_iNEMO2 inemo(.SS_n(SS_n), .SCLK(SCLK), .MISO(MISO), .MOSI(MOSI), .INT(INT));
					
	initial begin
		// reset the DUT but don’t assert strt_cal yet
		clk = 0;
		rst_n = 0;
		strt_cal = 0;
		moving  = 1;
		lftIR = 0;
		rghtIR = 0;
		@(posedge clk);
		@(negedge clk) rst_n = 1;
		
		// wait for NEMO_setup inside SPI_iNEMO2 to get asserted, timeout after 100000 clk cycles
		fork
			begin: timeout_NEMO_setup
				repeat(100000) @(posedge clk);
				$display("ERROR: timed out waiting for NEMO_setup");
				$stop();
			end
			begin
				@(posedge inemo.NEMO_setup)
				disable timeout_NEMO_setup;
			end
		join
		
		// assert strt_cal for one clock cycle
		@(negedge clk) strt_cal = 1;
		@(negedge clk) strt_cal = 0;
		
		// wait for cal_done to get asserted
		fork
			begin: timeout_cal_done
				repeat(2000000) @(posedge clk);
				$display("ERROR: timed out waiting for cal_done");
				$stop();
			end
			begin
				@(posedge cal_done)
				disable timeout_cal_done;
			end
		join
		
		// let the simulation run for 8 million more clocks and then stop
		repeat(8000000) @(posedge clk);
		$stop();
	end
	
	always
		#5 clk = ~clk;

endmodule
