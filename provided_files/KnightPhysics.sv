module KnightPhysics(clk,RST_n,SS_n,SCLK,MISO,MOSI,INT,lftPWM1,lftPWM2,rghtPWM1,rghtPWM2,
                     IR_en,lftIR_n,cntrIR_n,rghtIR_n);
  //////////////////////////////////////////////////
  // Model of physics of the Knight, including a //
  // model of the gaurdrails and IR sensors.    //
  ///////////////////////////////////////////////

  input clk;				// 50MHz clock
  input RST_n;				// unsynchronized raw reset input
  input SS_n;				// active low slave select to inertial sensor
  input SCLK;				// Serial clock
  input MOSI;				// serial data in from monarch
  input IR_en;				// enables IR sensors
  input lftPWM1,lftPWM2;	// drive magnitude left motor
  input rghtPWM1,rghtPWM2;	// drive magnitude right motor
  
  output MISO;				// serial data out to inertial sensor
  output INT;				// inertial reading ready
  output reg lftIR_n;		// raw left IR sensor
  output reg cntrIR_n;		// center IR sensor
  output reg rghtIR_n;		// right IR sensor
  
  //////////////////////////////////////////////////////
  // Registers needed for modeling physics of Knight //
  ////////////////////////////////////////////////////
  reg signed [12:0] alpha_lft,alpha_rght;			// angular acceleration of wheels
  reg signed [15:0] omega_lft,omega_rght;			// angular velocities of wheels
  reg signed [16:0] omega_sum;				        // if sum positive we are moving forward
  reg signed [15:0] heading_v;					// function of omega_rght - omega_lft
  reg signed [19:0] heading_robot;				// angular orientation of robot (starts at zero) integration of heading_v
  reg [6:0] rand_err;
  reg signed [15:0] gyro_err;
  reg [14:0] xx,yy;  						// board coordinates with 4096X multiplier
  
  /////////////////////////////////////////////
  // Declare internal signals between units //
  ///////////////////////////////////////////
  wire [10:0] mtrL1,mtrL2;		// inversePWM outputs telling motor drive magnitude
  wire [10:0] mtrR1,mtrR2;		// inversePWM outputs telling motor drive magnitude  
  wire calc_physics;			// update the physics model everytime inversePWM refreshes
  
  /////////////////////////////////////////////////////
  // Instantiate model of SPI based inertial sensor //
  ///////////////////////////////////////////////////
  SPI_iNEMO4 iNEMO(.SS_n(SS_n),.SCLK(SCLK),.MISO(MISO),.MOSI(MOSI),.INT(INT),.YAW(heading_v+gyro_err));
  
  //////////////////////////////////////////////////////////////
  // Instantiate inverse PWM's to get motor drive magnitudes //
  ////////////////////////////////////////////////////////////
  inverse_PWM11e iMTRL1(.clk(clk),.rst_n(RST_n),.PWM_sig(lftPWM1),.duty_out(mtrL1),.vld(calc_physics));
  inverse_PWM11e iMTRL2(.clk(clk),.rst_n(RST_n),.PWM_sig(lftPWM2),.duty_out(mtrL2),.vld()); 
  inverse_PWM11e iMTRR1(.clk(clk),.rst_n(RST_n),.PWM_sig(rghtPWM1),.duty_out(mtrR1),.vld());
  inverse_PWM11e iMTRR2(.clk(clk),.rst_n(RST_n),.PWM_sig(rghtPWM2),.duty_out(mtrR2),.vld()); 

  /////////////////////////////////////////////
  // Next is modeling physics of MazeRunner //
  ///////////////////////////////////////////
  always @(posedge calc_physics) begin
	alpha_rght = alpha(mtrR1,mtrR2,omega_rght);	// angular accel direct to (duty - k*omega)
        alpha_lft = alpha(mtrL1,mtrL2,omega_lft);		// angular accel direct to (duty - k*omega)
	omega_lft = omega(omega_lft,alpha_lft);		// angular velocity is integral of alpha
	omega_rght = omega(omega_rght,alpha_rght);	// angular velocity is integral of alpha
	omega_sum = omega_lft + omega_rght;             // if just pivoting this is near zero, positive when moving forward
    heading_v = omega_plat(omega_rght,omega_lft);	// angular velocity of platform is function of omegaR - omegaL
	heading_robot = theta_plat(heading_robot,heading_v);	// theta of platform is integration of omega_plat
    rand_err = $random() % 128;				// 7-bit random error
    gyro_err = {{9{rand_err[6]}},rand_err};
	
	//// Now update position on board xx,yy based on heading & speed /////
	//// Also models reflective gaurdrails (i.e. lftIR_n, rghtIR_n) ////
	if ((omega_lft>$signed(16'd1000)) && (omega_rght>$signed(16'd1000))) begin // both wheels moving forward
	  case (heading_robot[19:8]) inside
	    [12'h3C8:12'h438] : begin		//  West
		    xx = xx - omega_sum[16:13];
			if (omega_sum>17'd22000)
		      if (heading_robot[19:8]<12'h3FF) 		// north of pure west
			    yy = (lftIR_n & rghtIR_n) ? yy + (8'h3F - heading_robot[19:12]) : 
				     (~lftIR_n) ? yy + 2 : yy;
			  else									// south of pure west
			    yy = (lftIR_n & rghtIR_n) ? yy - (heading_robot[19:12] - 8'h3F) : 
				     (~rghtIR_n) ? yy - 2 : yy;
			if ((yy[11:0]>12'h8C0) && (omega_sum>17'd22000))
			  rghtIR_n = 0;
			else
			  rghtIR_n = 1;
			if ((yy[11:0]<12'h740) && (omega_sum>17'd22000))
			  lftIR_n = 0;
			else
			  lftIR_n = 1;
		  end
		[12'hBC8:12'hC38] : begin		//  East
		    xx = xx + omega_sum[16:13];
			if (omega_sum>17'd22000)
		      if (heading_robot[19:8]<12'hBFF) 		// south of pure east
			    yy = (lftIR_n & rghtIR_n) ? yy - (8'hBF - heading_robot[19:12]) :
                     (~lftIR_n) ? yy - 2 : yy;
			  else									// north of pure east
			    yy = (lftIR_n & rghtIR_n) ? yy + (heading_robot[19:12] - 8'hBF) :
                     (~rghtIR_n) ? yy + 2 :	yy;
			if ((yy[11:0]>12'h8F0) && (omega_sum>17'd22000))   
			  lftIR_n = 0;
			else
			  lftIR_n = 1;
			if ((yy[11:0]<12'h710) && (omega_sum>17'd22000))
			  rghtIR_n = 0;
			else
			  rghtIR_n = 1;
		  end
		[12'h7C8:12'h7FF] : begin		// west of pure south
		  yy = yy - omega_sum[16:13];
			if (omega_sum>17'd22000)
			  xx = (lftIR_n & rghtIR_n) ? xx - (8'h7F - heading_robot[19:12]) :
                   (~lftIR_n) ? xx - 2 : xx;
			if ((xx[11:0]>12'h8F0) && (omega_sum>17'd22000))
			  lftIR_n = 0;
			else
			  lftIR_n = 1;
			if ((xx[11:0]<12'h710) && (omega_sum>17'd22000))
			  rghtIR_n = 0;
			else
			  rghtIR_n = 1;
          end
		[12'h800:12'h838] : begin		// east of pure south
		  yy = yy - omega_sum[16:13];
			if (omega_sum>17'd22000)
			  xx = (lftIR_n & rghtIR_n) ? xx + (heading_robot[19:12] - 8'h80) :
                   (~rghtIR_n) ? xx + 2	: xx;
			if ((xx[11:0]>12'h8F0) && (omega_sum>17'd22000))
			  lftIR_n = 0;
			else
			  lftIR_n = 1;
			if ((xx[11:0]<12'h710) && (omega_sum>17'd22000))
			  rghtIR_n = 0;
			else
			  rghtIR_n = 1;
          end		  
		[12'h000:12'h038] : begin						// west of pure north
		    yy = yy + omega_sum[16:13];
			if (omega_sum>17'd22000)
			  xx = (lftIR_n & rghtIR_n) ? xx - heading_robot[19:12] :
                   (~rghtIR_n) ? xx - 2 : xx;
			if ((xx[11:0]>12'h8F0) && (omega_sum>17'd22000))
			  rghtIR_n = 0;
			else
			  rghtIR_n = 1;
			if ((xx[11:0]<12'h710) && (omega_sum>17'd22000))
			  lftIR_n = 0;
			else
			  lftIR_n = 1;
		  end
		[12'hFC8:12'hFFF] : begin						// east of pure north
		    yy = yy + omega_sum[16:13];
			if (omega_sum>17'd22000)
			  xx = (lftIR_n & rghtIR_n) ? xx - {{9{heading_robot[19]}},heading_robot[19:12]} :
                   (~lftIR_n) ? xx + 2 : xx;
			if ((xx[11:0]>12'h8F0) && (omega_sum>17'd22000))
			  rghtIR_n = 0;
			else
			  rghtIR_n = 1;
			if ((xx[11:0]<12'h710) && (omega_sum>17'd22000))
			  lftIR_n = 0;
			else
			  lftIR_n = 1;
		  end
		default : $display("PHYS ERR: not traveling orthogonal direction");
	  endcase
	end else begin     // if wheels are not moving forward don't assert lft/rght IR's
	  lftIR_n = 1'b1;
	  rghtIR_n = 1'b1;
	end

	
	///////// Model center line crossings as function of lower 12-bits of xx/yy ///////
	if (((xx[11:0]>12'h3E0) && (xx[11:0]<12'h460)) ||  ((xx[11:0]>12'hBA0) && (xx[11:0]<12'hC20))) 
	  cntrIR_n = 1'b0;
	else if (((yy[11:0]>12'h3E0) && (yy[11:0]<12'h460)) ||  ((yy[11:0]>12'hBA0) && (yy[11:0]<12'hC20)))
	  cntrIR_n = 1'b0;
	else
	  cntrIR_n = 1'b1;	  
  end
	

  initial begin
	omega_lft = 16'h0000;
	omega_rght = 16'h0000;
	heading_robot = 16'h0000;
	xx = 15'h2800;	// start on left 
	yy = 15'h2800;	// top corner (0,4) 
	lftIR_n = 1;
	cntrIR_n = 1;
	rghtIR_n = 1;
  end
  
  //////////////////////////////////////////////////////
  // functions used in "physics" computations follow //
  ////////////////////////////////////////////////////
  
  //// Angular acceleration of wheel as function of duty, and omega ////
  function signed [12:0] alpha (input [10:0] duty1, duty2, input signed [15:0] omega1);
    reg [11:0] mag;
	reg [11:0] mag_shaped;
	reg [12:0] torque;
	reg [13:0] alpha14bit;

    mag = (duty1>duty2) ? duty1 - duty2 : duty2 - duty1;
	mag_shaped = $sqrt(real'({mag,12'h000}));
    torque = (duty1>duty2) ? mag_shaped : -{1'b0,mag_shaped};
	alpha14bit = {torque[12],torque} - {{2{omega1[15]}},omega1[15:4]} - {{4{omega1[15]}},omega1[15:6]};
        alpha = (alpha14bit[13]&~alpha14bit[12]) ? 13'h1000 :
	        (~alpha14bit[13]&alpha14bit[12]) ? 13'h0FFF :
		alpha14bit[12:0];

  endfunction
 
   //// Angular velocity of wheel as integration of alpha ////
  function signed [15:0] omega (input signed [15:0] omega1, input signed [12:0] torque);
    //// if torque is greater than friction wheel speed changes ////
	reg signed [15:0] intermediate;
	
    if ((torque>$signed(13'h0020)) || (torque<$signed(-13'h0020))) begin
	  intermediate = omega1 + {{6{torque[12]}},torque[12:3]};	// wheel speed integrates
	  if (intermediate>$signed(16'd32700))
	    omega = 16'd32700;
	  else if (intermediate<$signed(-16'd32700))
	    omega = -16'd32700;
	  else
	    omega = intermediate;
	end else
	  omega = omega1 - {{6{omega1[15]}},omega1[15:6]};	// friction takes its toll 
  endfunction

   //// Angular position of wheel as integration of omega ////  
  function signed [21:0] theta (input signed [21:0] theta1, input signed [15:0] omega);
	theta = theta1 + {{11{omega[15]}},omega[15:5]};
  endfunction
  
  //// Angular velocity of platform is proportional to omegaR - omegaL ////
  function signed [15:0] omega_plat (input signed [15:0] omegaR,omegaL);
	omega_plat = {omegaR[15],omegaR[15:1]} - {omegaL[15],omegaL[15:1]}; 
  endfunction
  
  
  //// Angle of platform is integration of omega_plat ////
  function signed [19:0] theta_plat (input signed [19:0] theta_plat1,input signed [15:0] omega_plat1);
	theta_plat = theta_plat1 + {{11{omega_plat1[15]}},omega_plat1[15:7]} + 
	                           {{12{omega_plat1[15]}},omega_plat1[15:8]} -
	                           {{16{omega_plat1[15]}},omega_plat1[15:12]} -
							   {{17{omega_plat1[15]}},omega_plat1[15:13]};
							 //  {{18{omega_plat1[15]}},omega_plat1[15:14]} -
							 //  {{19{omega_plat1[15]}},omega_plat1[15]};
  endfunction
  
endmodule

///////////////////////////////////////////////////
// Inverse PWM defined below for easy reference //
/////////////////////////////////////////////////
module inverse_PWM11e(clk,rst_n,PWM_sig,duty_out,vld);

  input clk,rst_n;
  input PWM_sig;
  output reg [10:0] duty_out;
  output reg vld;
  
  reg [10:0] pwm_cnt;
  reg [10:0] per_cnt;
  
  //////////////////////////////////////////
  // Count the duty cycle of the PWM_sig //
  ////////////////////////////////////////
  always_ff @(posedge clk, negedge rst_n)
    if (!rst_n)
	  pwm_cnt <= 11'h000;
	else if (&per_cnt)
	  pwm_cnt <= 11'h000;
	else if (PWM_sig)
	  pwm_cnt <= pwm_cnt + 1;
	  
  ///////////////////////////////////////
  // Need to count the PWM period off //
  /////////////////////////////////////
  always_ff @(posedge clk, negedge rst_n)
    if (!rst_n)
	  per_cnt <= 11'h000;
	else
	  per_cnt <= per_cnt + 1;

  ////////////////////////////////////////////////////
  // Buffer pwm_cnt in output register so it holds //
  //////////////////////////////////////////////////  
  always_ff @(posedge clk, negedge rst_n)
    if (!rst_n)
	  duty_out <= 11'h000;
	else if (&per_cnt)
	  duty_out <= pwm_cnt;
	  
  ///////////////////////////////////////
  // Pulse vld when new reading ready //
  /////////////////////////////////////
  always_ff @(posedge clk, negedge rst_n)
    if (!rst_n)
	  vld <= 1'b0;
	else
	  vld <= &per_cnt;
	  
endmodule

  
