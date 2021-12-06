# ECE551_FA2021_Knight-s_Tours
Final project repo of ECE551 in Fall 2021 at UW Madison. <br />
Owned by Team Doraemon: Shichen (Justin) Qiao, Xin Su, Wenfei Huang, and Kailun Teng. <br />

Note: targeting area: 14052(Tommy), 16242(Eric) <br />
Note: Changed xx and yy in KnightsPhysics.sv to type logic. Changed cal_done, lftIR, cntrIR, rghtIR, and start_tour in KnightsTour.sv to type logic. Both for pre-synthesis testing purposes. <br />
Note: Remember to TURN OFF FASTSIM in provided_files/KnightsTour.sv to 0 before synthesis. <br />
Note: Remember to ADD `timescale 1ns/1ps to all v, sv, and vg files involved in post synthesis validation. <br />
Note: Only do rst and cal for post synthesis validation in project demo. <br />

# Journals: <br />
11/29/2021, 11PM: Created repo, pploaded all DUT files, unit tests, and provided files. <br />
11/30/2021, 10AM: Uploaded synthesis script. <br />
11/30/2021, 4PM: Uploaded 1st synthesis results, min delay violated, max delay met, area 15861. <br />
11/30/2021, 4PM: Fixed rst_synch module name, fixed TourLogic not synthsizable issue. <br />
11/30/2021, 4PM: Reduced visited in TourLogic to 2D array of 1-bit booleans <br />
11/30/2021, 10PM: Reorganized the repo, made 2nd synthesis, now there is not Error/Warnings, min_delay violated (but passed), max_delay violated (-0.36), and Area = 17919.44 <br />
12/3/2021, 11PM: Updated PID pipelined DUT, met max & min delay, area = 16924.28. Problem: under the current test, waveform have unexpected pulses and sharp drops after going north by 2, going left by 1, and trying to go south by 2. Solution: no solution yet, Eric is working on it. Next steps: implement more comprehensive full chip tests, design structured pre/post -synthesis test suites, and improve TourLogic. (Tommy reduced area by 2800 just by optimizing TourLogic.) <br />
12/4/2021, 1AM: Optimized TourLogic, uploaded latest DUT and synthesis results, met max & min delay, area = 13788.55. Testing needed. current KnightsPhysics is still old.
12/5/2021, 11AM: Uploaded all full chip tests, updated TourCmd to travel hori first vert second. Note: some variables/ports in KnightsPhysics or in KnightsTour was changed to type logic to support testing.
12/5/2021, 10PM: Uploaded final synthesis results, pre-synthesis tests and results, and post-synthesis validation results. Area = 13944.14, timings are met. One last step before demo: code coverage.
