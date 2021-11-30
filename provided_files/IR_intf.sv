module IR_intf(clk,rst_n,lftIR_n,cntrIR_n,rghtIR_n,IR_en,lftIR,rghtIR,cntrIR);
 
  parameter FAST_SIM = 1;		// used for speeding up simulations.  8X faster
  
  input clk, rst_n;
  input lftIR_n,cntrIR_n,rghtIR_n;	// raw inputs from IR sensors
  output IR_en;						// from 3-bit PWM (8 possible intensity settings)
  output reg lftIR,cntrIR,rghtIR;	// captured IR readings (updated every 2.6ms)
  
  localparam PWM_duty = 3'b101;		// 62.5% for now
  
  reg [16:0] smpl_tmr;						// sample once every ~2.6ms
  reg lftIR_FF1, cntrIR_FF1, rghtIR_FF1;	// flops for meta-stability
  reg cntrIR_FF2;								// rise edge detect to clear blanking timer.
  reg smpl_IRs_FF1;							// delayed version of smpl_IRs for sampling meta flops
  reg [22:0] blanking_timer;				// once there is a rise on center, don't sample for 0.167sec
  
  logic IR_on, smpl_IRs;					// decodes of timer
  
  wire [2:0] duty;
  wire blankover, cntr_rise;
  
  //////////////////////////////////////////
  // Infer period timer (always running) //
  ////////////////////////////////////////
  always_ff @(posedge clk, negedge rst_n)
    if (!rst_n)
	  smpl_tmr <= 17'h00000;
	else
	  smpl_tmr <= smpl_tmr + 1;
	
  generate if (FAST_SIM) begin
    assign IR_on = (smpl_tmr[13:10]==4'h0) ? 1'b1 : 1'b0;
    assign smpl_IRs = IR_on & &smpl_tmr[9:0]; 
	assign blankover = &blanking_timer[16:0];
  end else begin
    assign IR_on = (smpl_tmr[16:13]==4'h0) ? 1'b1 : 1'b0;
    assign smpl_IRs = IR_on & &smpl_tmr[12:0];  
	assign blankover = &blanking_timer;
  end endgenerate
  
  
  
  /////////////////////////////////////////////////////
  // Create delayed sample for meta-stability flops //
  ///////////////////////////////////////////////////
  always_ff @(posedge clk, negedge rst_n)
    if (!rst_n)
	  smpl_IRs_FF1 <= 1'b0;
	else
	  smpl_IRs_FF1 <= smpl_IRs;
	  
  //////////////////////////////////////
  // Infer flops that sample raw IRs //
  ////////////////////////////////////
  always_ff @(posedge clk, negedge rst_n)
    if (!rst_n) begin
	  lftIR_FF1 <= 1'b0;
	  rghtIR_FF1 <= 1'b0;
	end else if (smpl_IRs) begin
	  lftIR_FF1 <= ~lftIR_n;
	  rghtIR_FF1 <= ~rghtIR_n;
	end
	
  ///////////////////////////////////////////////////////
  // Infer flops that sample again for meta-stability //
  /////////////////////////////////////////////////////
  always_ff @(posedge clk, negedge rst_n)
    if (!rst_n) begin
	  lftIR <= 1'b0;
	  rghtIR <= 1'b0;
	end else if (smpl_IRs_FF1) begin
	  lftIR <= lftIR_FF1;
	  rghtIR <= rghtIR_FF1;
	end
	
	///////////////////////////////////////////////////////
	// Infer blanking timer that prevents samples of    //
	// center timer for 0.167 sec after rise of center //
	////////////////////////////////////////////////////
	always_ff @(posedge clk, negedge rst_n)
	  if (!rst_n)
	    blanking_timer <= 23'h000000;
	  else if (cntr_rise)
	    blanking_timer <= 23'h000000;
	  else if (!blankover)
	    blanking_timer <= blanking_timer + 1;
	 
  //////////////////////////////////////
  // Infer flops that sample cntr IR //
  ////////////////////////////////////
  always_ff @(posedge clk, negedge rst_n)
    if (!rst_n) begin
	   cntrIR_FF1 <= 1'b0;
		cntrIR_FF2 <= 1'b0;
    end else if (smpl_IRs) begin
	   cntrIR_FF1 <= ~cntrIR_n;
		cntrIR_FF2 <= cntrIR;
	 end

	
  ///////////////////////////////////////////////////////
  // Infer flops that sample again for meta-stability //
  /////////////////////////////////////////////////////
  always_ff @(posedge clk, negedge rst_n)
    if (!rst_n) 
	   cntrIR <= 1'b0;
    else if (smpl_IRs_FF1 && blankover)
	   cntrIR <= cntrIR_FF1;
		
  assign cntr_rise = cntrIR & ~ cntrIR_FF2;

    assign duty = (IR_on) ? PWM_duty : 3'b000;
  
    //////////////////////////////////////////
    // Instantiate PWM3 which drives IR_en //
    ////////////////////////////////////////
    PWM3 iDUTY(.clk(clk),.rst_n(rst_n),.duty(duty),.PWM_sig(IR_en));
  
 endmodule
 
 
 ////////////////////////////////////////////////
 // Now define PWM3 (used to drive IR emitter //
 //////////////////////////////////////////////
 module PWM3(clk,rst_n,duty,PWM_sig);

  input clk,rst_n;		// clock and active low asynch reset
  input [2:0] duty;	// specifies duty cycle to motor drive
  output reg PWM_sig;
  
  wire set, reset;
  
  reg [2:0] cnt;
  

  
  ///////////////////////////
  // infer 3-bit counter //
  /////////////////////////
  always_ff @(posedge clk, negedge rst_n) 
    if (!rst_n)
	  cnt <= 3'h0;
	else
	  cnt <= cnt + 1;
	  
  assign set = ~|cnt;		// set at zero, but reset has priority
  assign reset = (cnt>=duty) ? 1'b1 : 1'b0;
  
  ////////////////////////////
  // infer PWM output flop //
  //////////////////////////
  always_ff @(posedge clk, negedge rst_n)
    if (!rst_n)
	  PWM_sig <= 1'b0;
	else if (reset)
	  PWM_sig <= 1'b0;
	else if (set)
	  PWM_sig <= 1'b1;
  
endmodule
