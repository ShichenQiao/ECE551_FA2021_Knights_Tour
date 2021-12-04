module charge_modelsim_tb();
	logic clk, rst_n;					// 50MHz sys clk and master rst_n
	logic go;							// initiates “tune”
	logic piezo, piezo_n;				// differential piezo drive

	charge #(1) i_charge(.clk(clk), .rst_n(rst_n), .go(go), .piezo(piezo), .piezo_n(piezo_n));
	
	initial begin
		clk = 0;
		rst_n = 0;
		go = 0;
		@(posedge clk);
		@(negedge clk) rst_n = 1;
		go = 1;
		@(negedge clk) go = 0;
		repeat(4000000) @(posedge clk);
		
		@(negedge clk) go = 1;
		@(negedge clk) go = 0;
		repeat(100000) @(posedge clk);
		
		$stop();
	end
	
	always
		#5 clk = ~clk;
	
endmodule
