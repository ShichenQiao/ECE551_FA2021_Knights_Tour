module inertial_integrator(clk,rst_n,strt_cal,cal_done,vld,rdy,yaw_rt,
                           lftIR,rghtIR,heading,moving);
						   
parameter FAST_SIM = 1;		// used for speeding up simulations.

input clk, rst_n;
input strt_cal;						// goes high to initiate calibration
input vld;							// goes high for 1 clock cycle when new data valid
input signed [15:0] yaw_rt;			// raw gyro rate readings from inert_intf
input lftIR,rghtIR;					// gaurdrail signals (fusion with gyro)
input moving;						// Only integrate yaw when "going"
output logic cal_done;				// asserted when calibration is completed
output reg rdy;
output signed [11:0] heading;

  ////////////////////////////////////////////////////////
  // Internal registers (pipelined for timing reasons) //
  //////////////////////////////////////////////////////
  reg signed [18:0] yaw_comp;			// offset compensated gyro rate
  reg signed [18:0] yaw_scaled;			// yaw_comp scaled by 31/32
  reg vld_ff1,vld_ff2;				// pipe vld to keep synch

  
  /////////////////
  // SM outputs //
  ///////////////
  logic clr_integrator;
  logic clr_smpl_cntr;
  logic en_smpl_cntr;
  logic compensate_offset;
 
  ////////////////////
  // Define States //
  //////////////////
  typedef enum reg[1:0] {IDLE,CALIBRATING,RUNNING} state_t;
  state_t state,nstate;
  
  //////////////////////////////
  // Define needed registers //
  ////////////////////////////
  reg signed [26:0] yaw_int;						// angle integrator
  reg signed [18:0] yaw_off;						// offset registers
  reg [11:0] smpl_cntr;								// 2048 samples for "real thing" (have to count to 2048 inclusive)		
  
  ////////////////////////////
  // Declare internal nets //
  //////////////////////////
  wire signed [12:0] raw_heading;
  wire signed [23:0] prod_rate;		// 31*yaw_comp
  wire enough_smpls;		// assigned based on smpl_cntr & FAST_SIM
  wire signed [18:0] yaw_fusion;
  
  ////////////////////////
  // Infer State Flops //
  //////////////////////
  always_ff @(posedge clk, negedge rst_n)
    if (!rst_n)
	   state <= IDLE;
	 else
	   state <= nstate;
		
  //////////////////////////////////////
  // state transition & output logic //
  ////////////////////////////////////
  always_comb begin
    //////////////////////
	 // Default outputs //
	 ////////////////////
	 cal_done = 0;
	 clr_integrator = 0;
	 clr_smpl_cntr = 0;
	 en_smpl_cntr = 0;
	 compensate_offset = 0;
	 nstate = IDLE;
	 
	 case (state)
	   IDLE : begin
		  if (strt_cal) begin				// if start calibration we:
		    clr_integrator = 1;			// clear the integrators to
			clr_smpl_cntr = 1;				// average 2048 samples and
		    nstate = CALIBRATING;			// enter the calibrating state
		  end else
		    nstate = IDLE;
		end
		CALIBRATING : begin
		  en_smpl_cntr = vld_ff1;			// count valid samples averaged
		  if (enough_smpls) begin			// have 2048 valid samples in offset calcs
		    cal_done = 1;
			clr_integrator = 1;
			nstate = RUNNING;
		  end else
			nstate = CALIBRATING;
		end
		default : begin		// this is same as RUNNING
		  compensate_offset = 1;
		  if (strt_cal) begin				// only exit RUNNING if we get another strt_cal
			 clr_smpl_cntr = 1;
			 clr_integrator = 1;
			 nstate = CALIBRATING;
		  end else
		    nstate = RUNNING;
		end
	 endcase
	 
  end
  
  /////////////////////////////////////////////////////////////////////////
  // During calibration just purly integrate sign extended raw readings //
  // During actual run, we compensate by subtracting offset from raw   //
  //////////////////////////////////////////////////////////////////////
  always_ff @(posedge clk) begin
    yaw_comp <= (compensate_offset) ? {yaw_rt,3'b000}-yaw_off : {{3{yaw_rt[15]}},yaw_rt};
  end
  

  //////////////////////////////////
  // Calibration factor of 31/32 //
  ////////////////////////////////
  assign prod_rate = yaw_comp*$signed(6'h1F);	// mult by 31
  always_ff @(posedge clk)
    if (vld_ff1)
      yaw_scaled <= (compensate_offset) ? prod_rate[23:5] : yaw_comp;		// div by 32

  ///////////////////////////////////////////////////
  // Integrate first 2048 samples to form average //
  // then capture them as offsets to be          //
  // subtracted from remaining samples          //
  ///////////////////////////////////////////////
  always @(posedge clk, negedge rst_n)
    if (!rst_n)
	  smpl_cntr <= 0;
	else if (clr_smpl_cntr)
	  smpl_cntr <= 0;
	else if (en_smpl_cntr)
	  smpl_cntr <= smpl_cntr + 1;
	  
  generate if (FAST_SIM)
    assign enough_smpls = (smpl_cntr==12'h008) ? 1'b1 : 1'b0;
  else
    assign enough_smpls = (smpl_cntr==12'h800) ? 1'b1 : 1'b0;
  endgenerate	
  

  //// now pipeline vld 2X to form rdy ////
  always_ff @(posedge clk, negedge rst_n)
    if (!rst_n) begin
	  vld_ff1 <= 1'b0;
	  vld_ff2 <= 1'b0;
	  rdy <= 1'b0;
	end else begin
      vld_ff1 <= vld;
      vld_ff2 <= vld_ff1;
	  rdy <= vld_ff2;
	end
	
  assign yaw_fusion = (compensate_offset&lftIR&~rghtIR) ? 19'h03000 :
                      (compensate_offset&~lftIR&rghtIR) ? 19'h7D000 :
					  19'h00000;
  
  ///////////////////////////////////////////////////////////////
  // Now infer integrators to form angular position from rate //
  // Also used during calibration to form average for offset //
  ////////////////////////////////////////////////////////////
  always @(posedge clk, negedge rst_n)
    if (!rst_n) begin
	  yaw_int <= 0;
	end else if (clr_integrator) begin
	  yaw_int <= 0;
	end else if ((vld_ff2) && ((!compensate_offset) || (moving))) begin
	  /////////////////////////////////////////////////////////////////
	  // During calibration we use the integrator as accumulators   //
	  // to get an average of 2048 samples of yaw, which is later  //
	  // subtracted from each respective reading during RUN state //
	  /////////////////////////////////////////////////////////////
	  if (FAST_SIM)	// speed up integration by 1.5X 
	    yaw_int  <= yaw_int + {{8{yaw_scaled[18]}},yaw_scaled} + {{9{yaw_scaled[18]}},yaw_scaled[18:1]} +
	                          {{8{yaw_fusion[18]}},yaw_fusion};
      else							
	    yaw_int  <= yaw_int + {{8{yaw_scaled[18]}},yaw_scaled} + 
	                          {{8{yaw_fusion[18]}},yaw_fusion};
	end
	
  always @(posedge clk, negedge rst_n)
    if (!rst_n) begin
	  yaw_off <= 19'h00000;
	end else if (cal_done) begin
	  ///////////////////////////////////////////////////////////////
	  // Our calibrated offset is the average of 2048 samples, so //
	  // we arithmetically shift the integrators down 11-bits.   //
	  // Actually shift a parametized number of bits (short sim)//
	  ///////////////////////////////////////////////////////////
	  if (FAST_SIM) begin
		yaw_off <= yaw_int[21:0];
      end else begin
		yaw_off <= yaw_int[26:8];
	  end
	end

	//////////////////////
	// Divide by 2^15. //
	////////////////////
	assign heading = yaw_int[26:15];

endmodule
