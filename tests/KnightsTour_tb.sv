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
		send_cmd_to_DUT(16'h0000);
		wait4sig(iDUT.cal_done, 1000000);
		wait4sig(resp_rdy, 1000000);
		if(resp !== 8'hA5) begin
			$display("ERROR: did not calibrate as expected. ");
			$stop();
		end
		
		// Test: go north by 1 square
		//send_cmd_to_DUT({4'b0010, 8'h00, 4'h1});
		//wait4sig(resp_rdy, 10000000);
		
		// Test: go west by 1 square
		//send_cmd_to_DUT({4'b0010, 8'h3F, 4'h1});
		//wait4sig(resp_rdy, 10000000);
		
		// Test: go south by 1 square
		//send_cmd_to_DUT({4'b0010, 8'h7F, 4'h1});
		//wait4sig(resp_rdy, 10000000);
		
		// Test: go east by 1 square
		//send_cmd_to_DUT({4'b0010, 8'hBF, 4'h1});
		//wait4sig(resp_rdy, 10000000);
		
		// Test: go north by 2 square
		//repeat(150000)@(posedge clk);
		//send_cmd_to_DUT({4'b0010, 8'h00, 4'h2});
		//wait4sig(resp_rdy, 10000000);
		
		// Test: start tour from the center
		send_cmd_to_DUT(16'b0100_0000_0010_0010);
		wait4sig(resp_rdy, 10000000);
		wait4sig(resp_rdy, 10000000);
		
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
	
	task send_cmd_to_DUT(input logic [15:0] cmd_to_send);
		@(negedge clk) cmd = cmd_to_send;
		@(negedge clk) send_cmd = 1;
		@(negedge clk) send_cmd = 0;
	endtask
		
endmodule