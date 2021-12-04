module KnightsTour_tb();

	//<< import or include tasks?>>


	/////////////////////////////
	// Stimulus of type reg //
	/////////////////////////
	reg clk, RST_n;
	reg [15:0] cmd;
	reg send_cmd;

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
		reset_DUT();
		wait4sig(iPHYS.iNEMO.NEMO_setup, 100000);
		
		// test calibration
		@(posedge clk);
		calibrate_DUT();
		wait4sig(iDUT.cal_done, 1000000);
		wait4sig(resp_rdy, 1000000);
		if(resp !== 8'hA5) begin
			$display("ERROR: did not calibrate as expected. ");
			$stop();
		end
		
		print_cordinates();
		
		// Test: go north by 1 square
		move_DUT(1'b0, 2'b00, 4'h1);
		wait4sig(resp_rdy, 10000000);
		
		print_cordinates();
		
		// Test: go west by 1 square
		move_DUT(1'b0, 2'b01, 4'h1);
		wait4sig(resp_rdy, 10000000);
		
		print_cordinates();
		
		// Test: go south by 1 square
		move_DUT(1'b0, 2'b10, 4'h1);
		wait4sig(resp_rdy, 10000000);
		
		print_cordinates();
		
		// Test: go east by 1 square
		move_DUT(1'b0, 2'b11, 4'h1);
		wait4sig(resp_rdy, 10000000);
		
		print_cordinates();
		
		// Test: start tour from the center
		//send_cmd_to_DUT(16'b0100_0000_0010_0010);
		//wait4sig(resp_rdy, 10000000);
		//wait4sig(resp_rdy, 10000000);
		//wait4sig(resp_rdy, 10000000);
		
		repeat(10) @(posedge clk);
		$display("YAHOO! All test passed! Justin Qiao is unstoppable! ");
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
	
	task reset_DUT();
		@(negedge clk) RST_n = 0;
		@(negedge clk) RST_n = 1;
	endtask
	
	task calibrate_DUT();
		@(negedge clk);
		cmd = 16'h0000;
		send_cmd = 1;
		@(negedge clk) send_cmd = 0;
	endtask
	
	task print_cordinates();
		$display("The Knights is now at (%.2f, %.2f)", iPHYS.xx/4096.0, iPHYS.yy/4096.0);
	endtask
	
	task move_DUT(input logic fanfare,					// 1 to move with fanfare, 0 to move without
				  input logic [1:0] dir, 				// 0 to north, 1 to west, 2 to south, 3 to east
				  input logic [3:0] num_of_square);		// used 4 bits for convinence, the real robot should only move 1 or 2 squares at a time
		@(negedge clk);
		if(fanfare)
			case(dir)
				2'b00:	cmd = {4'b0011, 8'h00, num_of_square};		// north
				2'b01:	cmd = {4'b0011, 8'h3F, num_of_square};		// west
				2'b10:	cmd = {4'b0011, 8'h7F, num_of_square};		// south
				2'b11:	cmd = {4'b0011, 8'hBF, num_of_square};		// east
			endcase
		else
			case(dir)
				2'b00:	cmd = {4'b0011, 8'h00, num_of_square};		// north
				2'b01:	cmd = {4'b0011, 8'h3F, num_of_square};		// west
				2'b10:	cmd = {4'b0011, 8'h7F, num_of_square};		// south
				2'b11:	cmd = {4'b0011, 8'hBF, num_of_square};		// east
			endcase
		send_cmd = 1;
		@(negedge clk) send_cmd = 0;
	endtask
		
endmodule