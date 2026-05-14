# =============================================================================
# artix7.xdc  —  Constraints File
# GPU Make | Target: Xilinx Artix-7 (xc7a35t — Basys 3 / Arty A7-35)
#
# Maps top-level ports to physical FPGA pins.
# Adjust pin assignments for your specific board.
# =============================================================================

# --- Clock: 100 MHz onboard oscillator ---
set_property PACKAGE_PIN W5     [get_ports clk]
set_property IOSTANDARD  LVCMOS33 [get_ports clk]
create_clock -period 10.000 -name sys_clk [get_ports clk]

# --- Active-low reset (mapped to pushbutton) ---
set_property PACKAGE_PIN U18    [get_ports rst_n]
set_property IOSTANDARD  LVCMOS33 [get_ports rst_n]

# --- Start signal (mapped to pushbutton BTNL) ---
set_property PACKAGE_PIN W19    [get_ports start]
set_property IOSTANDARD  LVCMOS33 [get_ports start]

# --- Input data: a_in[7:0] → Switches SW7–SW0 ---
set_property PACKAGE_PIN V17    [get_ports {a_in[0]}]
set_property PACKAGE_PIN V16    [get_ports {a_in[1]}]
set_property PACKAGE_PIN W16    [get_ports {a_in[2]}]
set_property PACKAGE_PIN W17    [get_ports {a_in[3]}]
set_property PACKAGE_PIN W15    [get_ports {a_in[4]}]
set_property PACKAGE_PIN V15    [get_ports {a_in[5]}]
set_property PACKAGE_PIN W14    [get_ports {a_in[6]}]
set_property PACKAGE_PIN W13    [get_ports {a_in[7]}]
set_property IOSTANDARD  LVCMOS33 [get_ports {a_in[*]}]

# --- Input data: b_in[7:0] → Switches SW15–SW8 ---
set_property PACKAGE_PIN V2     [get_ports {b_in[0]}]
set_property PACKAGE_PIN T3     [get_ports {b_in[1]}]
set_property PACKAGE_PIN T2     [get_ports {b_in[2]}]
set_property PACKAGE_PIN R3     [get_ports {b_in[3]}]
set_property PACKAGE_PIN W2     [get_ports {b_in[4]}]
set_property PACKAGE_PIN U1     [get_ports {b_in[5]}]
set_property PACKAGE_PIN T1     [get_ports {b_in[6]}]
set_property PACKAGE_PIN R2     [get_ports {b_in[7]}]
set_property IOSTANDARD  LVCMOS33 [get_ports {b_in[*]}]

# --- Output valid (mapped to LED0) ---
set_property PACKAGE_PIN U16    [get_ports output_valid]
set_property IOSTANDARD  LVCMOS33 [get_ports output_valid]

# --- relu_out[3:0] → LEDs 1–4 (lower nibble indicator) ---
set_property PACKAGE_PIN E19    [get_ports {relu_out[0]}]
set_property PACKAGE_PIN U19    [get_ports {relu_out[1]}]
set_property PACKAGE_PIN V19    [get_ports {relu_out[2]}]
set_property PACKAGE_PIN W18    [get_ports {relu_out[3]}]
set_property IOSTANDARD  LVCMOS33 [get_ports {relu_out[*]}]

# --- Timing: false paths on async inputs ---
set_false_path -from [get_ports rst_n]
set_false_path -from [get_ports start]
set_false_path -from [get_ports {a_in[*]}]
set_false_path -from [get_ports {b_in[*]}]
