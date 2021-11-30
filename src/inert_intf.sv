//////////////////////////////////////////////////////
// Interfaces with ST 6-axis inertial sensor.  In  //
// this application we only use Z-axis gyro for   //
// heading of robot.  Fusion correction comes    //
// from "gaurdrail" signals lftIR/rghtIR.       //
/////////////////////////////////////////////////
module inert_intf(clk,rst_n,strt_cal,cal_done,heading,rdy,lftIR,
                  rghtIR,SS_n,SCLK,MOSI,MISO,INT,moving);

	parameter FAST_SIM = 1;				// used to speed up simulation

	input clk, rst_n;
	input MISO;							// SPI input from inertial sensor
	input INT;							// goes high when measurement ready
	input strt_cal;						// initiate claibration of yaw readings
	input moving;						// Only integrate yaw when going
	input lftIR,rghtIR;					// gaurdrail sensors

	output cal_done;					// pulses high for 1 clock when calibration done
	output signed [11:0] heading;		// heading of robot.  000 = Orig dir 3FF = 90 CCW 7FF = 180 CCW
	output rdy;							// goes high for 1 clock when new outputs ready (from inertial_integrator)
	output SS_n,SCLK,MOSI;				// SPI outputs


	////////////////////////////////////////////
	// Declare any needed internal registers //
	//////////////////////////////////////////
	logic [7:0]yawL, yawH;				// holding registers
	logic [15:0]timer;					// 16-bit timer
	logic INT_ff1, INT_ff2;				// double flop of INT

	//////////////////////////////////////////////
	// Declare outputs of SM are of type logic //
	////////////////////////////////////////////
	logic wrt;							// wrt signal to SPI_mnrch to start a new SPI transaction
	logic [15:0]cmd;					// cmd being sent from SPI_mnrch
	logic C_Y_H, C_Y_L;					// enable signals to registers yawH and yawL
	logic vld;							// flag signal to inertial_integrator indicating yaw_rt is valid
	
	//////////////////////////////////////////////////////////////
	// Declare any needed internal signals that connect blocks //
	////////////////////////////////////////////////////////////
	logic signed [15:0] yaw_rt;			// feeds inertial_integrator
	logic done;							// done sig from SPI_mnrch
	logic [15:0]inert_data;				// rd_data from SPI_mnrch

	///////////////////////////////////////
	// Create enumerated type for state //
	/////////////////////////////////////
	typedef enum logic [2:0] {INIT1, INIT2, INIT3, WAIT_INIT, WAIT_INT, READ_LOW, READ_HIGH, DONE} state_t;
	state_t state, nxt_state;

	////////////////////////////////////////////////////////////
	// Instantiate SPI monarch for Inertial Sensor interface //
	//////////////////////////////////////////////////////////
	SPI_mnrch iSPI(.clk(clk),.rst_n(rst_n),.SS_n(SS_n),.SCLK(SCLK),
				 .MISO(MISO),.MOSI(MOSI),.wrt(wrt),.done(done),
				 .rd_data(inert_data),.wt_data(cmd));
				  
	////////////////////////////////////////////////////////////////////
	// Instantiate Angle Engine that takes in angular rate readings  //
	// and acceleration info and produces a heading reading         //
	/////////////////////////////////////////////////////////////////
	inertial_integrator #(FAST_SIM) iINT(.clk(clk),.rst_n(rst_n),.strt_cal(strt_cal),.vld(vld),
						   .rdy(rdy),.cal_done(cal_done),.yaw_rt(yaw_rt),.moving(moving),.lftIR(lftIR),
						   .rghtIR(rghtIR),.heading(heading));
										   
	//////////////////////////////////////////////
	// 16-bit timer used during initialization //
	////////////////////////////////////////////
	always_ff @(posedge clk, negedge rst_n)
		if(!rst_n)
			timer <=16'h0000;
		else
			timer <= timer + 1;
			
	//////////////////////
	// Double flop INT //
	////////////////////
	always_ff @(posedge clk) begin
		INT_ff1 <= INT;
		INT_ff2 <= INT_ff1;
	end
	
	/////////////////////
	// Hold registers //
	///////////////////
	always_ff @(posedge clk)
		if(C_Y_L)
			yawL <= inert_data[7:0];
	always_ff @(posedge clk)
		if(C_Y_H)
			yawH <= inert_data[7:0];
	assign yaw_rt = {yawH, yawL};

	////////////////////
	// State Machine //
	//////////////////
	always_ff @(posedge clk, negedge rst_n)
		if(!rst_n)
			state = INIT1;
		else
			state = nxt_state;
			
	always_comb begin
		// default all SM outputs to prevent unintended latches
		wrt = 0;
		cmd = 16'h0000;
		C_Y_H = 0;
		C_Y_L = 0;
		vld = 0;
		nxt_state = state;
		
		case(state)
			INIT2: begin
				cmd = 16'h1160;					// setup gyro for 416Hz data rate, +/- 250°/sec range
				if(done) begin					// when previous SPI transaction is finished
					wrt = 1;
					nxt_state = INIT3;
				end
			end
			INIT3: begin
				cmd = 16'h1440;					// turn rounding on for gyro readings
				if(done) begin					// when previous SPI transaction is finished
					wrt = 1;
					nxt_state = WAIT_INIT;
				end
			end
			WAIT_INIT:
				if(done)						// when previous SPI transaction is finished, go to the work states
					nxt_state = WAIT_INT;
			WAIT_INT: begin
				cmd = 16'hA600;					// send command to read yawL
				if(INT_ff2 == 1) begin			// wait until INT_ff2 is asserted to read new yaw values
					wrt = 1;
					nxt_state = READ_LOW;
				end
			end
			READ_LOW: begin
				cmd = 16'hA700;					// send command to read yawH
				if(done) begin					// when yawL is ready on rd_data
					C_Y_L = 1;					// capture yawL
					wrt = 1;
					nxt_state = READ_HIGH;
				end
			end
			READ_HIGH:
				if(done) begin					// when yawH is ready on rd_data
					C_Y_H = 1;					// capture yawH
					nxt_state = DONE;
				end
			DONE: begin
				vld = 1;						// tell inertial_integrator that yaw_rt is valid
				nxt_state = WAIT_INT;			// go back to wait for another INT
			end
			default: begin			// is INIT1
				cmd = 16'h0D02;					// enable interrupt upon data ready
				if(&timer) begin				// begin initialization when the 16-bit timer expires
					wrt = 1;
					nxt_state = INIT2;
				end
			end
		endcase
	end
	
endmodule
	  