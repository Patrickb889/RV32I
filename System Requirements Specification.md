# System Requirements Specification

## 1. Introduction
### 1.1 Purpose
This document specifies the functional and non-functional requirements for an RV32I RISC-V instruction set simulator (ISS) implemented in software. It is intended to serve as a 
reference for the developer during implementation and testing. The document covers the full scope of the simulator's required behaviour, interfaces, and quality constraints.

### 1.2 Scope
The scope of this project encompasses the full behavioural and interface requirements for a software-based RV32I instruction-set simulator. The simulator shall accept ELF32 binaries 
compiled for the RISC-V 32-bit base integer ISA and execute them on a host machine without physical RISC-V hardware. It is intended as a learning and verification tool for understanding 
CPU architecture and validating RV32I program behaviour.
The following are explicitly out of scope: compressed instructions (RV32C), floating point extensions (RV32F/D), or any extension beyond the base RV32I instruction set, 
privileged ISA features, hardware implementation, and multi-core or multi-hart execution. 

## 2. Description
### 2.1 Product Perspective
The simulation is a standalone software tool that sits between the compilation toolchain and physical hardware in a typical RISC-V development workflow. It accepts ELF32 binaries 
produced by a RISC-V cross-compiler and executes them on a host machine. It has no dependencies on physical RISC-V hardware and operates entirely 
in software. The simulator runs in a Linux environment and outputs to the host terminal.

### 2.2 Assumptions
- A-01: Input ELF32 binaries are assumed to be correctly compiled for the RV32I ISA.
- A-02: The host machine is assumed to be little-endian.
- A-03: The simulated program is assumed to fit within the defined simulated memory space.
- A-04: The ELF binary is assumed to target a bare-metal environment with no operating system — meaning no Linux syscalls or OS-level services are expected from the simulated program.
- A-05: The simulator is assumed to be functional/behavioural only — cycle-accurate execution timing is not required.

### 2.3 Constraints
- C-01: The simulator must run on Linux or Windows via WSL.
- C-02: Implementation is constrained to the RV32I base integer ISA only.
- C-03: The simulator must accept ELF32 as the sole input format.

## 3. Functional Requirements

> Requirements follow the format: **`FR-XX`** — *The system shall [action] [object] [condition].*
>
> Priority: 🔴 Must Have | 🟡 Should Have | 🟢 Nice to Have

---

### 3.1 ELF Binary Loading

| ID | Requirement | Priority |
|---|---|---|
| FR-01 | The system shall parse and load a valid ELF32 binary into simulated memory. | 🔴 |
| FR-02 | The system shall initialize the program counter to the entry point address specified in the ELF header. | 🔴 |
| FR-03 | The system shall reject any input file that is not a valid ELF32 binary and report an error to the user. | 🔴 |

---

### 3.2 Instruction Decoding

| ID | Requirement | Priority |
|---|---|---|
| FR-04 | The system shall decode all 47 instructions defined in the RV32I base integer ISA. | 🔴 |
| FR-05 | The system shall correctly decode all RV32I instruction formats: R, I, S, B, U, and J. | 🔴 |
| FR-06 | The system shall detect and report any unrecognized or illegal opcode encountered during decoding. | 🔴 |

---

### 3.3 Arithmetic Operations

| ID | Requirement | Priority |
|---|---|---|
| FR-07 | The system shall execute all RV32I integer register-register arithmetic instructions: ADD, SUB, AND, OR, XOR, SLL, SRL, SRA, SLT, and SLTU. | 🔴 |
| FR-08 | The system shall execute all RV32I integer register-immediate arithmetic instructions: ADDI, ANDI, ORI, XORI, SLLI, SRLI, SRAI, SLTI, and SLTIU. | 🔴 |
| FR-09 | The system shall handle integer overflow via wrapping arithmetic as defined by the RV32I specification. | 🔴 |
| FR-10 | The system shall correctly distinguish and execute signed and unsigned arithmetic operations. | 🔴 |

---

