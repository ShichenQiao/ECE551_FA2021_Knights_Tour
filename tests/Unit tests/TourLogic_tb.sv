module TourLogic_tb();
	logic clk, rst_n;							// 50MHz clock and active low asynch reset
	logic [2:0] x_start, y_start;				// starting position on 5x5 board
	logic go;									// initiate calculation of solution
	logic [4:0] indx;							// used to specify index of move to read out
	logic done;									// pulses high for 1 clock when solution complete
	logic [7:0] move;							// the move addressed by indx (1 of 24 moves)
	
	TourLogic iDUT(.clk(clk), .rst_n(rst_n), .x_start(x_start), .y_start(y_start), .go(go), .done(done), .indx(indx), .move(move));
	
	initial begin
		clk = 0;
		rst_n = 0;
		x_start = 2;
		y_start = 2;
		go = 0;
		indx = 0;
		@(posedge clk);
		@(negedge clk) rst_n = 1;
		go = 1;

		// test 1: starting from center cell
		@(negedge clk) go = 0;
		wait_posedge_done(done, 1000000);

		// test 2: starting from top left cell
		@(negedge clk) go = 0;
		x_start = 0;
		y_start = 0;
		indx = 4;
		@ (negedge clk) go = 1;
		wait_posedge_done(done, 1000000);

		// test 3: starting from top right cell
		@(negedge clk) go = 0;
		x_start = 4;
		y_start = 0;
		indx = 23;
		@ (negedge clk) go = 1;
		wait_posedge_done(done, 1000000);

		// test 4: starting from bottom left cell
		@(negedge clk) go = 0;
		x_start = 0;
		y_start = 4;
		indx = 15;
		@ (negedge clk) go = 1;
		wait_posedge_done(done, 1000000);

		// test 5: starting from bottom right cell
		@(negedge clk) go = 0;
		x_start = 4;
		y_start = 4;
		indx = 20;
		@ (negedge clk) go = 1;
		wait_posedge_done(done, 1000000);
				
		$display("YAHOO! test passed");
		$stop();
	end
	
	always
		#5 clk = ~clk;
	
	// print the whole board solution every time
	always @(negedge iDUT.update_position && iDUT.move_num == 5'd23) begin
		integer y;
		for(y = 4; y >= 0; y--) begin
			$display("%2d  %2d  %2d  %2d  %2d\n", iDUT.visited[y][0], iDUT.visited[y][1], iDUT.visited[y][2], iDUT.visited[y][3], iDUT.visited[y][4]);
		end
		$display("---------------------------------\n");
	end
	
	// task to check timeouts of waiting the posedge of a given status signal
	task automatic wait_posedge_done(ref done, input int clks2wait);
		fork
			begin: timeout
				repeat(clks2wait) @(posedge clk);
				$display("ERROR: timed out waiting for done");
				$stop();
			end
			begin
				@(posedge done)
				disable timeout;
			end
		join
	endtask
	
endmodule
