module SPI_mnrch_tb();

	logic clk, rst_n;			// 50MHz system clock and async reset
	logic [15:0]wt_data;		// data (command) being sent to inertial sensor
	logic wrt;					// high for 1 clock initiate a SPI transaction
	logic [15:0]rd_data;		// Data from SPI serf. For inertial sensor we will only ever use [7:0]
	logic SS_n, SCLK, MOSI, MISO;		// SPI datalines
	logic done;					// asserted when SPI transaction is complete, stay asserted till next wrt
	logic INT;					// interrupt output
	
	SPI_mnrch imnrch(.clk(clk), .rst_n(rst_n), .wt_data(wt_data), .wrt(wrt), .rd_data(rd_data), .SS_n(SS_n), .SCLK(SCLK), .MOSI(MOSI), .MISO(MISO), .done(done));
	SPI_iNEMO1 inemo(.SS_n(SS_n), .SCLK(SCLK), .MISO(MISO), .MOSI(MOSI), .INT(INT));
	
	initial begin
		clk = 0;
		rst_n = 0;
		wrt = 0;
		
		// read from the Who Am I register
		wt_data = 16'h8F00;
		@(posedge clk);
		@(negedge clk);
		rst_n = 1;						// deassert master reset
		wrt = 1;
		@(negedge clk) wrt = 0;
		// check return value from the Who Am I register
		wait4sig(done, 1000);			// wait until posedge done, assert timeout error if not received after 1000 clks
		if(rd_data[7:0] !== 8'h6A) begin
			$display("ERROR: got wrong value from the Who Am I Register");
			$stop();
		end
		
		// configure the INT
		@(negedge clk);
		wt_data = 16'h0D02;				// write to the INT config register
		wrt = 1;
		@(negedge clk) wrt = 0;
		// check inemo.NEMO_setup after configuration
		wait4sig(done, 1000);			// wait until posedge done, assert timeout error if not received after 1000 clks
		@(negedge clk);
		if(inemo.NEMO_setup !== 1'b1) begin
			$display("ERROR: NEMO_setup did not go high after writing to the INT config register");
			$stop();
		end
		
		// read the first yaw data
		@(negedge clk) wt_data = 16'hA600;		// read the yawL value
		wait4sig(INT, 50000);			// wait until posedge INT, assert timeout error if not received after 50000 clks
		wrt = 1;						// send the reading command
		@(negedge clk) wrt = 0;
		// check the received yawL data
		wait4sig(done, 1000);			// wait until posedge done, assert timeout error if not received after 1000 clks
		if(rd_data[7:0] !== 8'h8d) begin
			$display("ERROR: wrong ywaL returned for the first reading");
			$stop();
		end
		if(INT !== 1'b0) begin			// INT should drop after reading yawL
			$display("ERROR: INT did not drop when ywaL is read for the first time");
			$stop();
		end
		// read the yawH value
		@(negedge clk);
		wt_data = 16'hA700;
		wrt = 1;
		@(negedge clk) wrt = 0;
		// check the received yawH data
		wait4sig(done, 1000);			// wait until posedge done, assert timeout error if not received after 1000 clks
		if(rd_data[7:0] !== 8'h99) begin
			$display("ERROR: wrong ywaH returned for the first reading");
			$stop();
		end
		
		// read the second yaw data
		@(negedge clk) wt_data = 16'hA600;		// read the yawL value
		wait4sig(INT, 50000);			// wait until posedge INT, assert timeout error if not received after 50000 clks
		wrt = 1;						// send the reading command
		@(negedge clk) wrt = 0;
		// check the received yawL data
		wait4sig(done, 1000);			// wait until posedge done, assert timeout error if not received after 1000 clks
		if(rd_data[7:0] !== 8'h3d) begin
			$display("ERROR: wrong ywaL returned for the second reading");
			$stop();
		end
		if(INT !== 1'b0) begin			// INT should drop after reading yawL
			$display("ERROR: INT did not drop when ywaL is read for the second time");
			$stop();
		end
		// read the yawH value
		@(negedge clk);
		wt_data = 16'hA700;
		wrt = 1;
		@(negedge clk) wrt = 0;
		// check the received yawH data
		wait4sig(done, 1000);			// wait until posedge done, assert timeout error if not received after 1000 clks
		if(rd_data[7:0] !== 8'hcd) begin
			$display("ERROR: wrong ywaH returned for the second reading");
			$stop();
		end
		
		$display("YAHOO! test passed");
		$stop();
	end
	
	always
		#5 clk = ~clk;
		
	// task to check timeouts of waiting the posedge of a given status signal
	task automatic wait4sig(ref sig, input int clks2wait);
		fork
			begin: timeout
				repeat(clks2wait) @(posedge clk);
				$display("ERROR: timed out waiting for sig in wait4sig");
				$stop();
			end
			begin
				@(posedge sig)
				disable timeout;
			end
		join
	endtask
	
endmodule
