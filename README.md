
# MIPS32 Pipelined RISC Processor

A Verilog implementation of a 5-stage MIPS32 RISC processor featuring pipelining, data forwarding, hazard detection, and load/store support.

## Features
- 5-stage pipeline (IF, ID, EX, MEM, WB)
- Data forwarding unit
- Hazard detection unit
- Load and store instructions
- Arithmetic and logical operations
- Branch instructions
- Verilog HDL implementation
- Simulation support using Icarus Verilog and GTKWave

## Pipeline Stages
1. Instruction Fetch (IF)
2. Instruction Decode (ID)
3. Execute (EX)
4. Memory Access (MEM)
5. Write Back (WB)

## Tools Used
- Verilog HDL
- Icarus Verilog
- GTKWave

## Project Structure
- `if_stage.v` – Instruction Fetch stage
- `id_stage.v` – Instruction Decode stage
- `ex_stage.v` – Execute stage
- `mem_stage.v` – Memory stage
- `wb_stage.v` – Write Back stage
- `forwarding_unit.v` – Data forwarding logic
- `hazard_detection.v` – Hazard detection logic
- `regbank.v` – Register file
- `memory.v` – Instruction/Data memory
- `pipe_mips32.v` – Top-level processor module

## Author
Varnit Chauhan
