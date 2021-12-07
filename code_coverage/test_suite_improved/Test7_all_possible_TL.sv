module Test7_all_possible_TL();

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
	
	/////////////////////////////////////////
	// loop variable to help with testing //
	///////////////////////////////////////
	int y;

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
		
		/* TEST 13 STARTING POINTS */
		
		// 0, 2, 4 rows & cols
		for (int i = 0; i <= 4; i = i + 2)
			for (int j = 0; j <= 4; j = j + 2) begin
				@(posedge clk);
				reset_DUT(clk, RST_n);								// reset DUT
				start_tour_DUT(i, j, clk, cmd, send_cmd);			// start tour in a black square
				wait4sig(iDUT.start_tour, 100000000, clk);			// wait for TourLogic finish calculations
				// print resulting board from TourLogic
				for(y = 4; y >= 0; y--) begin
					$display("%2d  %2d  %2d  %2d  %2d\n", iDUT.iTL.visited[y][0], iDUT.iTL.visited[y][1], iDUT.iTL.visited[y][2], iDUT.iTL.visited[y][3], iDUT.iTL.visited[y][4]);
				end
				$display("---------------------------------\n");
				// make sure the solution travels through all 25 squares
				if(iDUT.iTL.visited[y][0] && iDUT.iTL.visited[y][1] && iDUT.iTL.visited[y][2] &&iDUT.iTL.visited[y][3] && iDUT.iTL.visited[y][4]) begin
					$display("Error: tour calculated by TourLogic is problematic when starting from (%d, %d)", i, j);
					$stop();
				end
				// make sure the calculated tour has 24 moves in total
				if(iDUT.iTL.move_num !== 5'd24) begin
					$display("Error: tour calculated by TourLogic should take 24 L moves");
					$stop();
				end
			end
		
		// 1, 3 rows & cols
		for (int i = 1; i <= 4; i = i + 2)
			for (int j = 1; j <= 4; j = j + 2) begin
				@(posedge clk);
				reset_DUT(clk, RST_n);								// reset DUT
				start_tour_DUT(i, j, clk, cmd, send_cmd);			// start tour in a black square
				wait4sig(iDUT.start_tour, 100000000, clk);			// wait for TourLogic finish calculations
				// print resulting board from TourLogic
				for(y = 4; y >= 0; y--)
					$display("%2d  %2d  %2d  %2d  %2d\n", iDUT.iTL.visited[y][0], iDUT.iTL.visited[y][1], iDUT.iTL.visited[y][2], iDUT.iTL.visited[y][3], iDUT.iTL.visited[y][4]);
				$display("---------------------------------\n");
				// make sure the solution travels through all 25 squares
				if(iDUT.iTL.visited[y][0] && iDUT.iTL.visited[y][1] && iDUT.iTL.visited[y][2] &&iDUT.iTL.visited[y][3] && iDUT.iTL.visited[y][4]) begin
					$display("Error: tour calculated by TourLogic is problematic when starting from (%d, %d)", i, j);
					$stop();
				end
				// make sure the calculated tour has 24 moves in total
				if(iDUT.iTL.move_num !== 5'd24) begin
					$display("Error: tour calculated by TourLogic should take 24 L moves");
					$stop();
				end
			end
		
		repeat(10) @(posedge clk);
		$display("YAHOO! All test passed! Justin Qiao is unstoppable! ");
		$stop();

	end

	always
	#5 clk = ~clk;
		
endmodule