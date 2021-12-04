# ECE551_FA2021_Knight-s_Tours
Final project repo of ECE551 in Fall 2021 at UW Madison. <br />
Owned by Team Doraemon: Shichen (Justin) Qiao, Xin Su, Wenfei Huang, and Kailun Teng. <br />

Note: targeting area: 14052(Tommy), 16242(Eric)

# Journals: <br />
11/29/2021, 11PM: Created repo, pploaded all DUT files, unit tests, and provided files. <br />
11/30/2021, 10AM: Uploaded synthesis script. <br />
11/30/2021, 4PM: Uploaded 1st synthesis results, min delay violated, max delay met, area 15861. <br />
11/30/2021, 4PM: Fixed rst_synch module name, fixed TourLogic not synthsizable issue. <br />
11/30/2021, 4PM: Reduced visited in TourLogic to 2D array of 1-bit booleans <br />
11/30/2021, 10PM: Reorganized the repo, made 2nd synthesis, now there is not Error/Warnings, min_delay violated (but passed), max_delay violated (-0.36), and Area = 17919.44 <br />
3/12/2021, 11PM: Updated PID pipelined DUT, met max & min delay, area = 16924.28. Problem: under the current test, waveform have unexpected pulses and sharp drops after going north by 2, going left by 1, and trying to go south by 2. Solution: no solution yet, Eric is working on it. Next steps: implement more comprehensive full chip tests, design structured pre/post -synthesis test suites, and improve TourLogic. (Tommy reduced area by 2800 just by optimizing TourLogic.) <br />
