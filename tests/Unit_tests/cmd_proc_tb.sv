module cmd_proc_tb();
	////////////////////////
	// Testbench signals //
	//////////////////////
	logic clk,rst_n;						// 50MHz clock and asynch active low reset
	// cmd_proc signals
	logic [15:0] cmd;						// command from BLE
	logic cmd_rdy;							// command ready
	logic clr_cmd_rdy;						// mark command as consumed
	logic send_resp;						// command finished, send_response via UART_wrapper/BT
	logic strt_cal;							// initiate calibration of gyro
	logic cal_done;							// calibration of gyro done
	logic signed [11:0] heading;			// heading from gyro
	logic heading_rdy;						// pulses high 1 clk for valid heading reading
	logic lftIR;							// nudge error +
	logic cntrIR;							// center IR reading (have I passed a line)
	logic rghtIR;							// nudge error -
	logic signed [11:0] error;				// error to PID (heading - desired_heading)
	logic [9:0] frwrd;						// forward speed register
	logic moving;							// asserted when moving (allows yaw integration)
	logic tour_go;							// pulse to initiate TourCmd block
	logic fanfare_go;						// kick off the "Charge!" fanfare on piezo
	// RemoteComm signals
	logic [15:0]test_cmd;					// the command being sent from RemoteComm at the testbench level
	logic TX, RX;							// UART lines
	logic send_cmd;							// asserted to send a new command from RemoteComm to UART_wrapper
	logic cmd_sent;							// indicates transmission of command complete
	logic resp_rdy;							// indicates 8-bit response has been received
	logic [7:0]resp;						// 8-bit response from DUT UART_wrapper, should be 8'hA5
	// UART_wrapper signals
	logic tx_done;
	// inert_intf signals
	logic SS_n, SCLK, MOSI, MISO, INT;		// SPI interface signals
	
	///////////////////////
	// Module instances //
	/////////////////////
	cmd_proc #(1) iDUT(.clk(clk), .rst_n(rst_n), .cmd(cmd), .cmd_rdy(cmd_rdy), .clr_cmd_rdy(clr_cmd_rdy), .send_resp(send_resp),
					   .strt_cal(strt_cal), .cal_done(cal_done), .heading(heading), .heading_rdy(heading_rdy), .lftIR(lftIR),
					   .cntrIR(cntrIR), .rghtIR(rghtIR), .error(error), .frwrd(frwrd), .moving(moving), .tour_go(tour_go),
					   .fanfare_go(fanfare_go));
		   
	RemoteComm iComm(.clk(clk), .rst_n(rst_n), .RX(RX), .TX(TX), .cmd(test_cmd), .send_cmd(send_cmd), .cmd_sent(cmd_sent), .resp_rdy(resp_rdy),
					 .resp(resp));
					   
	UART_wrapper iUART(.clk(clk), .rst_n(rst_n), .clr_cmd_rdy(clr_cmd_rdy), .trmt(send_resp), .resp(8'hA5), .RX(TX), .TX(RX),
					   .cmd_rdy(cmd_rdy), .cmd(cmd), .tx_done(tx_done));
					   
	inert_intf #(1) iintf(.clk(clk), .rst_n(rst_n), .strt_cal(strt_cal), .cal_done(cal_done), .heading(heading), .rdy(heading_rdy), .lftIR(lftIR),
						  .rghtIR(rghtIR), .SS_n(SS_n), .SCLK(SCLK), .MOSI(MOSI), .MISO(MISO), .INT(INT), .moving(moving));
						 
	SPI_iNEMO3 inemo(.SS_n(SS_n), .SCLK(SCLK), .MISO(MISO), .MOSI(MOSI), .INT(INT));
	
	///////////////////
	// Actual tests //
	/////////////////
	initial begin
		clk = 0;
		rst_n = 0;
		test_cmd = 16'h0000;					// the calibrate command
		send_cmd = 0;
		lftIR = 0;
		cntrIR = 0;
		rghtIR = 0;
		@(posedge clk);
		@(negedge clk);
		rst_n = 1;								// deassert master reset
		
		// test calibration after master reset
		send_cmd = 1;							// send Calibrate command
		@(negedge clk) send_cmd = 0;
		wait_posedge_sig(cal_done, 500000);		// wait for cal_done or timeout if it does not occur
		wait_posedge_sig(resp_rdy, 50000);		// wait for resp_rdy or timeout if it does not occur
		if(resp !== 8'hA5) begin
			$display("ERROR: wrong response received at RemoteComm");
			$stop();
		end
		
		// test sending command to move "north" 1 square
		@(negedge clk);
		test_cmd = 16'h2001;					// move "north" 1 square
		send_cmd = 1;
		@(negedge clk) send_cmd = 0;
		@(posedge cmd_sent);
		if(frwrd !== 10'h000) begin
			$display("ERROR: frwrd is not 10'h000 when cmd_sent");
			$stop();
		end
		
		repeat(10) @(posedge heading_rdy);
		if(frwrd !== 10'h120) begin
			$display("ERROR: frwrd is not 10'h120 at the 10th posedge heading_rdy");
			$stop();
		end
		
		if(moving !== 1'b1) begin				// robot should be moving at this stage
			$display("ERROR: moving is not asserted at the 10th posedge heading_rdy");
			$stop();
		end
		
		repeat(22) @(posedge heading_rdy);		// robot should be travelling at max_spd
		if(frwrd !== 10'h300) begin
			$display("ERROR: frwrd is not satrated to 10'h200 after 22 more posedge heading_rdy");
			$stop();
		end
		
		@(negedge clk) cntrIR = 1;				// leaving previous square
		repeat(1000) @(negedge clk);				// the duration of the cntrIR pulse is 100 clk, but only 1 cross should be counted
		cntrIR = 0;
		repeat(2) @(posedge heading_rdy);		// robot should still be travelling at max_spd
		if(frwrd !== 10'h300) begin
			$display("ERROR: frwrd is not keeping satrated to 10'h200 when receiving one pulse on cntrIR");
			$stop();
		end
		
		@(negedge clk) cntrIR = 1;				// cntrIR detected the second reflecting type, should ramp down at twice the rate it ramped up
		@(negedge clk) cntrIR = 0;				// this time, test with only one clk of cntrIR pulse, should not happen in reality
		wait_posedge_sig(resp_rdy, 500000);		// wait for resp_rdy indicating moving "north" by 1 square finished
		if((frwrd !== 10'h000) || moving) begin		// should stop moving at this time
			$display("ERROR: frwrd is not 0 or moving is still high when resp_rdy");
			$stop();
		end

		@(negedge clk) send_cmd = 1;			// send another move "north" 1 square
		@(negedge clk) send_cmd = 0;
		repeat(25) @(posedge heading_rdy);
		@(negedge clk) lftIR = 1;				// test functionality of lftIR indecating the robot is going to much to the left
		repeat(1000) @(negedge clk);
		lftIR = 0;
		if((error > $signed(-12'h030)) && (error < $signed(12'h030))) begin			// error should be disturbed
			$display("ERROR: 1000 clocks of lftIR did not affect error significantly");
			$stop();
		end
		@(negedge clk) rghtIR = 1;				// test functionality of rghtIR indecating the robot is going to much to the right
		repeat(1000) @(negedge clk);
		rghtIR = 0;
		if((error > $signed(-12'h030)) && (error < $signed(12'h030))) begin			// error should be disturbed
			$display("ERROR: 1000 clocks of rghtIR did not affect error significantly");
			$stop();
		end

		$display("YAHOO! test passed");
		$stop();
	end
	
	always
		#5 clk = ~clk;

	// task to check timeouts of waiting the posedge of a given status signal
	task automatic wait_posedge_sig(ref sig, input int clks2wait);
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
