module SPI_mnrch(
	input clk, rst_n,			// 50MHz system clock and async reset
	output logic SS_n,			// SPI SS_n line
	output SCLK,				// SPI SCLK line
	output MOSI,				// SPI MOSI line
	input MISO,					// SPI MISO line
	input wrt,					// high for 1 clock initiate a SPI transaction
	input [15:0]wt_data,		// data (command) being sent to inertial sensor
	output logic done,			// asserted when SPI transaction is complete, stay asserted till next wrt
	output [15:0]rd_data		// Data from SPI serf. For inertial sensor we will only ever use [7:0]
);
	typedef enum logic [1:0] {IDLE, BEGIN, WORK, END} state_t;
	state_t state, nxt_state;
	
	logic ld_SCLK;				// SM output to load SCLK_div by 5'b10111, making SCLK high
	logic init;					// SM output to init a SPI transaction
	logic shft;					// SM output to shift the shift register by 1 bit
	logic smpl;					// SM output to sample the MISO line
	logic [4:0]SCLK_div;		// clock divider
	logic [3:0]bit_cntr;		// bit counter
	logic done15;				// asserted when bit_cntr reaches 4'b1111 indicating shifted 15 times
	logic MISO_smpl;			// MISO sample collected when smpl is high
	logic [15:0]shft_reg;		// main 16-bit shift register
	logic set_done;				// SM output to set done and SS_n
	
	// clock divider
	always_ff @(posedge clk)
		if(ld_SCLK)
			SCLK_div <= 5'b10111;			// front porch
		else
			SCLK_div <= SCLK_div + 1;
	assign SCLK = SCLK_div[4];
	
	// bit counter
	always_ff @(posedge clk)
		if(init)
			bit_cntr <= 4'b0000;
		else if(shft)
			bit_cntr <= bit_cntr + 1;
	assign done15 = &bit_cntr;
	
	// sample MISO when smpl is asserted
	always_ff @(posedge clk)
		if(smpl)
			MISO_smpl <= MISO;
	
	// main 16-bits shift register
	always_ff @(posedge clk)
		if(init)
			shft_reg <= wt_data;
		else if(shft)
			shft_reg <= {shft_reg[14:0], MISO_smpl};
	assign MOSI = shft_reg[15];
	assign rd_data = shft_reg;
	
	// state register of the SM
	always_ff @(posedge clk, negedge rst_n)
		if(!rst_n)
			state <= IDLE;
		else
			state <= nxt_state;
	
	// state machine
	always_comb begin
		// default all SM outputs to prevent unintended latches
		smpl = 1'b0;
		shft = 1'b0;
		ld_SCLK = 1'b0;
		init = 1'b0;
		set_done = 1'b0;
		nxt_state = state;
		
		case(state)
			BEGIN:
				if(SCLK_div == 5'b11111)			// not shifting at first SCLK fall
					nxt_state = WORK;
			WORK:
				if(done15)							// go to END state after shift 15 times
					nxt_state = END;
				else if(SCLK_div == 5'b01111)		// sample on SCLK rise
					smpl = 1'b1;
				else if(SCLK_div == 5'b11111)		// shift on SCLK fall
					shft = 1'b1;
			END:
				if(SCLK_div == 5'b01111)			// sample on last SCLK rise
					smpl = 1'b1;
				else if(SCLK_div == 5'b11111) begin
					shft = 1'b1;					// shift last bit
					ld_SCLK = 1'b1;					// prevent last SCLK fall
					set_done = 1'b1;				// set down after last bit shifted
					nxt_state = IDLE;
				end
			default: begin		// is IDLE
				if(wrt) begin
					init = 1'b1;
					nxt_state = BEGIN;
				end
				else
					ld_SCLK = 1'b1;					// keep SCLK high when SPI transaction not happening
			end
		endcase
	end
		
	// SR flop making sure SS_n is straight from a FF
		always_ff @(posedge clk, negedge rst_n)
		if(!rst_n)
			SS_n <= 1'b1;		// preset SS_n
		else if(init)
			SS_n <= 1'b0;
		else if(set_done)
			SS_n <= 1'b1;
	
	// SR flop generating done, init is S, set_done is R
	always_ff @(posedge clk, negedge rst_n)
		if(!rst_n)
			done <= 1'b0;
		else if(init)
			done <= 1'b0;
		else if(set_done)
			done <= 1'b1;

endmodule
