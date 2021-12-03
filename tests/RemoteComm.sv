module RemoteComm(clk, rst_n, RX, TX, cmd, send_cmd, cmd_sent, resp_rdy, resp);

	input clk, rst_n;		// clock and active low reset
	input RX;				// serial data input
	input send_cmd;			// indicates to tranmit 16-bit command (cmd)
	input [15:0] cmd;		// 16-bit command

	output TX;				// serial data output
	output logic cmd_sent;	// indicates transmission of command complete
	output resp_rdy;		// indicates 8-bit response has been received
	output [7:0] resp;		// 8-bit response from DUT

	wire [7:0] tx_data;		// 8-bit data to send to UART
	wire tx_done;			// indicates 8-bit was sent over UART
	
	logic [7:0]low_byte; 	// low byte of cmd
	logic sel;				// sel output from SM, 1 select high byte, 0 select low byte
	logic trmt;				// SM output to UART to send a byte
	logic set_cmd_sent;		// SM output to the SR flop controlling cmd_sent

	///////////////////////////////////////////////
	// Registers needed...state machine control //
	/////////////////////////////////////////////
	always_ff @(posedge clk)			// used to buffer low byte of cmd
		if(send_cmd)
			low_byte = cmd[7:0];
			
	// SR flop to generate cmd_sent
	always @(posedge clk, negedge rst_n)
		if(!rst_n)
			cmd_sent <= 1'b0;
		else if(send_cmd)			// send_cmd is R
			cmd_sent <= 1'b0;
		else if(set_cmd_sent)		// set_cmd_sent is S
			cmd_sent <= 1'b1;

	///////////////////////////////
	// state definitions for SM //
	/////////////////////////////
	typedef enum logic [1:0] {IDLE, SEND, WAIT} state_t;
	state_t state, nxt_state;

	///////////////////////////////////////////////
	// Instantiate basic 8-bit UART transceiver //
	/////////////////////////////////////////////
	UART iUART(.clk(clk), .rst_n(rst_n), .RX(RX), .TX(TX), .tx_data(tx_data), .trmt(trmt),
			   .tx_done(tx_done), .rx_data(resp), .rx_rdy(resp_rdy), .clr_rx_rdy(resp_rdy));
			   
	// mux selecting tx_data, between high byte and low byte of the cmd
	assign tx_data = sel ? cmd[15:8] : low_byte;
	
	// state register
	always_ff @(posedge clk, negedge rst_n)
		if(!rst_n)
			state <= IDLE;
		else
			state <= nxt_state;
			
	always_comb begin
		// default all SM outputs to prevent unintended latches
		sel = 1'b0;
		trmt = 1'b0;
		set_cmd_sent = 1'b0;
		nxt_state = state;
		
		case(state)
			SEND:
				if(tx_done) begin
					trmt = 1'b1;		// send low byte
					nxt_state = WAIT;
				end
			WAIT:
				if(tx_done) begin
					set_cmd_sent = 1'b1;		// wait until low byte sent to assert cmd_sent
					nxt_state = IDLE;
				end
			default:		// is IDLE
				if(send_cmd) begin
					sel = 1'b1;
					trmt = 1'b1;		// send high byte
					nxt_state = SEND;
				end
		endcase
	end

endmodule
