# Project Charter

## Problem Statement
Modern CPUs are among the most complex and foundational components in computing, yet their internal workings are rarely taught through hands-on construction. As a third-year computer 
engineering student, I lack a deep, practical understanding of how a CPU executes instructions — including how data flows through stages, how arithmetic and logic operations are 
performed, and how hardware modules communicate with one another.

To address this gap, I will design and simulate a functional CPU from scratch using SystemVerilog, implementing core components such as the ALU, register file, program counter, and 
control unit. The CPU will follow the RISC-V instruction set architecture (ISA), a well-documented open standard well-suited for learning. The design will be developed and verified 
in a Linux-based simulation environment using Icarus Verilog and GTKWave.

Success will be measured by the CPU's ability to correctly execute a defined set of RISC-V instructions in simulation, with outputs verified through testbenches and waveform analysis.

## Project Goals
1. Learn RISC-V architecture — Gain a working understanding of the RV32I base integer instruction set, including instruction formats, memory addressing, and the role of each instruction
type (R, I, S, B, U, J) in program execution.
2. Produce a working simulation of a 5-stage pipelined CPU — Design, implement, and verify a CPU in SystemVerilog that correctly executes RV32I instructions through a 5-stage pipeline
(Fetch, Decode, Execute, Memory, Writeback), validated through testbenches and GTKWave waveform analysis.
3. Document and record my design process — Maintain clear, ongoing documentation of design decisions, module interfaces, encountered bugs, and their resolutions — producing a reference
that could help a future beginner replicate or build on this work.

## Success Criteria
1. Instruction correctness — All RV32I base integer instructions execute and produce correct results in simulation, verified against expected outputs defined in SystemVerilog testbenches.
2. Pipeline functionality — All 5 stages (Fetch, Decode, Execute, Memory, Writeback) operate correctly in sequence, with hazard handling (data hazards, control hazards) producing correct
results rather than corrupted or stale values.
3. Waveform verification — GTKWave waveforms for each module clearly show expected signal behaviour at each clock cycle, serving as visual confirmation of correct operation.
4. Modular design integrity — Each hardware module (ALU, register file, program counter, control unit, etc.) passes its own isolated testbench before being integrated into the full pipeline.

## Scope
- Design and simulation of a 5-stage pipelined CPU in SystemVerilog supporting the RV32I base integer instruction set
- Implementation of core modules: ALU, register file, program counter, instruction memory, data memory, and control unit
- Hazard detection and handling for data and control hazards
- Verification through per-module testbenches and full-pipeline integration tests
- Waveform analysis using GTKWave
- Documentation of design decisions, module interfaces, and bug resolutions

## Non-Goals
- Physical synthesis or FPGA deployment
- Support for RISC-V extensions beyond RV32I (e.g. M, F, C extensions)
- An operating system, assembler, or toolchain built on top of the CPU
- Performance optimization (e.g. branch prediction, caching, superscalar execution)

## Timeline
| Milestone | Target Date | Description |
|--------|--------|-------------|
| 3/5 core modules completed | June 30, 2026 | 3 core CPU modules designed and passing their isolated testbenches |
| Functional single-cycle CPU | July 31, 2026  | All modules integrated into a working single-cycle design that correctly executes RV32I instructions end-to-end |
| Pipelined CPU | August 16, 2026  | Single-cycle design refactored into a 5-stage pipeline with hazard handling, verified through integration testbenches and waveform analysis |

## Deliverables
- Core CPU Modules With Accompanying Test Benches
  - Arithmetic/Logic Unit
  - Registers
  - Instruction Memory
  - Data Memory
  - Decoder
- Single Cycle CPU
- Pipelined CPU
- Project Documentation
