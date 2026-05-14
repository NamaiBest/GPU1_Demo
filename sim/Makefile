# =============================================================================
# Makefile — Icarus Verilog simulation
# GPU Make | Usage: make sim   /   make wave   /   make clean
# =============================================================================

IVERILOG = iverilog
VVP      = vvp
GTKWAVE  = gtkwave

RTL_DIR  = ../rtl
SIM_DIR  = .

SRCS     = $(RTL_DIR)/core_mac.v \
           $(RTL_DIR)/core_relu.v \
           $(RTL_DIR)/top.v \
           $(SIM_DIR)/tb_top.v

OUT      = sim_out

.PHONY: sim wave clean

## Compile and run simulation
sim: $(OUT)
	$(VVP) $(OUT)

$(OUT): $(SRCS)
	$(IVERILOG) -g2012 -Wall -o $(OUT) $(SRCS)

## Open waveform in GTKWave (requires GTKWave installed)
wave: sim
	$(GTKWAVE) dump.vcd &

## Remove build artifacts
clean:
	rm -f $(OUT) dump.vcd
