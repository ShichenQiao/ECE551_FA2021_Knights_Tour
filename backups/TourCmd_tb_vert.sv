module TourCmd_tb();

	logic clk,rst_n;						// 50MHz clock and asynch active low reset
	logic start_tour;						// from done signal from TourLogic
	logic [7:0] move;						// encoded 1-hot move to perform
	logic [4:0] mv_indx;					// "address" to access next move
	logic [15:0] cmd_UART;					// cmd from UART_wrapper
	logic cmd_rdy_UART;						// cmd_rdy from UART_wrapper
	logic [15:0] cmd;						// multiplexed cmd to cmd_proc
	logic cmd_rdy;							// cmd_rdy signal to cmd_proc
	logic clr_cmd_rdy;						// from cmd_proc (goes to UART_wrapper too)
	logic send_resp;						// lets us know cmd_proc is done with command
	logic [7:0] resp;						// either 0xA5 (done) or 0x5A (in progress)

	TourCmd iDUT(.clk(clk), .rst_n(rst_n), .start_tour(start_tour), .mv_indx(mv_indx), .move(move), .cmd_UART(cmd_UART), .cmd_rdy_UART(cmd_rdy_UART),
				 .cmd(cmd), .cmd_rdy(cmd_rdy), .clr_cmd_rdy(clr_cmd_rdy), .send_resp(send_resp), .resp(resp));

	initial begin
		clk = 0;
		rst_n = 0;
		move = 8'b0000_0010;
		cmd_UART = 16'h0000;
		cmd_rdy_UART = 0;
		start_tour = 0;
		clr_cmd_rdy = 0;
		send_resp = 0;
		@(posedge clk);
		@(negedge clk) rst_n = 1;
		start_tour = 1;							// start the tour as if Tour Logic finished its work
		if(resp !== 8'hA5) begin				// check resp in IDLE
				$display("Error: wrong resp seen in the IDLE state");
				$stop();
		end
		@(negedge clk) start_tour = 0;
		for(int i = 0; i < 24; i++) begin		// go through all 24 "moves"
			repeat(10)@(posedge clk);
			//@(posedge cmd_rdy);				// wait for cmd_rdy from TourCmd
			if(cmd !== 16'b0010_0000_0000_0010) begin 			// move command with fanfare. Move up 2 squares.
				$display("Error: failed to move up by 2 squares");
				$stop();
			end
			@(negedge clk) clr_cmd_rdy = 1;		// knock down cmd_rdy and go to the HOLD1 state
			@(negedge clk) clr_cmd_rdy = 0;
			
			repeat(10)@(negedge clk);
			send_resp = 1;						// assert send_resp serval clks later indicating finished moving
			if(i !== 24 && resp !== 8'h5A) begin				// check resp when it's not the last move cmd
				$display("Error: wrong resp seen before the last cmd formed");
				$stop();
			end
			@(negedge clk) send_resp = 0;
			
			repeat(10)@(posedge clk);
			//@(posedge cmd_rdy); 				//wait for cmd_rdy from TourCmd
			if(cmd !== 16'b0011_1011_1111_0001) begin 			//move command with fanfare. Move to the right 1 squares.
				$display("Error: failed to move right by 1 square");
				$stop();
			end
			
			@(negedge clk) clr_cmd_rdy = 1;		// knock down cmd_rdy and go to the HOLD2 state
			@(negedge clk) clr_cmd_rdy = 0;
			
			repeat(10)@(negedge clk);
			send_resp = 1;						// assert send_resp serval clks later indicating finished moving
												
			if(i === 24 && resp !== 8'hA5) begin				// check resp when the last moving cmd to cmd_proc is formed
				$display("Error: wrong resp seen when the last cmd is formed");
				$stop();
			end
			@(negedge clk) send_resp = 0;
		end
			
		$display("Yahoo! All test passed!");
		$stop();
	end

	always
		#5 clk = ~clk;

endmodule