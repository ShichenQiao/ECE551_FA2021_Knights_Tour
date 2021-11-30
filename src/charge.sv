module charge
	#(parameter FAST_SIM = 1) (				// when asserted, duration is 1/16 as when it's not asserted
	input clk, rst_n,						// 50MHz sys clk and master rst_n
	input go,								// initiates “tune”
	output logic piezo, piezo_n				// differential piezo drive
);
	localparam G6 = 15'd31888;				// 50M / 1568 = 31887.8
	localparam C7 = 15'd23889;				// 50M / 2093 = 23889.2
	localparam E7 = 15'd18961;				// 50M / 2637 = 18960.9
	localparam G7 = 15'd15944;				// 50M / 3136 = 15943.9
	localparam dura_1 = 24'h7FFFFF;			// 2^23 - 1
	localparam dura_2 = 24'hBFFFFF;			// 2^23 + 2^22 - 1
	localparam dura_3 = 24'h3FFFFF;			// 2^22 - 1
	localparam dura_4 = 24'hFFFFFF;			// 2^24 - 1
	
	logic [23:0] dura, nxt_dura;			// the duration counter, and the value being loaded into it
	logic [14:0] num_clk, nxt_num_clk;		// the number of clk corresponding to a frequency
	logic nxt_note;							// asserted when it's time to process the next note
	logic S_piezo, R_piezo;					// S and R input to the piezo SR flop
	logic num_clk_load;						// asserted when it's time to repeat a note

	typedef enum logic [2:0] {IDLE, NOTE1, NOTE2, NOTE3, NOTE4, NOTE5, NOTE6} state_t;
	state_t state, nxt_state;

	// duration down counter
	generate
		if(FAST_SIM)						// in case of fast sim, decrement by 16 each time instead of by 1
			always_ff @(posedge clk)
				if(!rst_n)
					dura <= 24'h000000;
				else if(nxt_note)			// load the duration for the next node when nxt_note asserted
					dura <= nxt_dura;
				else if(dura < 16)
					dura <= 24'h000000;		// saturate to 0
				else
					dura <= dura - 16;		// if not being reset or loaded, just count down
		else
			always_ff @(posedge clk, negedge rst_n)
				if(!rst_n)
					dura <= 24'h000000;
				else if(nxt_note)			// load the duration for the next node when nxt_note asserted
					dura <= nxt_dura;
				else
					dura <= dura - 1;		// if not being reset or loaded, just count down
	endgenerate
			
	// "frequency" down counter, count the number of clk corresponding to the current note's frequency
	always_ff @(posedge clk, negedge rst_n)
		if(!rst_n)
			num_clk <= 15'h0000;
		else if(num_clk_load)
			num_clk <= nxt_num_clk;			// load the number of clk corresponding to the current note when num_clk_load asserted
		else
			num_clk <= num_clk - 1;			// if not being reset or loaded, just count down
	
	// state register
	always_ff @(posedge clk, negedge rst_n)
		if(!rst_n)
			state <= IDLE;
		else
			state <= nxt_state;
	
	// control SM
	always_comb begin
		// default all outputs to prevent unintended latches
		nxt_dura = 24'h000000;
		nxt_num_clk = 15'h0000;
		num_clk_load = 1'b0;
		nxt_note = 1'b0;
		S_piezo = 1'b0;
		R_piezo = 1'b0;
		nxt_state = state;
		
		case(state)
			NOTE1: begin
				// repeat playing G6 untile the duration counter reach 0
				if(~|num_clk) begin			// reload num clk if needed
					nxt_num_clk = G6;
					num_clk_load = 1'b1;
					S_piezo = 1'b1;
				end
				else if(num_clk == (G6 >> 1))
					R_piezo = 1'b1;			// 50% duty cycle
				// 
				if(~|dura) begin			// setup counters and go to next note after the duration counter expires, cutoff any note being played
					nxt_dura = dura_1;
					nxt_note = 1'b1;
					nxt_num_clk = C7;
					num_clk_load = 1'b1;
					nxt_state = NOTE2;
				end
			end
			NOTE2: begin
				// repeat playing C7 untile the duration counter reach 0
				if(~|num_clk) begin			// reload num clk if needed
					nxt_num_clk = C7;
					num_clk_load = 1'b1;
					S_piezo = 1'b1;
				end
				else if(num_clk == (C7 >> 1))
					R_piezo = 1'b1;			// 50% duty cycle
				if(~|dura) begin			// setup counters and go to next note after the duration counter expires, cutoff any note being played
					nxt_dura = dura_1;
					nxt_note = 1'b1;
					nxt_num_clk = E7;
					num_clk_load = 1'b1;
					nxt_state = NOTE3;
				end
			end
			NOTE3: begin
				// repeat playing E7 untile the duration counter reach 0
				if(~|num_clk) begin			// reload num clk if needed
					nxt_num_clk = E7;
					num_clk_load = 1'b1;
					S_piezo = 1'b1;
				end
				else if(num_clk == (E7 >> 1))
					R_piezo = 1'b1;			// 50% duty cycle
				if(~|dura) begin			// setup counters and go to next note after the duration counter expires, cutoff any note being played
					nxt_dura = dura_2;
					nxt_note = 1'b1;
					nxt_num_clk = G7;
					num_clk_load = 1'b1;
					nxt_state = NOTE4;
				end
			end
			NOTE4: begin
				// repeat playing G7 untile the duration counter reach 0
				if(~|num_clk) begin			// reload num clk if needed
					nxt_num_clk = G7;
					num_clk_load = 1'b1;
					S_piezo = 1'b1;
				end
				else if(num_clk == (G7 >> 1))
					R_piezo = 1'b1;			// 50% duty cycle
				if(~|dura) begin			// setup counters and go to next note after the duration counter expires, cutoff any note being played
					nxt_dura = dura_3;
					nxt_note = 1'b1;
					nxt_num_clk = E7;
					num_clk_load = 1'b1;
					nxt_state = NOTE5;
				end
			end
			NOTE5: begin
				// repeat playing E7 untile the duration counter reach 0
				if(~|num_clk) begin			// reload num clk if needed
					nxt_num_clk = E7;
					num_clk_load = 1'b1;
					S_piezo = 1'b1;
				end
				else if(num_clk == (E7 >> 1))
					R_piezo = 1'b1;			// 50% duty cycle
				if(~|dura) begin			// setup counters and go to next note after the duration counter expires, cutoff any note being played
					nxt_dura = dura_4;
					nxt_note = 1'b1;
					nxt_num_clk = G7;
					num_clk_load = 1'b1;
					nxt_state = NOTE6;
				end
			end
			NOTE6: begin
				// repeat playing G7 untile the duration counter reach 0
				if(~|num_clk) begin			// reload num clk if needed
					nxt_num_clk = G7;
					num_clk_load = 1'b1;
					S_piezo = 1'b1;
				end
				else if(num_clk == (G7 >> 1))
					R_piezo = 1'b1;			// 50% duty cycle
				if(~|dura) begin			// when the duration counter expires for the last time, go back to IDLE and make piezo low
					R_piezo = 1'b1;
					nxt_state = IDLE;
				end
			end
			default:						// is IDLE
				if(go) begin				// wait in IDLE until go asserted while keeping both piezo and piezo_n low until go asserted
					nxt_dura = dura_1;		// setup a duration of 2^23 clocks
					nxt_note = 1'b1;		// load the duration of note 1 in the next clock cycle
					S_piezo = 1'b1;			// begin to generate piezo in the next clock cycle
					nxt_num_clk = G6;
					num_clk_load = 1'b1;	// load num_clk with the value corresponding to the frequence of the G6 note in the next clock cycle
					nxt_state = NOTE1;		// start processing note 1 in the next clock cycle
				end
		endcase
	end
	
	// SR flop generating piezo
	always_ff @(posedge clk, negedge rst_n)
		if(!rst_n)
			piezo <= 1'b0;
		else if(R_piezo)
			piezo <= 1'b0;
		else if(S_piezo)
			piezo <= 1'b1;
	
	// generate piezo_n only when not in the IDLE state, otherwise, keep it low
	always_ff @(posedge clk, negedge rst_n)
		if(!rst_n)
			piezo_n <= 1'b0;
		else if(state == IDLE)
			piezo_n <= 1'b0;
		else
			piezo_n <= ~piezo;

endmodule
