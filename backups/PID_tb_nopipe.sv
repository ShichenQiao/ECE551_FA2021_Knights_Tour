module PID_tb();
	logic clk, rst_n;
	logic moving;								// clear I_term if not moving
	logic err_vld;								// compute I & D again when vld
	logic signed [11:0] error;					// signed error into PID
	logic [9:0] frwrd;							// summed with PID to form lft_spd,right_spd
	logic [10:0] lft_spd, rght_spd;				// these form the input to mtr_drv
	logic [10:0] addr;							// loop variable, from 0 to 1999, going through all possible address of the memory
	logic [24:0] stim[0:1999];					// memory holding data in PID_stim.hex
	logic [21:0] resp[0:1999], resp_vec;		// memory holding data in PID_resp.hex and a pointer to a row at addr
	
	PID iDUT(.clk(clk), .rst_n(rst_n), .moving(moving),	.err_vld(err_vld), .error(error), .frwrd(frwrd), .lft_spd(lft_spd), .rght_spd(rght_spd));
	
	initial begin
		clk = 0;
		$readmemh("../lib/PID_stim.hex", stim);		// load data in PID_stim.hex into memory
		$readmemh("../lib/PID_resp.hex", resp);		// load data in PID_resp.hex into memory
		// loop throught all 2000 vectors
		for(addr = 0; addr < 2000; addr = addr + 1) begin
			@(posedge clk) #1;					// check responses 1 time unit after each posedge clk
			if((lft_spd !== resp_vec[21:11]) || (rght_spd !== resp_vec[10:0])) begin			// match responses to corresponding vector
				$display("ERROR: lft_spd and rght_spd does not match the corresponding vector in PID_resp.hex");
				$stop();
			end
		end
		$display("YAHOO! All test passed! Student Name: Justin Qiao");
		$stop();
	end
	
	// ROM presents data on clock low
	always @(negedge clk) begin
		// decompose one stim vector, and apply its stims to the DUT
		rst_n <= stim[addr][24];
		moving <= stim[addr][23];
		err_vld <= stim[addr][22];
		error <= stim[addr][21:10];
		frwrd <= stim[addr][9:0];
		// create pointer to resp[addr]
		resp_vec <= resp[addr];
	end
	
	always
		#5 clk = ~clk;
	
endmodule