### 3.4 Branch Operations

| ID | Requirement | Priority |
|---|---|---|
| FR-11 | The system shall execute all RV32I branch instructions: BEQ, BNE, BLT, BGE, BLTU, and BGEU. | 🔴 |
| FR-12 | The system shall execute the RV32I jump instructions JAL and JALR. | 🔴 |
| FR-13 | The system shall correctly update the program counter for both taken and not-taken branches. | 🔴 |
| FR-14 | The system shall correctly store the return address in the destination register for JAL and JALR instructions. | 🔴 |

---

### 3.5 Memory Operations

| ID | Requirement | Priority |
|---|---|---|
| FR-15 | The system shall execute all RV32I load instructions: LB, LH, LW, LBU, and LHU. | 🔴 |
| FR-16 | The system shall execute all RV32I store instructions: SB, SH, and SW. | 🔴 |
| FR-17 | The system shall correctly apply sign extension to the results of LB and LH load instructions. | 🔴 |
| FR-18 | The system shall correctly treat LBU and LHU as zero-extended unsigned loads. | 🔴 |
| FR-19 | The system shall detect and report any memory access that falls outside the defined simulated memory space. | 🔴 |

---

### 3.6 Exceptions and Traps

| ID | Requirement | Priority |
|---|---|---|
| FR-20 | The system shall detect and report an illegal instruction exception when an unrecognized opcode is executed. | 🔴 |
| FR-21 | The system shall detect and report a misaligned memory access exception when a load or store address does not meet RV32I alignment requirements. | 🔴 |
| FR-22 | The system shall detect and report a misaligned PC exception when an instruction fetch occurs from a non 4-byte aligned address. | 🔴 |
| FR-23 | The system shall halt simulation cleanly and report the cause when an unrecoverable exception is encountered. | 🔴 |

## 4. Non-Functional Requirements

> Requirements follow the format: **`NFR-XX`** — *The system shall [quality criterion] [measurable condition].*

---

### 4.1 Accuracy

| ID | Requirement |
|---|---|
| NFR-01 | The system shall produce register and memory state identical to the RV32I specification for all base integer instructions. |
| NFR-02 | The system shall pass all applicable tests in the official RISC-V compliance test suite for the RV32I base integer ISA. |

---

### 4.2 Maintainability

| ID | Requirement |
|---|---|
| NFR-03 | The system shall implement each functional stage (fetch, decode, execute, memory) as a separate, independently readable module. |
| NFR-04 | Each source module shall be traceable to one or more functional requirement IDs from this document. |

---

### 4.3 Portability

| ID | Requirement |
|---|---|
| NFR-05 | The system shall run on Ubuntu 22.04 or later, either natively or via WSL on a Windows host. |

---

### 4.4 Testability

| ID | Requirement |
|---|---|
| NFR-06 | Each functional requirement in section 3 shall have at least one corresponding test case. |
| NFR-07 | The system shall produce a full register dump and final PC value at the end of every simulation run to support verification. |

## 5. Interface Requirements

> Requirements follow the format: **`IF-XX`** — *The system shall [accept/produce/report] [input/output/interface] [condition].*

---

### 5.1 Input Interface

| ID | Requirement |
|---|---|
| IF-01 | The system shall accept a single ELF32 binary as input via a command-line argument. |
| IF-02 | The system shall report a descriptive error message to stderr identifying the specific cause of any input failure. |
| IF-03 | The system shall report a descriptive error message to stderr if the input file cannot be found or opened. |

---

### 5.2 Output Interface

| ID | Requirement |
|---|---|
| IF-04 | The system shall write all simulation output to stdout. |
| IF-05 | The system shall produce a full register dump and final PC value at the end of every simulation run. |
| IF-06 | The system shall report all exceptions and errors to stderr with a descriptive message. |

---

### 5.3 Development Environment

| ID | Requirement |
|---|---|
| IF-07 | The system shall be developed and executed using Icarus Verilog on Ubuntu 22.04 or later, natively or via WSL. |
