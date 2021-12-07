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

# File Directories
```bash
ECE551_FA2021_Knights_Tour-main
├── EX21_cmd_proc__charge.pdf
├── Ex23_KnightsTour.pdf
├── ProjectSpec.pdf
├── README.md
├── TopLevelTestingSynthesis.pdf
├── backups
│   ├── 1st_synth
│   │   ├── ……
│   ├── 2nd_synth
│   │   ├── ……
│   ├── 3rd_synth_PID_pipe
│   │   ├── ……
│   ├── 4th_synth_optimized
│   │   ├── ……
│   ├── 5th_synth_pretested
│   │   ├── ……
│   ├── KnightPhysics_need_eric.sv
│   ├── KnightPhysics_old.sv
│   ├── PID_nopipe.sv
│   ├── PID_pipe_P.sv
│   ├── PID_tb_nopipe.sv
│   ├── TourCmd_tb_vert.sv
│   ├── TourCmd_vert.sv
│   ├── TourLogic_debug.sv
│   ├── TourLogic_record_possibles.sv
│   └── test_suite_coverages.zip
├── code_coverage
│   ├── DUT_coverage.zip
│   ├── ModelsimTutorial_s21.pdf
│   ├── improved_DUT_coverage.zip
│   ├── test_suite
│   │   ├── Test1_rst&cal.sv
│   │   ├── Test2_simple_moves.sv
│   │   ├── Test3_simple_fanfare.sv
│   │   ├── Test4_corner_turns.sv
│   │   ├── Test5_tour_with_fanfare.sv
│   │   ├── Test6_resp.sv
│   │   ├── Test7_all_possible_TL.sv
│   │   ├── Test8_tour_from_center.sv
│   │   └── tb_tasks.sv
│   └── test_suite_improved
│       ├── Test1_rst&cal.sv
│       ├── ……
│       ├── Test8_tour_from_center.sv
│       ├── Test9_invalid_opcodes_added_after_coverage
│       │   ├── Test9_console.jpg
│       │   ├── Test9_invalid_opcodes.sv
│       │   └── Test9_waves.jpg
│       └── tb_tasks.sv
├── lib
│   ├── ……
├── post_synth_validation
│   ├── KnightPhysics.sv
│   ├── KnightsTour.vg
│   ├── KnightsTour_tb.sv
│   ├── RemoteComm.sv
│   ├── SPI_iNEMO4.sv
│   ├── UART.v
│   ├── UART_rx.sv
│   ├── UART_tx.sv
│   ├── console.jpg
│   ├── post_synth.cr.mti
│   ├── post_synth.mpf
│   ├── tb_tasks.sv
│   ├── transcript
│   ├── vsim.wlf
│   ├── waves.jpg
│   └── work
│       ├── ……
├── pre_synth_simulation
│   ├── Test1_console.jpg
│   ├── Test1_waves.jpg
│   ├── ……
│   ├── Test8_console.txt
│   └── Test8_waves.jpg
├── provided_files
│   ├── IR_intf.sv
│   ├── KnightPhysics.sv
│   ├── KnightsTour.sv
│   ├── SPI_iNEMO4.sv
│   └── inertial_integrator.sv
├── src
│   ├── MtrDrv.sv
│   ├── PID.sv
│   ├── PWM11.sv
│   ├── SPI_mnrch.sv
│   ├── TourCmd.sv
│   ├── TourLogic.sv
│   ├── UART.v
│   ├── UART_rx.sv
│   ├── UART_tx.sv
│   ├── UART_wrapper.sv
│   ├── charge.sv
│   ├── cmd_proc.sv
│   ├── inert_intf.sv
│   └── reset_synch.sv
├── synthesis
│   ├── KnightsTour.dc
│   ├── KnightsTour.vg
│   ├── KnightsTour_area.txt
│   ├── KnightsTour_max_delay.rpt
│   ├── KnightsTour_min_delay.rpt
│   ├── ……
└── tests
    ├── KnightsTour_tb_shell.sv
    ├── RemoteComm.sv
    ├── Unit_tests
    │   ├── CommTB.sv
    │   ├── MtrDrv_tb.sv
    │   ├── PID_tb.sv
    │   ├── PWM11_tb.sv
    │   ├── SPI_mnrch_tb.sv
    │   ├── TourCmd_tb.sv
    │   ├── TourLogic_tb.sv
    │   ├── UART_tb.sv
    │   ├── UART_tx_tb.sv
    │   ├── charge_modelsim_tb.sv
    │   ├── cmd_proc_tb.sv
    │   └── inert_intf_tb.sv
    ├── full_ship_tests
    │   ├── Test1_rst&cal
    │   │   └── KnightsTour_tb.sv
    │   ├── Test2_simple_moves
    │   │   └── KnightsTour_tb.sv
    │   ├── Test3_simple_fanfare
    │   │   └── KnightsTour_tb.sv
    │   ├── Test4_corner_turns
    │   │   └── KnightsTour_tb.sv
    │   ├── Test5_tour_with_fanfare
    │   │   └── KnightsTour_tb.sv
    │   ├── Test6_resp
    │   │   └── KnightsTour_tb.sv
    │   ├── Test7_all_possible_TL
    │   │   └── KnightsTour_tb.sv
    │   ├── Test8_tour_from_center
    │   │   ├── KnightsTour_tb.sv
    │   │   ├── hori_first.txt
    │   │   ├── tour_from_center.jpg
    │   │   └── vert_first.txt
    │   └── Test9_invalid_opcodes_added_after_coverage
    │       ├── KnightsTour_tb.sv
    │       ├── Test9_console.jpg
    │       └── Test9_invalid_opcodes.jpg
    └── tb_tasks.sv

33 directories, 538 files
```

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
