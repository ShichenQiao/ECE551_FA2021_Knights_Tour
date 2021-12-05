module KnightsTour_tb();

	// import tb_tasks package
	import tb_tasks::*;

	/////////////////////////////
	// Stimulus of type reg //
	/////////////////////////
	reg clk, RST_n;
	logic [15:0] cmd;
	logic send_cmd;

	///////////////////////////////////
	// Declare any internal signals //
	/////////////////////////////////
	wire SS_n,SCLK,MOSI,MISO,INT;
	wire lftPWM1,lftPWM2,rghtPWM1,rghtPWM2;
	wire TX_RX, RX_TX;
	logic cmd_sent;
	logic resp_rdy;
	logic [7:0] resp;
	wire IR_en;
	wire lftIR_n,rghtIR_n,cntrIR_n;

	//////////////////////
	// Instantiate DUT //
	////////////////////
	KnightsTour iDUT(.clk(clk), .RST_n(RST_n), .SS_n(SS_n), .SCLK(SCLK),
				   .MOSI(MOSI), .MISO(MISO), .INT(INT), .lftPWM1(lftPWM1),
				   .lftPWM2(lftPWM2), .rghtPWM1(rghtPWM1), .rghtPWM2(rghtPWM2),
				   .RX(TX_RX), .TX(RX_TX), .piezo(piezo), .piezo_n(piezo_n),
				   .IR_en(IR_en), .lftIR_n(lftIR_n), .rghtIR_n(rghtIR_n),
				   .cntrIR_n(cntrIR_n));
				  
	/////////////////////////////////////////////////////
	// Instantiate RemoteComm to send commands to DUT //
	///////////////////////////////////////////////////
	RemoteComm iRMT(.clk(clk), .rst_n(RST_n), .RX(RX_TX), .TX(TX_RX), .cmd(cmd),
			 .send_cmd(send_cmd), .cmd_sent(cmd_sent), .resp_rdy(resp_rdy), .resp(resp));
				   
	//////////////////////////////////////////////////////
	// Instantiate model of Knight Physics (and board) //
	////////////////////////////////////////////////////
	KnightPhysics iPHYS(.clk(clk),.RST_n(RST_n),.SS_n(SS_n),.SCLK(SCLK),.MISO(MISO),
					  .MOSI(MOSI),.INT(INT),.lftPWM1(lftPWM1),.lftPWM2(lftPWM2),
					  .rghtPWM1(rghtPWM1),.rghtPWM2(rghtPWM2),.IR_en(IR_en),
					  .lftIR_n(lftIR_n),.rghtIR_n(rghtIR_n),.cntrIR_n(cntrIR_n)); 
				   
	initial begin
		clk = 0;
		
		// test reset
		@(posedge clk);
		reset_DUT(clk, RST_n);
		wait4sig(iPHYS.iNEMO.NEMO_setup, 100000, clk);
		
		// test calibration
		@(posedge clk);
		calibrate_DUT(clk, cmd, send_cmd);
		wait4sig(iDUT.cal_done, 1000000, clk);
		wait4sig(resp_rdy, 1000000, clk);
		if(resp !== 8'hA5) begin
			$display("ERROR: did not calibrate as expected. ");
			$stop();
		end
		
		print_cordinates(iPHYS.xx, iPHYS.yy);
		
		// Test: go south by 2 square with fanfare
		move_DUT(1'b1, 2'b10, 4'h2, clk, cmd, send_cmd);
		// the first three posedge iDUT.cntrIR should not have fanfare
		for(int i = 0; i < 3; i++) begin
			wait4sig(iDUT.cntrIR, 10000000, clk);
			if(piezo | piezo_n) begin
				$display("ERROR: fanfare played before arrived at the destination. ");
				$stop();
			end
		end
		// the fourth one should have fanfare
		wait4sig(resp_rdy, 10000000, clk);
		if(!(piezo | piezo_n)) begin
			$display("ERROR: fanfare was not played when arrived at the destination. ");
			$stop();
		end
		
		print_cordinates(iPHYS.xx, iPHYS.yy);
		
		// Test: go east by 1 square without fanfare
		move_DUT(1'b0, 2'b11, 4'h1, clk, cmd, send_cmd);
		wait4sig(resp_rdy, 10000000, clk);
		
		// fanfare should have stopped before here
		if(piezo | piezo_n) begin
			$display("ERROR: fanfare played before arrived at the destination. ");
			$stop();
		end
		
		print_cordinates(iPHYS.xx, iPHYS.yy);
		
		repeat(10) @(posedge clk);
		$display("YAHOO! All test passed! Justin Qiao is unstoppable! ");
		$stop();

	end

	always
	#5 clk = ~clk;
		
endmodule