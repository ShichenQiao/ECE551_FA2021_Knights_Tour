// usage: import tb_tasks::*;
package tb_tasks;
	
	// task to check timeouts of waiting the posedge of a given status signal
	// usage: wait4sig(<sig>, <clks2wait>, clk);
	task automatic wait4sig(ref sig, input int clks2wait, ref clk);
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

	// usage: reset_DUT(clk, RST_n);
	task automatic reset_DUT(ref clk, RST_n);
		@(negedge clk) RST_n = 0;
		@(negedge clk) RST_n = 1;
	endtask

	// usage: calibrate_DUT(clk, cmd, send_cmd);
	task automatic calibrate_DUT(ref clk, ref [15:0] cmd, ref send_cmd);
		@(negedge clk);
		cmd = 16'h0000;
		send_cmd = 1;
		@(negedge clk) send_cmd = 0;
	endtask
	
	// usage: start_tour_DUT(<3'b<x>>, <3'b<y>>, clk, cmd, send_cmd);
	task automatic start_tour_DUT(input logic [2:0] x, y, ref clk, ref [15:0] cmd, ref send_cmd);
		@(negedge clk);
		cmd = {4'b0100, 5'b00000, x, 1'b0, y};
		send_cmd = 1;
		@(negedge clk) send_cmd = 0;
	endtask

	// usage: print_cordinates(iPHYS.xx, iPHYS.yy);
	task automatic print_cordinates(ref [14:0] xx, yy);
		$display("The Knights is now at (%.2f, %.2f)", xx/4096.0, yy/4096.0);
	endtask

	// usage: move_DUT(<1'b<fanfare>>, <2'b<dir>>, <4'h<num_of_square>>, clk, cmd, send_cmd);
	task automatic move_DUT(input logic fanfare,		// 1 to move with fanfare, 0 to move without
				  input logic [1:0] dir, 				// 0 to north, 1 to west, 2 to south, 3 to east
				  input logic [3:0] num_of_square,		// used 4 bits for convinence, the real robot should only move 1 or 2 squares at a time
				  ref clk, ref [15:0]cmd, ref send_cmd);		
		@(negedge clk);
		case(dir)
			2'b00:	cmd = {3'b001, fanfare, 8'h00, num_of_square};		// north
			2'b01:	cmd = {3'b001, fanfare, 8'h3F, num_of_square};		// west
			2'b10:	cmd = {3'b001, fanfare, 8'h7F, num_of_square};		// south
			2'b11:	cmd = {3'b001, fanfare, 8'hBF, num_of_square};		// east
		endcase
		send_cmd = 1;
		@(negedge clk) send_cmd = 0;
	endtask
endpackage