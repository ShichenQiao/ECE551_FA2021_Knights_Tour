module KnightsTour(
  input clk, RST_n,						// 50MHz clock and asynch active low reset						// SPI input from A2D
  output SS_n,SCLK,MOSI,	            // outputs of SPI to inertial interface
  input MISO,						    // SPI input from gyro
  input INT,						    // interrupt signals from gyro (new readings ready)
  output lftPWM1,lftPWM2,				// left motor PWM controls
  output rghtPWM1,rghtPWM2,				// right motor PWM controls
  input RX,								// UART input from BLE module
  output TX,							// UART output to BLE module
  output piezo,piezo_n,					// to Piezo buzzer (charge fanfare)
  output IR_en,							// Enable 3 IR sensors (for 500usec once every 10ms)
  input lftIR_n,						// goes low if left IR encounters a rail
  input cntrIR_n,						// goes low when center IR crosses a line
  input rghtIR_n						// goes low if right IR encounters a rail
);
 
  localparam FAST_SIM = 1;				// used to speed up simulation

  ////////////////////////
  // Internals signals //
  //////////////////////
  wire rst_n;							// global synchronized reset
  wire strt_cal;						// initiate gyro heading calibration
  wire cal_done;						// done with gyro heading calibration
  wire signed [10:0] lft_spd, rght_spd;	// signed motor controls
  wire signed [11:0] error;
  wire signed [11:0] heading;
  wire lftIR,cntrIR,rghtIR;				// sampled IR signals
  wire heading_rdy;						// new heading reading is ready
  wire moving;							// clear I in PID and don't integrate yaw if not moving
  wire send_resp;						// send either 0xA5 (done) or 0x5A (in progress)
  wire resp_sent;
  wire cmd_rdy;							// multiplexed cmd_rdy
  wire cmd_rdy_UART;					// cmd ready from UART/Bluetooth  
  wire [9:0] frwrd;						// forward speed
  wire [15:0] cmd;						// multiplexed cmd from TourCmd
  wire [15:0] cmd_UART;					// command from UART/Bluetooth
  wire clr_cmd_rdy;
  wire tour_go;
  wire fanfare_go;
  wire start_tour;						// done from TourLogic
  wire [4:0] mv_indx;					// "address" of tour move
  wire [7:0] move;						// 1-hot encoded Knight move
  wire [7:0] resp;						// either 0xA5 (done), or 0x5A (in progress)
  
  
  /////////////////////////////////////
  // Instantiate reset synchronizer //
  ///////////////////////////////////
  reset_synch iRST(.*);
 
  ///////////////////////////////////////////////////
  // UART_wrapper receives 16-bit command via BLE //
  /////////////////////////////////////////////////
  UART_wrapper iWRAP(.clk(clk), .rst_n(rst_n), .RX(RX), .TX(TX), .resp(resp), 
               .trmt(send_resp), .tx_done(resp_sent),
			   .cmd_rdy(cmd_rdy_UART), .cmd(cmd_UART), .clr_cmd_rdy(clr_cmd_rdy));
		
  ////////////////////////////////////
  // Instantiate command processor //
  //////////////////////////////////  
  cmd_proc #(FAST_SIM) iCMD(.clk(clk),.rst_n(rst_n),.cmd(cmd),.cmd_rdy(cmd_rdy),
           .clr_cmd_rdy(clr_cmd_rdy),.send_resp(send_resp),.strt_cal(strt_cal),
		   .cal_done(cal_done),.heading(heading),.heading_rdy(heading_rdy),.lftIR(lftIR),
		   .cntrIR(cntrIR),.rghtIR(rghtIR),.error(error),.frwrd(frwrd),.moving(moving),
		   .tour_go(tour_go),.fanfare_go(fanfare_go));
	
  ///////////////////////////////////////////////////
  // Instantiate tour logic that solves the moves //
  /////////////////////////////////////////////////  
  TourLogic iTL(.clk(clk),.rst_n(rst_n),.x_start(cmd[6:4]),.y_start(cmd[2:0]),
                .go(tour_go),.done(start_tour),.indx(mv_indx),.move(move));
				
  ///////////////////////////////////////////////////////////////
  // Instantiate tour cmd that translates moves into commands //
  /////////////////////////////////////////////////////////////
  TourCmd iTC(.clk(clk),.rst_n(rst_n),.start_tour(start_tour),.move(move),
              .mv_indx(mv_indx),.cmd(cmd),.cmd_UART(cmd_UART),.cmd_rdy(cmd_rdy),
			  .cmd_rdy_UART(cmd_rdy_UART),.clr_cmd_rdy(clr_cmd_rdy),
			  .send_resp(send_resp), .resp(resp));				
 
  /////////////////////////////////////
  // Instantiate inertial interface //
  ///////////////////////////////////
  inert_intf #(FAST_SIM) iNEMO(.clk(clk),.rst_n(rst_n),.strt_cal(strt_cal),
             .cal_done(cal_done),.heading(heading),.rdy(heading_rdy),.lftIR(lftIR),
			 .rghtIR(rghtIR),.SS_n(SS_n),.SCLK(SCLK),.MOSI(MOSI),
			 .MISO(MISO),.INT(INT),.moving(moving));

  /////////////////////////////////
  // Instantiate PID controller //
  ///////////////////////////////			 
  PID iCNTRL(.clk(clk),.rst_n(rst_n),.moving(moving),.err_vld(heading_rdy),.frwrd(frwrd),
             .error(error),.lft_spd(lft_spd),.rght_spd(rght_spd));

  ///////////////////////////////////
  // Instantiate motor PWM driver //
  /////////////////////////////////  
  MtrDrv iMTR(.clk(clk),.rst_n(rst_n),.lft_spd(lft_spd),.rght_spd(rght_spd),
              .lftPWM1(lftPWM1),.lftPWM2(lftPWM2),.rghtPWM1(rghtPWM1),
			  .rghtPWM2(rghtPWM2));
			   
  /////////////////////////////////////////////////////
  // Instantiate block to interface with IR sensors //
  /////////////////////////////////////////////////// 					 
  IR_intf #(FAST_SIM) iIR(.clk(clk),.rst_n(rst_n),.lftIR_n(lftIR_n),.cntrIR_n(cntrIR_n),
                          .rghtIR_n(rghtIR_n),.IR_en(IR_en),.lftIR(lftIR),
						  .rghtIR(rghtIR),.cntrIR(cntrIR));
			  
  /////////////////////////////////////////
  // Instantiate "Charge!" fanfare unit //
  ///////////////////////////////////////
  charge #(FAST_SIM) ICHRG(.clk(clk),.rst_n(rst_n),.go(fanfare_go),.piezo(piezo),.piezo_n(piezo_n));
  
	  
endmodule