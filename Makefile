BOARD=tangnano9k
FAMILY=GW1N-9C
DEVICE=GW1NR-LV9QN88PC6/I5

all: Verilog-SHA256.fs

# Synthesis
Verilog-SHA256.json: main.v
	yosys -p "read_verilog main.v; synth_gowin -top main -json Verilog-SHA256.json"

# Place and Route
Verilog-SHA256_pnr.json: Verilog-SHA256.json
	nextpnr-gowin --json Verilog-SHA256.json --write Verilog-SHA256_pnr.json --freq 27 --device ${DEVICE} --family ${FAMILY} --cst ${BOARD}.cst

# Generate Bitstream
Verilog-SHA256.fs: Verilog-SHA256_pnr.json
	gowin_pack -d ${FAMILY} -o  Verilog-SHA256.fs  Verilog-SHA256_pnr.json

# Program Board
load:  Verilog-SHA256.fs
	openFPGALoader -b ${BOARD}  Verilog-SHA256.fs -f

# Generate Simulation
main_test.o: main.v main_tb.v
	iverilog -o main_test.o -s test main.v main_tb.v

# Run Simulation
test: main_test.o
	vvp main_test.o

.PHONY: load
.INTERMEDIATE:  Verilog-SHA256_pnr.json  Verilog-SHA256.json main_test.o
