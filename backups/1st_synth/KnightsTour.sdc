###################################################################

# Created by write_sdc on Tue Nov 30 14:54:32 2021

###################################################################
set sdc_version 2.1

set_units -time ns -resistance MOhm -capacitance fF -voltage V -current uA
set_wire_load_model -name 16000 -library saed32lvt_tt0p85v25c
set_max_transition 0.15 [current_design]
set_driving_cell -lib_cell NAND2X2_LVT -library saed32lvt_tt0p85v25c           \
[get_ports RST_n]
set_driving_cell -lib_cell NAND2X2_LVT -library saed32lvt_tt0p85v25c           \
[get_ports MISO]
set_driving_cell -lib_cell NAND2X2_LVT -library saed32lvt_tt0p85v25c           \
[get_ports INT]
set_driving_cell -lib_cell NAND2X2_LVT -library saed32lvt_tt0p85v25c           \
[get_ports RX]
set_driving_cell -lib_cell NAND2X2_LVT -library saed32lvt_tt0p85v25c           \
[get_ports TX]
set_driving_cell -lib_cell NAND2X2_LVT -library saed32lvt_tt0p85v25c           \
[get_ports lftIR_n]
set_driving_cell -lib_cell NAND2X2_LVT -library saed32lvt_tt0p85v25c           \
[get_ports cntrIR_n]
set_driving_cell -lib_cell NAND2X2_LVT -library saed32lvt_tt0p85v25c           \
[get_ports rghtIR_n]
set_load -pin_load 0.1 [get_ports SS_n]
set_load -pin_load 0.1 [get_ports SCLK]
set_load -pin_load 0.1 [get_ports MOSI]
set_load -pin_load 0.1 [get_ports lftPWM1]
set_load -pin_load 0.1 [get_ports lftPWM2]
set_load -pin_load 0.1 [get_ports rghtPWM1]
set_load -pin_load 0.1 [get_ports rghtPWM2]
set_load -pin_load 0.1 [get_ports piezo]
set_load -pin_load 0.1 [get_ports piezo_n]
set_load -pin_load 0.1 [get_ports IR_en]
create_clock [get_ports clk]  -period 3  -waveform {0 1.5}
set_clock_uncertainty 0.15  [get_clocks clk]
set_input_delay -clock clk  0.4  [get_ports RST_n]
set_input_delay -clock clk  0.4  [get_ports MISO]
set_input_delay -clock clk  0.4  [get_ports INT]
set_input_delay -clock clk  0.4  [get_ports RX]
set_input_delay -clock clk  0.4  [get_ports TX]
set_input_delay -clock clk  0.4  [get_ports lftIR_n]
set_input_delay -clock clk  0.4  [get_ports cntrIR_n]
set_input_delay -clock clk  0.4  [get_ports rghtIR_n]
set_output_delay -clock clk  0.4  [get_ports SS_n]
set_output_delay -clock clk  0.4  [get_ports SCLK]
set_output_delay -clock clk  0.4  [get_ports MOSI]
set_output_delay -clock clk  0.4  [get_ports lftPWM1]
set_output_delay -clock clk  0.4  [get_ports lftPWM2]
set_output_delay -clock clk  0.4  [get_ports rghtPWM1]
set_output_delay -clock clk  0.4  [get_ports rghtPWM2]
set_output_delay -clock clk  0.4  [get_ports piezo]
set_output_delay -clock clk  0.4  [get_ports piezo_n]
set_output_delay -clock clk  0.4  [get_ports IR_en]
