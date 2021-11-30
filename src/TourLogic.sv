module TourLogic(clk, rst_n, x_start, y_start, go, done, indx, move);

	input clk, rst_n;							// 50MHz clock and active low asynch reset
	input [2:0] x_start, y_start;				// starting position on 5x5 board
	input go;									// initiate calculation of solution
	input [4:0] indx;							// used to specify index of move to read out
	output logic done;							// pulses high for 1 clock when solution complete
	output [7:0] move;							// the move addressed by indx (1 of 24 moves)


	////////////////////////////////////////
	// Declare needed internal registers //
	//////////////////////////////////////
	logic visited[0:4][0:4];					// 2-D array of 1-bit boolean values that keep track of where on the board the knight has visited.
	logic [7:0] last_move[0:23];				// 1-D array (of size 24) to keep track of last move taken from each move index
	logic [7:0] possible_move[0:23];			// 1-D array (of size 24) to keep track of possible moves from each move index
	logic [7:0] move_try;						// hold move would be tried next
	logic [4:0] move_num;						// move number...when you have moved 24 times you are done.  Decrement when backing up
	logic [2:0] xx, yy;							// represent the current x/y coordinates of the knight
	
	////////////////////////////
	// SM states and signals //
	//////////////////////////
	typedef enum logic [1:0] {IDLE, FIND, MOVE, BACK} state_t;
	state_t state, nxt_state;
	logic init;									// asserted when leaving the IDLE state, initialize the registers
	logic backing;								// asserted in the BACK state indicating we mad a bad decision and we are going backward along the path to find a better solution
	logic update_position;						// asserted when we are travelling from one block to another, NOT assterted when backing
	logic find_possible;						// asserted in the FIND state to find current possible moves and store at possible_move[move_num]
	logic next_try;								// asserted to try next move, always starting with 8'h01 and shifting one bit left at a time
	
	
	/////////////////////////////////////////////
	// Register recording the number of moves //
	///////////////////////////////////////////
	always_ff @(posedge clk)
		if(init)
			move_num <= 5'h00;									// set move_num to 0 when starting, so we finish when it reaches 24
		else if(update_position)								// increment move_num by 1 when we take a move
			move_num <= move_num + 5'h01;
		else if(backing)										// decrement move_num by 1 when we backup one step
			move_num <= move_num - 5'h01;
		
	/////////////////////////////////////////////////////////////
	// Registers recording the current position of the Knight //
	///////////////////////////////////////////////////////////
	always_ff @(posedge clk)
		if(init) begin											// set xx and yy to the Knight's initial position when starting
			xx <= x_start;
			yy <= y_start;
		end
		else if(update_position) begin							// update the position of the Knight when told to take the current try
			xx <= xx + off_x(move_try);
			yy <= yy + off_y(move_try);
		end
		else if(backing) begin									// undo the last move when backing up
			xx <= xx - off_x(last_move[move_num - 1]);
			yy <= yy - off_y(last_move[move_num - 1]);
		end
			
	/////////////////////////////////////////////////////////////////////////////////////////////////
	// Registers recording the visiting status of the board, 0 is not visited, otherwise, visited //
	///////////////////////////////////////////////////////////////////////////////////////////////
	always_ff @(posedge clk)
		if(init) begin
			for(integer i = 0; i < 5; i++)
				for(integer j = 0; j < 5; j++)
					visited[i][j] <= 1'b0;						// clear the visited status of the board when resetting
			visited[y_start][x_start] <= 1'b1;					// set the initial position with a value 1, indicating visited
		end
		else if(update_position)
			visited[yy + off_y(move_try)][xx + off_x(move_try)] <= 1'b1;		// take the current move_try and visit the destination square when we are told to move by update_position
		else if(backing)
			visited[yy][xx] <= 1'b0;							// clear the visiting status when backing up from the current square
	
	//////////////////////////////////////////////////////////////////
	// Registers recording the possible moves from each move index //
	////////////////////////////////////////////////////////////////
	always_ff @(posedge clk)
		if(find_possible)
			possible_move[move_num] <= calc_poss(xx, yy);		// call function to find the packed vector about all possible moves the Knight has currently
	
	///////////////////////////////////////////////////////////////////
	// Registers recording the last move taken from each move index //
	/////////////////////////////////////////////////////////////////
	always_ff @(posedge clk)
		if(update_position)
			last_move[move_num] <= move_try;					// record the move we decided to take while moving to the new position
	
	///////////////////////////////////////////////
	// Registers recording the move being tried //
	/////////////////////////////////////////////
	always_ff @(posedge clk)
		if(find_possible)
			move_try <= 8'h01;									// always start trying from 8'h01 for a new position
		else if(backing)
			move_try <= last_move[move_num - 1] << 1;			// when backing, resume the previous try, and shift it left by 1 bit to explore a move haven't been tried
		else if(next_try)
			move_try <= move_try << 1;							// when not backing, shift the current try left by 1 bit to explore a move haven't been tried when nxt_try asserted
			
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
		// default all SM outputs to prevent unintended latches
		done = 1'b0;
		init = 1'b0;
		backing = 1'b0;
		find_possible = 1'b0;
		update_position = 1'b0;
		next_try = 1'b0;
		nxt_state = state;
	
		case(state)
			FIND: begin
				find_possible = 1'b1;							// notify the registers that we are in a new position and want to find all possible moves next
				nxt_state = MOVE;
			end
			MOVE:
				if(move_num == 5'd24) begin						// assert done and go back to IDLE after 24 moves
					done = 1'b1;
					nxt_state = IDLE;
				end
				else if((|(possible_move[move_num] & move_try)) 										// if the move being tried is possible
						&& ((visited[yy + off_y(move_try)][xx + off_x(move_try)]) == 0)) begin			// and has not been visited
					update_position = 1'b1;						// notify the registers to go ahead with the current move_try
					nxt_state = FIND;							// explore further moves we can take after the current try
				end
				else if(move_try != 8'h80)						// if the current try is not good, try the next direction
					next_try = 1'b1;
				else
					nxt_state = BACK;							// if stuck, go backing up
			BACK: begin
				backing = 1'b1;									// notify the registers that we are backing up
				if(last_move[move_num - 1] != 8'h80)			// keep backing until there are some possible moves have not been tried
					nxt_state = MOVE;							// go back to MOVE it they are found
			end
			default:			// is IDLE
				if(go) begin
					init = 1'b1;
					nxt_state = FIND;							// wait until go is asserted to start solving the puzzle
				end
		endcase
	end
	
	///////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// Provide access to the move addressed by the input indx (1 of 24 moves), only valid when done is asseretd //
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////
	assign move = last_move[indx];


	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// Returns a packed byte of all the possible moves (at least in bound) moves given coordinates of Knight //
	//////////////////////////////////////////////////////////////////////////////////////////////////////////
	function [7:0] calc_poss(input [2:0] xpos,ypos);
		calc_poss = {(xpos <= 5'h02) && (ypos <= 5'h03), 		// high when able to go (2, 1)
					 (xpos <= 5'h02) && (ypos >= 5'h01), 		// high when able to go (2, -1)
					 (xpos <= 5'h03) && (ypos >= 5'h02), 		// high when able to go (1, -2)
					 (xpos >= 5'h01) && (ypos >= 5'h02),		// high when able to go (-1, -2)
					 (xpos >= 5'h02) && (ypos >= 5'h01),		// high when able to go (-2, -1)
					 (xpos >= 5'h02) && (ypos <= 5'h03),		// high when able to go (-2, 1)
					 (xpos <= 5'h03) && (ypos <= 5'h02),		// high when able to go (1, 2)
					 (xpos >= 5'h01) && (ypos <= 5'h02)};		// high when able to go (-1, 2)
	endfunction

	///////////////////////////////////////////////////////////////////////////////////////////
	// Returns the x-offset the Knight will move given the encoding of the move being tried //
	/////////////////////////////////////////////////////////////////////////////////////////
	function signed [2:0] off_x(input [7:0] try);
		off_x = (try[6] | try[7]) ? 3'b010 :					// going right by 2
				(try[1] | try[5]) ? 3'b001 :					// going right by 1
				(try[0] | try[4]) ? 3'b111 :					// going left by 1
				3'b110;											// going left by 2
	endfunction

	///////////////////////////////////////////////////////////////////////////////////////////
	// Returns the y-offset the Knight will move given the encoding of the move being tried //
	/////////////////////////////////////////////////////////////////////////////////////////
	function signed [2:0] off_y(input [7:0] try);
		off_y = (try[0] | try[1]) ? 3'b010 :					// going up by 2
				(try[2] | try[7]) ? 3'b001 :					// going up by 1
				(try[3] | try[6]) ? 3'b111 :					// going down by 1
				3'b110;											// going down by 2
	endfunction
  
endmodule    
