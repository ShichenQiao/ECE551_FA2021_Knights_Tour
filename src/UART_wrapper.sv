module UART_wrapper(
	input clk, rst_n,		// clk and active low reset
	input clr_cmd_rdy,		// knock down cmd_rdy when asserted
	input send_resp,				// start UART transmission when asserted
	input [7:0]resp,		// response byte to be sent from UART
	input RX,				// UART RX data line
	output TX,				// UART TX data line
	output logic cmd_rdy,	// asserted when 16-bit command is ready
	output [15:0]cmd,		// 16-bit command from the received 2 bytes
	output resp_sent		// asserted when UART transmission finished
);

	logic rx_rdy;				// asserted when UART rx data is ready
	logic [7:0]rx_data;			// UART rx data byte
	logic clr_rx_rdy;			// SM output to clear rx_rdy
	logic capture_high;			// SM output to capture and store the high byte
	logic set_rdy;				// SM output to set cmd_rdy
	logic SM_clr_cmd_rdy;		// SM output to clear cmd_rdy
	logic [7:0]high_byte;		// high byte of cmd
	
	typedef enum logic {IDLE, WRAP} state_t;
	state_t state, nxt_state;
	
	// instantiate UART module
	UART iUART(.clk(clk), .rst_n(rst_n), .RX(RX), .TX(TX), .rx_rdy(rx_rdy), .clr_rx_rdy(clr_rx_rdy), .rx_data(rx_data), .trmt(send_resp), .tx_data(resp), .tx_done(resp_sent));
	
	// state register
	always_ff @(posedge clk, negedge rst_n)
		if(!rst_n)
			state <= IDLE;
		else
			state <= nxt_state;
	
	always_comb begin
		// default all SM outputs to prevent unintended latches
		capture_high = 1'b0;
		clr_rx_rdy = 1'b0;
		set_rdy = 1'b0;
		nxt_state = state;
		SM_clr_cmd_rdy = 1'b0;

		case(state)
			WRAP:
				if(rx_rdy) begin
					set_rdy = 1'b1;				// set cmd_rdy after 2 bytes received
					clr_rx_rdy = 1'b1;			// clear rx_cdy to indicate it has been consumed
					nxt_state = IDLE;
				end
			default: begin			// is IDLE
				if(cmd_rdy & (~RX))				// clear cmd_rdy when received a new command
					SM_clr_cmd_rdy = 1'b1;
				if(rx_rdy) begin
					capture_high = 1'b1;		// capture high byte when first byte ready
					clr_rx_rdy = 1'b1;			// clear rx_cdy to indicate it has been consumed
					nxt_state = WRAP;
				end
			end
		endcase
	end
	
	// capture high byte
	always_ff @(posedge clk)
		if(capture_high)
			high_byte <= rx_data;
	
	// form 16 bit cmd from 2 bytes
	assign cmd = {high_byte, rx_data};
	
	// SR flop generating cmd_rdy, set_rdy is S, clr_cmd_rdy is R
	always_ff @(posedge clk, negedge rst_n)
		if(!rst_n)
			cmd_rdy <= 1'b0;
		else if(clr_cmd_rdy|SM_clr_cmd_rdy)
			cmd_rdy <= 1'b0;
		else if(set_rdy)
			cmd_rdy <= 1'b1;
	
endmodule
