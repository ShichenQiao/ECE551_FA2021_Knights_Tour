module UART_tb();

	logic clk, rst_n;		// 50MHz system clock & asynch active low reset
	logic trmt;				// start transimission when asserted
	logic [7:0]tx_data;		// byte sent from UART_tx
	logic clr_rdy;			// clear rdy when asserted
	logic tx_done;			// asserted when data transimission finished
	logic rdy;				// asserted when data received is ready
	logic [7:0]rx_data;		// byte received at UART_rx
	logic TX;				// bit sent from UART_tx

	UART_tx iDUT_tx(.clk(clk), .rst_n(rst_n), .trmt(trmt), .tx_data(tx_data), .TX(TX), .tx_done(tx_done));
	UART_rx iDUT_rx(.clk(clk), .rst_n(rst_n), .RX(TX), .clr_rdy(clr_rdy), .rdy(rdy), .rx_data(rx_data));

	initial begin
		clk = 0;
		rst_n = 0;
		trmt = 0;
		clr_rdy = 0;
		tx_data = 8'b1010_1010;
		@(posedge clk);
		@(negedge clk);
		rst_n = 1;		// deassert reset
		trmt = 1;		// start transimission
		@(negedge clk) trmt = 0;
		@(posedge rdy);
		if(rx_data !== tx_data) begin
			$display("ERROR: wrong data received when sending 8'b1010_1010");
			$stop();
		end
		
		@(posedge tx_done);		// wait until tx_done is asserted to transmit next byte
		@(negedge clk);
		tx_data = 8'b0101_0101;		// new byte to be transmitted
		trmt = 1;		// start transimission
		@(negedge clk) trmt = 0;
		repeat(10)@(posedge clk);		// wait a few clks after a new transmission starts
		if(tx_done !== 0) begin			// check functionality of tx_done
			$display("ERROR: tx_done was not cleared when new byte is transmissting");
			$stop();
		end
		if(rdy !== 0) begin			// check functionality of rdy
			$display("ERROR: rdy was not cleared when new byte is being received");
			$stop();
		end
		@(posedge rdy);
		if(rx_data !== tx_data) begin
			$display("ERROR: wrong data received when sending 8'b0101_0101");
			$stop();
		end
		
		@(posedge tx_done);
		@(negedge clk);
		tx_data = 8'b0110_1001;		// new byte to be transmitted
		trmt = 1;		// start transimission
		@(negedge clk) trmt = 0;
		@(posedge rdy);
		if(rx_data !== tx_data) begin
			$display("ERROR: wrong data received when sending 8'b0110_1001");
			$stop();
		end
		
		repeat(1000)@(negedge clk);
		clr_rdy = 1;		// knock down rdy with clr_rdy instead of new transmission
		@(negedge clk) clr_rdy = 0;
		@(posedge clk);
		if(rdy !== 1'b0) begin			// check functionality of clr_rdy
			$display("ERROR: clr_rdy failed to knock down rdy");
			$stop();
		end
		
		@(posedge tx_done)		// stop simulation after transmission is done
		$display("YAHOO! test passed");
		$stop();
	end

	always
		#5 clk = ~clk;

endmodule
