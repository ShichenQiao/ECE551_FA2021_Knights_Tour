module UART_tx_tb();

	logic clk, rst_n;		// 50MHz system clock & asynch active low reset
	logic trmt;				// asserted for 1 clock to initiate transmission
	logic [7:0]tx_data;		// byte to transmit
	logic TX;				// serial data output
	logic tx_done;			// asserted when byte is done transmitting, and stays high till next byte transmitted.

	UART_tx iDUT(.clk(clk), .rst_n(rst_n), .trmt(trmt), .tx_data(tx_data), .TX(TX), .tx_done(tx_done));

	initial begin
		clk = 0;
		rst_n = 0;
		trmt = 0;
		tx_data = 8'b1010_1010;
		
		@(posedge clk);
		@(negedge clk);
		rst_n = 1;			// deassert reset
		trmt = 1;			// test transmitting 8'b1010_1010
		@(negedge clk) trmt = 0;
		@(posedge tx_done);
		
		// test ransmitting 8'b0101_0101
		@(negedge clk);
		tx_data = 8'b0101_0101;
		trmt = 1;
		@(negedge clk) trmt = 0;
		@(posedge tx_done);
		
		// test ransmitting 8'b0110_1001
		@(negedge clk);
		tx_data = 8'b0110_1001;
		trmt = 1;
		@(negedge clk) trmt = 0;
		@(posedge tx_done);
		
		$stop();
		
	end

	always
		#5 clk = ~clk;

endmodule
