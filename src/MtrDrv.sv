module MtrDrv(
	input clk, rst_n,					// clock and active low asynch reset
	input signed [10:0]lft_spd,			// signed left motor speed
	input signed [10:0]rght_spd,		// signed right motor speed
	output lftPWM1, lftPWM2,			// to power MOSFETs that drive lft motor
	output rghtPWM1, rghtPWM2			// to power MOSFETs that drive right motor
);

logic [10:0]left_duty, right_duty;		// duty cycles of the motors

// get unsigned 11-bit duty cycles from signed 11-bit speeds
assign left_duty = lft_spd + 11'h400;
assign right_duty = rght_spd + 11'h400;

// instansiate PWM11 blocks for the two motors
PWM11 i_left_PWM(.clk(clk), .rst_n(rst_n), .duty(left_duty), .PWM_sig(lftPWM1), .PWM_sig_n(lftPWM2));
PWM11 i_right_PWM(.clk(clk), .rst_n(rst_n), .duty(right_duty), .PWM_sig(rghtPWM1), .PWM_sig_n(rghtPWM2));

endmodule
