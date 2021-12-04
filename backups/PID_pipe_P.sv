module PID(
	input clk, rst_n,
	input moving,							// clear I_term if not moving
	input err_vld,							// compute I & D again when vld
	input signed [11:0] error,				// signed error into PID
	input [9:0] frwrd,						// summed with PID to form lft_spd,right_spd
	output [10:0] lft_spd, rght_spd			// these form the input to mtr_drv
);
	// localparam signed P_COEFF = 5'h08;
	localparam signed D_COEFF = 6'h0B;

	// P_term signals
	logic signed [13:0] P_term;
	logic signed [9:0] err_sat;
	
	// I_term signals
	logic signed [8:0] I_term;
	logic signed [14:0] err_ext;			// sign extended, 15 bit version of err_sat
	logic signed [14:0] integrator;			// the integrator FF
	logic signed [14:0] sum;				// the sum of err_ext and integrator
	logic overflow;							// asserted when overflow occurs
	
	// D_term signals
	logic signed [12:0] D_term;
	logic signed [9:0] err_sat_FF1, err_sat_FF2;			// double flopped version of err_sat, using err_vld as en
	logic signed [9:0] D_diff;				// difference before saturation (10-bits)
	logic signed [6:0] D_diff_sat;			// difference after saturation (7-bits)
	
	// PID block signals
	logic signed [13:0] PID;				// sum of P_term, I_term, and D_term
	logic signed [10:0] lft, rght;			// unsaturated lft and rght speeds
		
	//////////////////////////////////
	// Free running pipeline flops //
	////////////////////////////////


	//////////////////////
	// Generate P_term //
	////////////////////

	// saturate error from 12 bits to 10 bits
	assign err_sat = (error[11] && ~&error[10:9]) ? 10'h200:
					 (!error[11] && |error[10:9]) ? 10'h1FF:
					  error[9:0];

	assign P_term = {err_sat_FF1[9], err_sat_FF1, 3'b000};			// P_term = err_sat * P_COEFF
	
	//////////////////////
	// Generate I_term //
	////////////////////

	// sign extends err_sat from 10 bits to 15 bits
	assign err_ext = {{5{err_sat[9]}}, err_sat};

	// calculate the output of the accumulator
	assign sum = integrator + err_ext;

	// overflow occurs when the MSB of the addends are the same, but different from the MSB of the sum
	assign overflow = ((~sum[14]) & integrator[14] & err_ext[14])
					  |(sum[14] & (~integrator[14]) & (~err_ext[14]));
					
	// 15-bit wide integrator with active low reset
	always_ff @(posedge clk, negedge rst_n)
		if(!rst_n)
			integrator <= 15'h0000;
		else if(!moving)
			integrator <= 15'h0000;
		else if(err_vld && !overflow)
			integrator <= sum;

	// output the left-most 9 bits of the integrator as the I_term
	assign I_term = integrator[14:6];

	//////////////////////
	// Generate D_term //
	////////////////////

	// double flop err_sat, using err_vld as en
	always_ff @(posedge clk, negedge rst_n)
		if(!rst_n) begin
			err_sat_FF1 <= 10'h000;
			err_sat_FF2 <= 10'h000;
		end
		else if(err_vld) begin
			err_sat_FF1 <= err_sat;
			err_sat_FF2 <= err_sat_FF1;
		end
			
	// calculate D_diff = err_sat - prev_err
	assign D_diff = err_sat - err_sat_FF2;

	// saturate D_diff_sat from 10 bits to 7 bits
	assign D_diff_sat = (D_diff[9] && ~&D_diff[8:6]) ? 7'h40:
						(!D_diff[9] && |D_diff[8:6]) ? 7'h3F:
						D_diff[6:0];
				
	assign D_term = D_diff_sat * $signed(D_COEFF);
	
	////////////////////////////////////
	// Generate lft_spd and rght_spd //
	//////////////////////////////////
	
	// sum up the P, sign-extended I, and sign-exteded D terms
	assign PID = P_term + {{5{I_term[8]}}, I_term} + {D_term[12], D_term};
	
	// generate left and right speeds from frwrd +/- PID only when robot is moving, otherwise, use 0s
	assign lft = moving ? ({1'b0, frwrd} + PID[13:3]) : 11'h000;
	assign rght = moving ? ({1'b0, frwrd} - PID[13:3]) : 11'h000;
	
	// positive saturate left and right speeds to 0x3FF
	assign lft_spd = (~PID[13] && lft[10]) ? 11'h3FF : lft;
	assign rght_spd = (PID[13] && rght[10]) ? 11'h3FF : rght;
	
	
endmodule
