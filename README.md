# RISC-V RV32I Processor

A RISC-V RV32I CPU core implemented in SystemVerilog, built from scratch as a 
learning project in digital hardware design.

## Project Status
🚧 Work in progress

## Architecture
- **ISA:** RISC-V RV32I (base integer instruction set)
- **Pipeline:** 5-stage (Fetch → Decode → Execute → Memory → Writeback)
- **HDL:** SystemVerilog
- **Simulator:** Icarus Verilog + GTKWave

## Modules
| Module | Status | Description |
|--------|--------|-------------|
| ALU    | ✅ Done | 16-operation ALU with zero, negative, carry, overflow flags |
| ...    | 🚧 WIP  | |

## Tools
- **OS:** Ubuntu (WSL2)
- **Editor:** VS Code
- **Simulation:** `iverilog` / `vvp` / `gtkwave`

## How to Simulate
```bash
iverilog -g2012 -o sim module.sv testbench.sv
vvp sim
```

## Learning Goals
- Understand RTL design and hardware description
- Implement a real ISA from the ground up
- Build intuition for pipelining and hazard handling
