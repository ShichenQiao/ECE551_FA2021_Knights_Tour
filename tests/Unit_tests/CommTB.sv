module CommTB();
	logic clk, rst_n;				// clock and active low reset
	logic [15:0] cmd;				// cmd going to be sent from RemoteComm
	logic [15:0] cmd_received;		// cmd received and wrapped by UART_warpper
	logic send_cmd;					// indicates to tranmit 16-bit command (cmd)
	logic clr_cmd_rdy;				// knock down cmd_rdy when asserted
	logic cmd_sent;					// asserted after both byte sent from RemoteComm
	logic cmd_rdy;					// asserted by UART_warpper when cmd is received and wrapped
	logic TX, RX;					// UART data lines between RemoteComm and UART_warpper

	// these signals are hooked to the DUTs but not used in the test bench becase tests on the response part is not required
	logic trmt;						// start UART ransmission when asserted (input to UART_warpper)
	logic [7:0] resp;				// response byte to be sent from UART (input to UART_warpper)
	logic tx_done;					// asserted when UART transmission finished (output from UART_warpper)
	logic [7:0] resp_received;		// 8-bit response from DUT (output from RemoteComm)
	logic resp_rdy;					// indicates 8-bit response has been received (output from RemoteComm)
	
	// instantiate UART_warpper and RemoteComm
	UART_warpper iUART_Warpper(.clk(clk), .rst_n(rst_n), .RX(TX), .TX(RX), .cmd(cmd_received), .cmd_rdy(cmd_rdy), .clr_cmd_rdy(clr_cmd_rdy), .trmt(trmt), .resp(resp), .tx_done(tx_done));
	RemoteComm iRemoteComm(.clk(clk), .rst_n(rst_n), .RX(RX), .TX(TX), .cmd(cmd), .send_cmd(send_cmd), .cmd_sent(cmd_sent), .resp_rdy(resp_rdy), .resp(resp_received));
	
	initial begin
		clk = 0;
		rst_n = 0;
		cmd = 16'hF00F;
		send_cmd = 0;
		clr_cmd_rdy = 0;
		trmt = 0;			// not used
		resp = 8'h00;		// not used
		@(posedge clk);
		@(negedge clk);
		rst_n = 1;			// deassert reset
		
		// test sending cmd 16'hF00F
		send_cmd = 1;
		@(negedge clk) send_cmd = 0;
		wait4sig(cmd_rdy, 60000);				// wait until posedge cmd_rdy, should happen about 20 baud periods later, assert timeout error if not received after 60000 clks
		if(cmd_received !== cmd) begin			// check if cmd received is the same as it was sent
			$display("ERROR: cmd received by UART_warpper is different cmd sent from RemoteComm");
			$stop();
		end
		
		// test functionality of clr_cmd_rdy
		@(negedge clk) clr_cmd_rdy = 1;
		@(negedge clk) clr_cmd_rdy = 0;
		repeat(2) @(posedge clk);
		if(cmd_rdy) begin
			$display("ERROR: clr_cmd_rdy failed to knock down cmd_rdy");
			$stop();
		end
		
		// test sending another cmd after cmd_sent is asserted for the previous cmd
		wait4sig(cmd_sent, 2000);				// wait until posedge cmd_sent, should happen about 0.5 baud periods later, assert timeout error if not received after 2000 clks
		@(negedge clk);
		cmd = 16'b0101_1001_0110_1010;
		send_cmd = 1;
		@(negedge clk) send_cmd = 0;
		wait4sig(cmd_rdy, 60000);				// wait until posedge cmd_rdy, should happen about 20 baud periods later, assert timeout error if not received after 60000 clks
		if(cmd_received !== cmd) begin			// check if cmd received is the same as it was sent
			$display("ERROR: cmd received by UART_warpper is different cmd sent from RemoteComm");
			$stop();
		end
		
		// test sending another cmd without using clr_cmd_rdy to knock down cmd_rdy asserted for the previous cmd_rdy
		wait4sig(cmd_sent, 2000);				// wait until posedge cmd_sent, should happen about 0.5 baud periods later, assert timeout error if not received after 2000 clks
		@(negedge clk);
		cmd = 16'b1010_1111_0101_0000;
		send_cmd = 1;
		@(negedge clk) send_cmd = 0;
		wait4sig(cmd_rdy, 60000);				// wait until posedge cmd_rdy, should happen about 20 baud periods later, assert timeout error if not received after 60000 clks
		if(cmd_received !== cmd) begin			// check if cmd received is the same as it was sent
			$display("ERROR: cmd received by UART_warpper is different cmd sent from RemoteComm");
			$stop();
		end
		
		@(posedge cmd_sent);		// stop simulation and print happy message after last cmd sent
		$display("YAHOO! test passed");
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
	
endmodule
