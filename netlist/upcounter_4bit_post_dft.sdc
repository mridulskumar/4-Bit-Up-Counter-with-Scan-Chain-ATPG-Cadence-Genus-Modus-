# ####################################################################

#  Created by Genus(TM) Synthesis Solution 20.11-s111_1 on Thu Apr 16 13:44:17 IST 2026

# ####################################################################

set sdc_version 2.0

set_units -capacitance 1000fF
set_units -time 1000ps

# Set the current design
current_design upcounter_4bit

create_clock -name "clk" -period 20.0 -waveform {0.0 10.0} [get_ports clk]
set_clock_transition 0.2 [get_clocks clk]
set_load -pin_load 0.05 [get_ports scan_out]
set_load -pin_load 0.05 [get_ports {count[3]}]
set_load -pin_load 0.05 [get_ports {count[2]}]
set_load -pin_load 0.05 [get_ports {count[1]}]
set_load -pin_load 0.05 [get_ports {count[0]}]
set_false_path -from [list \
  [get_ports scan_en]  \
  [get_ports scan_in] ]
set_false_path -to [get_ports scan_out]
set_clock_gating_check -setup 0.0 
set_input_delay -clock [get_clocks clk] -add_delay 5.0 [get_ports reset]
set_input_delay -clock [get_clocks clk] -add_delay 5.0 [get_ports enable]
set_input_delay -clock [get_clocks clk] -add_delay 5.0 [get_ports test_mode]
set_output_delay -clock [get_clocks clk] -add_delay 5.0 [get_ports {count[3]}]
set_output_delay -clock [get_clocks clk] -add_delay 5.0 [get_ports {count[2]}]
set_output_delay -clock [get_clocks clk] -add_delay 5.0 [get_ports {count[1]}]
set_output_delay -clock [get_clocks clk] -add_delay 5.0 [get_ports {count[0]}]
set_max_fanout 20.000 [current_design]
set_max_transition 0.5 [current_design]
set_max_leakage_power 0.0
set_max_dynamic_power 0.0
set_wire_load_mode "enclosed"
set_clock_uncertainty -setup 0.5 [get_clocks clk]
set_clock_uncertainty -hold 0.5 [get_clocks clk]
