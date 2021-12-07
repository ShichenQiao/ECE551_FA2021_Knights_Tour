# ECE551_FA2021_Knight-s_Tours
Final project repo of ECE551 in Fall 2021 at UW Madison. <br />
Owned by Team Doraemon: Shichen (Justin) Qiao, Xin Su, Wenfei Huang, and Kailun Teng. <br />

# Project Statistics
Total Area: 13944.14 <br />
Min Delay Slack: 0.00 (MET) <br />
Max Delay Slack: 0.35 (MET) <br />
Test Suite Code Coverage: 97.41% <br />

# Important Notes
Targeting area: 14052(Tommy), 16242(Eric) <br />
Changed xx and yy in KnightsPhysics.sv to type logic. Changed cal_done, lftIR, cntrIR, rghtIR, and start_tour in KnightsTour.sv to type logic. Both for pre-synthesis testing purposes. <br />
Remember to TURN OFF FASTSIM in provided_files/KnightsTour.sv to 0 before synthesis. <br />
Remember to ADD `timescale 1ns/1ps to all v, sv, and vg files involved in post synthesis validation. <br />
Only do rst and cal for post synthesis validation in project demo. <br />
Project Demo Date/Time: Fri. 12/10/2021 4PM <br />
ECE551_FA2021_Knights_Tour-main <br />
├── EX21_cmd_proc__charge.pdf <br />
├── Ex23_KnightsTour.pdf <br />
├── ProjectSpec.pdf <br />
├── README.md <br />
├── TopLevelTestingSynthesis.pdf <br />
├── backups <br />
│   ├── 1st_synth <br />
│   │   ├── …… <br />
│   ├── 2nd_synth <br />
│   │   ├── …… <br />
│   ├── 3rd_synth_PID_pipe <br />
│   │   ├── …… <br />
│   ├── 4th_synth_optimized <br />
│   │   ├── …… <br />
│   ├── 5th_synth_pretested <br />
│   │   ├── …… <br />
│   ├── KnightPhysics_need_eric.sv <br />
│   ├── KnightPhysics_old.sv <br />
│   ├── PID_nopipe.sv <br />
│   ├── PID_pipe_P.sv <br />
│   ├── PID_tb_nopipe.sv <br />
│   ├── TourCmd_tb_vert.sv <br />
│   ├── TourCmd_vert.sv <br />
│   ├── TourLogic_debug.sv <br />
│   ├── TourLogic_record_possibles.sv <br />
│   └── test_suite_coverages.zip <br />
├── code_coverage <br />
│   ├── DUT_coverage.zip <br />
│   ├── ModelsimTutorial_s21.pdf <br />
│   ├── improved_DUT_coverage.zip <br />
│   ├── test_suite <br />
│   │   ├── Test1_rst&cal.sv <br />
│   │   ├── Test2_simple_moves.sv <br />
│   │   ├── Test3_simple_fanfare.sv <br />
│   │   ├── Test4_corner_turns.sv <br />
│   │   ├── Test5_tour_with_fanfare.sv <br />
│   │   ├── Test6_resp.sv <br />
│   │   ├── Test7_all_possible_TL.sv <br />
│   │   ├── Test8_tour_from_center.sv <br />
│   │   └── tb_tasks.sv <br />
│   └── test_suite_improved <br />
│       ├── Test1_rst&cal.sv <br />
│       ├── …… <br />
│       ├── Test8_tour_from_center.sv <br />
│       ├── Test9_invalid_opcodes_added_after_coverage <br />
│       │   ├── Test9_console.jpg <br />
│       │   ├── Test9_invalid_opcodes.sv <br />
│       │   └── Test9_waves.jpg <br />
│       └── tb_tasks.sv <br />
├── lib <br />
│   ├── …… <br />
├── post_synth_validation <br />
│   ├── KnightPhysics.sv <br />
│   ├── KnightsTour.vg <br />
│   ├── KnightsTour_tb.sv <br />
│   ├── RemoteComm.sv <br />
│   ├── SPI_iNEMO4.sv <br />
│   ├── UART.v <br />
│   ├── UART_rx.sv <br />
│   ├── UART_tx.sv <br />
│   ├── console.jpg <br />
│   ├── post_synth.cr.mti <br />
│   ├── post_synth.mpf <br />
│   ├── tb_tasks.sv <br />
│   ├── transcript <br />
│   ├── vsim.wlf <br />
│   ├── waves.jpg <br />
│   └── work <br />
│       ├── …… <br />
├── pre_synth_simulation <br />
│   ├── Test1_console.jpg <br />
│   ├── Test1_waves.jpg <br />
│   ├── …… <br />
│   ├── Test8_console.txt <br />
│   └── Test8_waves.jpg <br />
├── provided_files <br />
│   ├── IR_intf.sv <br />
│   ├── KnightPhysics.sv <br />
│   ├── KnightsTour.sv <br />
│   ├── SPI_iNEMO4.sv <br />
│   └── inertial_integrator.sv <br />
├── src <br />
│   ├── MtrDrv.sv <br />
│   ├── PID.sv <br />
│   ├── PWM11.sv <br />
│   ├── SPI_mnrch.sv <br />
│   ├── TourCmd.sv <br />
│   ├── TourLogic.sv <br />
│   ├── UART.v <br />
│   ├── UART_rx.sv <br />
│   ├── UART_tx.sv <br />
│   ├── UART_wrapper.sv <br />
│   ├── charge.sv <br />
│   ├── cmd_proc.sv <br />
│   ├── inert_intf.sv <br />
│   └── reset_synch.sv <br />
├── synthesis <br />
│   ├── KnightsTour.dc <br />
│   ├── KnightsTour.vg <br />
│   ├── KnightsTour_area.txt <br />
│   ├── KnightsTour_max_delay.rpt <br />
│   ├── KnightsTour_min_delay.rpt <br />
│   ├── …… <br />
└── tests <br />
├── KnightsTour_tb_shell.sv <br />
├── RemoteComm.sv <br />
├── Unit_tests <br />
│   ├── CommTB.sv <br />
│   ├── MtrDrv_tb.sv <br />
│   ├── PID_tb.sv <br />
│   ├── PWM11_tb.sv <br />
│   ├── SPI_mnrch_tb.sv <br />
│   ├── TourCmd_tb.sv <br />
│   ├── TourLogic_tb.sv <br />
│   ├── UART_tb.sv <br />
│   ├── UART_tx_tb.sv <br />
│   ├── charge_modelsim_tb.sv <br />
│   ├── cmd_proc_tb.sv <br />
│   └── inert_intf_tb.sv <br />
├── full_ship_tests <br />
│   ├── Test1_rst&cal <br />
│   │   └── KnightsTour_tb.sv <br />
│   ├── Test2_simple_moves <br />
│   │   └── KnightsTour_tb.sv <br />
│   ├── Test3_simple_fanfare <br />
│   │   └── KnightsTour_tb.sv <br />
│   ├── Test4_corner_turns <br />
│   │   └── KnightsTour_tb.sv <br />
│   ├── Test5_tour_with_fanfare <br />
│   │   └── KnightsTour_tb.sv <br />
│   ├── Test6_resp <br />
│   │   └── KnightsTour_tb.sv <br />
│   ├── Test7_all_possible_TL <br />
│   │   └── KnightsTour_tb.sv <br />
│   ├── Test8_tour_from_center <br />
│   │   ├── KnightsTour_tb.sv <br />
│   │   ├── hori_first.txt <br />
│   │   ├── tour_from_center.jpg <br />
│   │   └── vert_first.txt <br />
│   └── Test9_invalid_opcodes_added_after_coverage <br />
│       ├── KnightsTour_tb.sv <br />
│       ├── Test9_console.jpg <br />
│       └── Test9_invalid_opcodes.jpg <br />
└── tb_tasks.sv <br />

33 directories, 538 files <br />

# Journals: <br />
11/29/2021, 11PM: Created repo, pploaded all DUT files, unit tests, and provided files. <br />
11/30/2021, 10AM: Uploaded synthesis script. <br />
11/30/2021, 4PM: Uploaded 1st synthesis results, min delay violated, max delay met, area 15861. <br />
11/30/2021, 4PM: Fixed rst_synch module name, fixed TourLogic not synthsizable issue. <br />
11/30/2021, 4PM: Reduced visited in TourLogic to 2D array of 1-bit booleans <br />
11/30/2021, 10PM: Reorganized the repo, made 2nd synthesis, now there is not Error/Warnings, min_delay violated (but passed), max_delay violated (-0.36), and Area = 17919.44 <br />
12/3/2021, 11PM: Updated PID pipelined DUT, met max & min delay, area = 16924.28. Problem: under the current test, waveform have unexpected pulses and sharp drops after going north by 2, going left by 1, and trying to go south by 2. Solution: no solution yet, Eric is working on it. Next steps: implement more comprehensive full chip tests, design structured pre/post -synthesis test suites, and improve TourLogic. (Tommy reduced area by 2800 just by optimizing TourLogic.) <br />
12/4/2021, 1AM: Optimized TourLogic, uploaded latest DUT and synthesis results, met max & min delay, area = 13788.55. Testing needed. current KnightsPhysics is still old. <br />
12/5/2021, 11AM: Uploaded all full chip tests, updated TourCmd to travel hori first vert second. Note: some variables/ports in KnightsPhysics or in KnightsTour was changed to type logic to support testing. <br />
12/5/2021, 10PM: Uploaded final synthesis results, pre-synthesis tests and results, and post-synthesis validation results. Area = 13944.14, timings are met. One last step before demo: code coverage. <br />
12/6/2021: 11PM: Finalized project. Conducted code coverage. Original test suite coverage: 96.98%. Improved by adding Test9_invalid_opcodes. Current coverage: 97.41%
