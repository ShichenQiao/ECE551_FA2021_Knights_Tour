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

		// should be 2.50, 2.50
		print_cordinates(iPHYS.xx, iPHYS.yy);
		
		// go through all 12 invalid opcodes that can be passed to the DUT, cmd_proc should stay in IDLE not moving/calibrating the robot at all
		for(logic [4:0] op = 5'b00001; op < 5'b10000; op = op + 5'b00001) begin
			if(op !== 5'b0010 && op !== 5'b0011 && op !== 5'b0100) begin
				// send garbage cmd with invalid opcodes
				@(negedge clk);
				cmd = {op[3:0], 12'hFFF};
				send_cmd = 1;
				@(negedge clk) send_cmd = 0;
				
				// wait untile cmd_proc received the garbage cmd
				wait4sig(iDUT.iCMD.clr_cmd_rdy, 10000000, clk);
				
				// check cmd_proc outputs, it should not launch calibration, nor make the robot moving
				for(int i = 0; i < 10; i++) begin
					@(posedge clk);
					if(iDUT.iCMD.moving | iDUT.iCMD.tour_go) begin
						$display("Error: cmd_proc should stay in IDLE if invalid opcode is received. ");
						$stop();
					end
				end
				
				print_cordinates(iPHYS.xx, iPHYS.yy);		// should stay as (2.50, 2.50)
				
				reset_DUT(clk, RST_n);						// reset DUT for next opcode
			end
		end
		
		repeat(10) @(posedge clk);
		$display("YAHOO! All test passed! Justin Qiao is unstoppable! ");
		$stop();

	end

	always
	#5 clk = ~clk;
		
endmodule