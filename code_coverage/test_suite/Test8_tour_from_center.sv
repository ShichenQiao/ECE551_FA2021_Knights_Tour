module Test8_tour_from_center();

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
		
		// should be 2.50, 2.50
		print_cordinates(iPHYS.xx, iPHYS.yy);
		
		// Test: start tour from the center of the board
		start_tour_DUT(3'd2, 3'd2, clk, cmd, send_cmd);
		
		// go through all 48 moves, i.e. 24 L moves
		for(int i = 0; i < 48; i++) begin
			wait4sig(resp_rdy, 10000000, clk);
			print_cordinates(iPHYS.xx, iPHYS.yy);		// print the coordinates of the robot after each move
		end
		
		repeat(10) @(posedge clk);
		$display("YAHOO! All test passed! Justin Qiao is unstoppable! ");
		$stop();

	end

	always
	#5 clk = ~clk;
		
endmodule