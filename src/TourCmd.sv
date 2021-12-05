module TourCmd(clk,rst_n,start_tour,move,mv_indx,
               cmd_UART,cmd,cmd_rdy_UART,cmd_rdy,
			   clr_cmd_rdy,send_resp,resp);

	input clk,rst_n;						// 50MHz clock and asynch active low reset
	input start_tour;						// from done signal from TourLogic
	input [7:0] move;						// encoded 1-hot move to perform
	output reg [4:0] mv_indx;				// "address" to access next move
	input [15:0] cmd_UART;					// cmd from UART_wrapper
	input cmd_rdy_UART;						// cmd_rdy from UART_wrapper
	output [15:0] cmd;						// multiplexed cmd to cmd_proc
	output cmd_rdy;							// cmd_rdy signal to cmd_proc
	input clr_cmd_rdy;						// from cmd_proc (goes to UART_wrapper too)
	input send_resp;						// lets us know cmd_proc is done with command
	output logic [7:0] resp;				// either 0xA5 (done) or 0x5A (in progress)

	logic cmd_from_UART;					// high when cmd is from UART, low when cmd is from Tour Logic
	logic moving_vert;						// high when moving vertically
	logic cmd_rdy_tour_logic;				// high when logic from Tour Logic is ready
	logic [15:0] cmd_vert, cmd_hori;		// vertical and horizontal move commands decomposed from move from Tour Logic
	logic [15:0] cmd_tour_logic;			// current cmd formed from Tour Logic, is the mux result between cmd_vert and cmd_hori
	logic clr_indx;							// clear input to the mv_indx counter
	logic nxt_indx;							// enable input to the mv_indx counter
	logic move_vert_two, move_hori_two;		// high when moving two squares, low when moving one
	logic move_vert_up, move_hori_right;	// high when moving up/right, low when moving down/left, respectively
	
	typedef enum logic [2:0] {IDLE, VERT, HOLD1, HORI, HOLD2} state_t;
	state_t state, nxt_state;
	
	///////////////////
	// mv_indx cntr //
	/////////////////
	always_ff @(posedge clk)
		if(clr_indx)						// synch reset from SM
			mv_indx <= 5'h00;
		else if (nxt_indx)
			mv_indx <= mv_indx + 1;			// when enabled by SM, count up
	
	/////////////////////
	// move decompose //
	///////////////////
	always_comb begin
		// default to prevent latches, default means going down by 1 and left by 1
		move_vert_up = 1'b0;
		move_vert_two = 1'b0;
		move_hori_right = 1'b0;
		move_hori_two = 1'b0;
		
		// decode move from Tour Logic
		case(move)
			8'b0000_0001: begin				// go (-1, 2)
				move_vert_two = 1'b1;
				move_vert_up = 1'b1;
			end
			8'b0000_0010: begin				// go (1, 2)
				move_vert_two = 1'b1;
				move_vert_up = 1'b1;
				move_hori_right = 1'b1;
			end
			8'b0000_0100: begin				// go (-2, 1)
				move_vert_up = 1'b1;
				move_hori_two = 1'b1;
			end
			8'b0000_1000: begin				// go (-2, -1)
				move_hori_two = 1'b1;
			end			
			8'b0001_0000: begin				// go (-1, -2)
				move_vert_two = 1'b1;
			end			
			8'b0010_0000: begin				// go (1, -2)
				move_vert_two = 1'b1;
				move_hori_right = 1'b1;
			end
			8'b0100_0000: begin				// go (2, -1)
				move_hori_two = 1'b1;
				move_hori_right = 1'b1;
			end
			8'b1000_0000: begin				// go (2, 1)
				move_vert_up = 1'b1;
				move_hori_two = 1'b1;
				move_hori_right = 1'b1;
			end
			default: begin
				move_vert_up = 1'b0;
				move_vert_two = 1'b0;
				move_hori_right = 1'b0;
				move_hori_two = 1'b0;
			end
		endcase
	end
	
	//////////////////////////////////////////////////////////////////////////////////
	// generate cmd and cmd_rdy (Note: moving vertically first, then horizontally) //
	////////////////////////////////////////////////////////////////////////////////
	// generate proper cmd for vertical moves according to decoded flag variables, move_vert_up and move_vert_two
	assign cmd_vert = move_vert_up ? (move_vert_two ? {4'b0010, 8'h00, 4'h2} :
													  {4'b0010, 8'h00, 4'h1}):
									 (move_vert_two ? {4'b0010, 8'h7F, 4'h2} :
									 				  {4'b0010, 8'h7F, 4'h1});
													  
	// generate proper cmd for horizontal moves according to decoded flag variables, move_hori_right and move_hori_two											  
	assign cmd_hori = move_hori_right ? (move_hori_two ? {4'b0011, 8'hBF, 4'h2} :
														 {4'b0011, 8'hBF, 4'h1}):
										(move_hori_two ? {4'b0011, 8'h3F, 4'h2} :
														 {4'b0011, 8'h3F, 4'h1});
	
	// select proper cmd for cmd_tour_logic
	assign cmd_tour_logic = moving_vert ? cmd_vert : cmd_hori;

	// select proper cmd as output
	assign cmd = cmd_from_UART ? cmd_UART : cmd_tour_logic;

	// select proper cmd_rdy as output
	assign cmd_rdy = cmd_from_UART ? cmd_rdy_UART : cmd_rdy_tour_logic;

	////////////////////////
	// SM state register //
	//////////////////////
	always_ff @(posedge clk, negedge rst_n)
		if(!rst_n)
			state <= IDLE;
		else
			state <= nxt_state;
	
	/////////////////
	// SM control //
	///////////////	
	always_comb begin
		// default SM outputs to prevent unintended latches
		cmd_from_UART = 1'b0;
		nxt_indx = 1'b0;
		clr_indx = 1'b0;
		moving_vert = 1'b0;
		cmd_rdy_tour_logic = 1'b0;
		resp = 8'h5A;
		nxt_state = state;
		
		case(state)
			VERT: begin
				moving_vert = 1'b1;			// indicate moving vertically
				cmd_rdy_tour_logic = 1'b1;	// indicate vertical move cmd from tour logic is ready
				if(clr_cmd_rdy)
					nxt_state = HOLD2;
			end
			HOLD1: begin
				moving_vert = 1'b1;			// still moving vertically, but cmd_rdy was knocked down at this stage
				if(send_resp)
					nxt_state = VERT;
			end
			HORI: begin
				cmd_rdy_tour_logic = 1'b1;	// indicate horizontal move cmd from tour logic is ready
				if(clr_cmd_rdy)
					nxt_state = HOLD1;
			end
			HOLD2: begin
				if(mv_indx == 8'd23)
					resp = 8'hA5;			// indicate this is the last move when mv_indx reaches 23
				if(send_resp)				// when the horizontal move
					if(mv_indx == 8'd23)	
						nxt_state = IDLE;	// go back to IDLE if all 24 moves finished
					else begin
						nxt_indx = 1'b1;	// otherwise, increment mv_indx by 1 and go back to move horizontally
						nxt_state = HORI;
					end
			end
			default: begin			// is IDLE
				resp = 8'hA5;				// set resp as we are done in IDLE, when cmd is from UART
				cmd_from_UART = 1'b1;		// indicate that cmd is from UART
				if(start_tour) begin		// when Tour Logic finish calculations, start to move
					clr_indx = 1'b1;		// zero mv_indx counter
					nxt_state = HORI;
				end
			end
		endcase
	end
	
endmodule