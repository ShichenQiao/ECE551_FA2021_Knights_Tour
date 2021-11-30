module cmd_proc(clk,rst_n,cmd,cmd_rdy,clr_cmd_rdy,send_resp,strt_cal,
                cal_done,heading,heading_rdy,lftIR,cntrIR,rghtIR,error,
				frwrd,moving,tour_go,fanfare_go);
				
	parameter FAST_SIM = 1;				// speeds up incrementing of frwrd register for faster simulation
				
	input clk,rst_n;					// 50MHz clock and asynch active low reset
	input [15:0] cmd;					// command from BLE
	input cmd_rdy;						// command ready
	output logic clr_cmd_rdy;			// mark command as consumed
	output logic send_resp;				// command finished, send_response via UART_wrapper/BT
	output logic strt_cal;				// initiate calibration of gyro
	input cal_done;						// calibration of gyro done
	input signed [11:0] heading;		// heading from gyro
	input heading_rdy;					// pulses high 1 clk for valid heading reading
	input lftIR;						// nudge error +
	input cntrIR;						// center IR reading (have I passed a line)
	input rghtIR;						// nudge error -
	output reg signed [11:0] error;		// error to PID (heading - desired_heading)
	output reg [9:0] frwrd;				// forward speed register
	output logic moving;				// asserted when moving (allows yaw integration)
	output logic tour_go;				// pulse to initiate TourCmd block
	output logic fanfare_go;			// kick off the "Charge!" fanfare on piezo
	
	///////////////////////
	// Internal signals //
	/////////////////////
	logic clr_frwrd, dec_frwrd, inc_frwrd;			// SM outputs to control the frwrd register
	logic move_cmd;									// SM output to inform a new move command is issued
	logic move_done;								// asserted when the current move is finished
	logic [2:0] sq_to_move;							// the number of squares to move, is cmd[2:0]
	logic [3:0] num_cntrIR_paulses;					// the number of cntrIR rise observed during the current move
	logic cntrIR_ff1, cntrIR_ff2, cntrIR_ff3;		// triple flop versions of cntrIR_rise
	logic cntrIR_rise;								// asserted when rise edge cntrIR detected
	logic signed [11:0]desired_heading;				// 12-bit version of the desired_heading
	logic signed [11:0]err_nudge;					// nudge value to correct error
	typedef enum logic [2:0] {IDLE, CALIBRATE, UPDATE_HEADING, TRAVELING, RAMP_DOWN} state_t;
	state_t state, nxt_state;

	/////////////////////
	// frwrd register //
	///////////////////
	generate 
		if(FAST_SIM) begin
			always_ff @(posedge clk, negedge rst_n)
				if(!rst_n)
					frwrd <= 10'h000;						// asynch reset
				else if(clr_frwrd)
					frwrd <= 10'h000;						// synch reset from SM
				else if(heading_rdy)						// only increments or decrements when heading_rdy
					if(inc_frwrd & (~&frwrd[9:8]))			// when inc_frwrd asserted and max_spd not reached, increment frwrd
						frwrd <= frwrd + 10'h20;			// if FAST_SIM, increment by 32
					else if (dec_frwrd & (|frwrd))			// when dec_frwrd asserted and 0 not reached, decrement frwrd
						frwrd <= frwrd - 10'h40;			// if FAST_SIM, decrement by 32 * 2 = 64
		end
		else begin
			always_ff @(posedge clk, negedge rst_n)
				if(!rst_n)
					frwrd <= 10'h000;						// asynch reset
				else if(clr_frwrd)
					frwrd <= 10'h000;						// synch reset from SM
				else if(heading_rdy)						// only increments or decrements when heading_rdy
					if(inc_frwrd & (~&frwrd[9:8]))			// when inc_frwrd asserted and max_spd not reached, increment frwrd
						frwrd <= frwrd + 10'h04;			// if not FAST_SIM, increment by 4
					else if (dec_frwrd & (|frwrd))			// when dec_frwrd asserted and 0 not reached, decrement frwrd
						frwrd <= frwrd - 10'h08;			// if not FAST_SIM, decrement by 4 * 2 = 8
		end
	endgenerate
	
	///////////////////////
	// Counting squares //
	/////////////////////
	always_ff @(posedge clk, negedge rst_n)					// triple flop cntrIR for rise edge detection
		if(!rst_n) begin
			cntrIR_ff1 <= 1'b0;
			cntrIR_ff2 <= 1'b0;
			cntrIR_ff3 <= 1'b0;
		end
		else begin
			cntrIR_ff1 <= cntrIR;
			cntrIR_ff2 <= cntrIR_ff1;
			cntrIR_ff3 <= cntrIR_ff2;
		end
	assign cntrIR_rise = (cntrIR_ff2 & (~cntrIR_ff3));		// detect rise edge
	
	always_ff @(posedge clk)
		if(move_cmd)
			sq_to_move <= cmd[2:0];							// capture the number of squares to move when the move command is issued
			
	always_ff @(posedge clk)
		if(move_cmd)
			num_cntrIR_paulses <= 3'b000;					// clear the number of squares moved when the move command is just issued
		else if(cntrIR_rise)
			num_cntrIR_paulses <= num_cntrIR_paulses + 3'b001;			// increment the number of squares moved by 1 when rise edge cntrIR detected
	
	assign move_done = ({sq_to_move, 1'b0} == num_cntrIR_paulses);		// current move finish when num_cntrIR_paulses = 2 * sq_to_move
	
	////////////////////
	// PID interface //
	//////////////////
	always_ff @(posedge clk)
		if(move_cmd)
			if(~|cmd[11:4])
				desired_heading <= 12'h000;					// desired_heading is 00 if cmd[11:4] is 0
			else
				desired_heading <= {cmd[11:4], 4'hF};		// otherwise, append cmd[11:4] by an F to form desired_heading
	generate
		if(FAST_SIM) begin									// when FAST_SIM, err_nudge is larger in magnitude, if not 0
			assign err_nudge = lftIR ? 12'h1FF :
							   rghtIR ? 12'hE00 :
							   12'h000;						// calculate err_nudge from lftIR and rghtIR
		end
		else begin
			assign err_nudge = lftIR ? 12'h05F :
							   rghtIR ? 12'hFA1 :
							   12'h000;						// calculate err_nudge from lftIR and rghtIR
		end
	endgenerate
	
	assign error = heading - desired_heading + err_nudge;	// calculate error for the PID block
	
	/////////////////
	// SM control //
	///////////////
	always_ff @(posedge clk, negedge rst_n)
		if(!rst_n)
			state <= IDLE;
		else
			state <= nxt_state;
		
	always_comb begin
		// default all outputs to prevent unintended latches
		clr_cmd_rdy = 1'b0;
		clr_frwrd = 1'b0;
		dec_frwrd = 1'b0;
		inc_frwrd = 1'b0;
		move_cmd = 1'b0;
		strt_cal = 1'b0;
		send_resp = 1'b0;
		moving = 1'b0;
		fanfare_go = 1'b0;
		tour_go = 1'b0;
		nxt_state = state;
		
		case(state)
			CALIBRATE:
				if(cal_done) begin							// send response and return to IDLE after calibration finished
					send_resp = 1'b1;
					nxt_state = IDLE;
				end
			UPDATE_HEADING: begin							// setp 1 of moving, adjust to proper heading
				moving = 1'b1;								// assert moving for PID to integreate correctly
				clr_frwrd = 1'b1;							// keep frwrd 0
				if ((error > $signed(-12'h030)) && (error < $signed(12'h030)))
					nxt_state = TRAVELING;					// start to ramp up when error reach a value within (-12'h030, 12'h030)
			end
			TRAVELING: begin								// step 2 of moving, ramp up and travel at max_spd
				moving = 1'b1;
				inc_frwrd = 1'b1;							// incrementing the frwrd register
				if(move_done) begin							// when the required number of square is traveled
					if(cmd[12] == 1'b1)
						fanfare_go = 1'b1;					// initiate fanfare if cmd[15:12] was 4'b0011
					nxt_state = RAMP_DOWN;
				end
			end
			RAMP_DOWN: begin								// step 3 of moving, slowing down
				moving = 1'b1;
				dec_frwrd = 1'b1;							// decrementing the frwrd register
				if(frwrd == 10'h000) begin					// send response and return to IDLE the frwrd register reaches 0
					send_resp = 1'b1;
					nxt_state = IDLE;
				end
			end
			default:			// is IDLE
				if(cmd_rdy) begin							// dispatch to the appropriate state based on the opcode (cmd[15:!2])
					clr_cmd_rdy = 1'b1;						// assert clr_cmd_rdy immediately
					if(cmd[15:12] == 4'b0000) begin			// calibrate
						strt_cal = 1'b1;					// start calibration
						nxt_state = CALIBRATE;
					end
					else if(cmd[15:13] == 3'b001) begin		// move, or move with fanfare
						move_cmd = 1'b1;
						nxt_state = UPDATE_HEADING;
					end
					else if(cmd[15:12] == 4'b0100)			// start tour
						tour_go = 1'b1;						// switch sommand control to TourCmd
				end
		endcase
	end
	
endmodule
