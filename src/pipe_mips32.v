`include "mips32_defs.vh"

module pipe_mips32 (
    input clk1
);

    // wires for IF/ID pipeline register
    wire [31:0] IF_ID_IR, IF_ID_NPC;
    wire        TAKEN_BRANCH;
    wire [9:0]  PC;
    // wires for ID/EX pipeline register
    wire [31:0] ID_EX_IR, ID_EX_NPC, ID_EX_A, ID_EX_B, ID_EX_Imm;
    wire [2:0]  ID_EX_type;
    // wires for EX/MEM pipeline register
    wire [31:0] EX_MEM_IR, EX_MEM_ALUOut, EX_MEM_B, EX_MEM_COND;
    wire [2:0]  EX_MEM_type;
    // wires for MEM/WB pipeline register
    wire [31:0] MEM_WB_IR, MEM_WB_ALUOut, MEM_WB_LMD;
    wire [2:0]  MEM_WB_type;
    // branch taken logic: for BEQZ, taken if EX_MEM_COND==1; for BNEQZ, taken if EX_MEM_COND==0
    wire branch_taken = ((EX_MEM_IR[31:26] == `BEQZ  && EX_MEM_COND == 32'd1) ||
                         (EX_MEM_IR[31:26] == `BNEQZ && EX_MEM_COND == 32'd0));
    // register file interface
    wire [4:0]  reg_raddr1, reg_raddr2;
    wire [31:0] reg_rdata1, reg_rdata2;
    wire        reg_we;
    wire [4:0]  reg_waddr;
    wire [31:0] reg_wdata;

    // FIX: HALTED driven by wb_stage output, not hardwired
    wire HALTED;
    // instruction memory interface
    wire [9:0]  iaddr = branch_taken ? EX_MEM_ALUOut[9:0] : PC;
    wire [31:0] idata;
    wire        mem_we;
    wire [9:0]  mem_daddr;
    wire [31:0] mem_wdata, mem_rdata;

    // Forwarding control signals
    wire [1:0] forward_a, forward_b;

    // rd for RR_ALU is IR[15:11]; for RM_ALU/LOAD it is IR[20:16]
    wire [4:0] EX_MEM_rd = (EX_MEM_type == `RR_ALU) ? EX_MEM_IR[15:11] : EX_MEM_IR[20:16];
    wire [4:0] MEM_WB_rd = (MEM_WB_type == `RR_ALU) ? MEM_WB_IR[15:11] : MEM_WB_IR[20:16];
    // reg_write signals for EX and MEM stages: only RR_ALU, RM_ALU, and LOAD write to registers
    wire reg_write_ex  = (EX_MEM_type == `RR_ALU) || (EX_MEM_type == `RM_ALU) || (EX_MEM_type == `LOAD);
    wire reg_write_mem = (MEM_WB_type == `RR_ALU) || (MEM_WB_type == `RM_ALU) || (MEM_WB_type == `LOAD);

    // MEM/WB forwarding value: LMD for LOAD, ALUOut for everything else
    wire [31:0] MEM_WB_fwd = (MEM_WB_type == `LOAD) ? MEM_WB_LMD : MEM_WB_ALUOut;
    // Hazard detection signals
    wire stall_ID_EX;
    wire flush_ID_EX;
    wire  stall_IF_ID;
    forwarding_unit fu (
        .rs1           (ID_EX_IR[25:21]),
        .rs2           (ID_EX_IR[20:16]),
        .rd_ex         (EX_MEM_rd),
        .rd_mem        (MEM_WB_rd),
        .reg_write_ex  (reg_write_ex),
        .reg_write_mem (reg_write_mem),
        .forward_a     (forward_a),
        .forward_b     (forward_b)
    );
     
     hazard_detection hd0(
        .IF_ID_IR       (IF_ID_IR),
        .ID_EX_IR       (ID_EX_IR),
        .stall_ID_EX      (stall_ID_EX),
        .flush_ID_EX      (flush_ID_EX),
        .stall_IF_ID      (stall_IF_ID)
     );

    memory mem_inst (
        .clk_mem  (clk1),
        .iaddr    (iaddr),
        .idata    (idata),
        .we       (mem_we),
        .daddr    (mem_daddr),
        .wdata    (mem_wdata),
        .rdata    (mem_rdata)
    );

    regbank rb_inst (
        .clk_wb   (clk1),
        .we       (reg_we),
        .waddr    (reg_waddr),
        .wdata    (reg_wdata),
        .raddr1   (reg_raddr1),
        .raddr2   (reg_raddr2),
        .rdata1   (reg_rdata1),
        .rdata2   (reg_rdata2)
    );

    if_stage if0 (
        .stall_IF_ID   (stall_IF_ID),
        .EX_MEM_IR     (EX_MEM_IR),
        .EX_MEM_COND   (EX_MEM_COND),
        .EX_MEM_ALUOut (EX_MEM_ALUOut),
        .clk1          (clk1),
        .halted        (HALTED),
        .branch_taken  (branch_taken),
        .instr_in      (idata),
        .PC            (PC),
        .IF_ID_IR      (IF_ID_IR),
        .IF_ID_NPC     (IF_ID_NPC),
        .TAKEN_BRANCH  (TAKEN_BRANCH)
    );

    id_stage id0 (
        .stall_ID_EX (stall_ID_EX),
        .flush_ID_EX (flush_ID_EX),
        .clk1       (clk1),
        .halted     (HALTED),
        .IF_ID_IR   (IF_ID_IR),
        .IF_ID_NPC  (IF_ID_NPC),
        .reg_rdata1 (reg_rdata1),
        .reg_rdata2 (reg_rdata2),
        .reg_raddr1 (reg_raddr1),
        .reg_raddr2 (reg_raddr2),
        .ID_EX_IR   (ID_EX_IR),
        .ID_EX_NPC  (ID_EX_NPC),
        .ID_EX_A    (ID_EX_A),
        .ID_EX_B    (ID_EX_B),
        .ID_EX_Imm  (ID_EX_Imm),
        .ID_EX_type (ID_EX_type)
    );

    ex_stage ex0 (
        .clk1          (clk1),
        .halted        (HALTED),
        .ID_EX_IR      (ID_EX_IR),
        .ID_EX_NPC     (ID_EX_NPC),
        .ID_EX_A       (ID_EX_A),
        .ID_EX_B       (ID_EX_B),
        .ID_EX_Imm     (ID_EX_Imm),
        .ID_EX_type    (ID_EX_type),
        .forward_a     (forward_a),
        .forward_b     (forward_b),
        .EX_MEM_fwd    (EX_MEM_ALUOut),
        .MEM_WB_fwd    (MEM_WB_fwd),
        .EX_MEM_IR     (EX_MEM_IR),
        .EX_MEM_ALUOut (EX_MEM_ALUOut),
        .EX_MEM_B      (EX_MEM_B),
        .EX_MEM_COND   (EX_MEM_COND),
        .EX_MEM_type   (EX_MEM_type)
    );

    mem_stage ms0 (
        .clk1          (clk1),
        .halted        (HALTED),
        .taken_branch  (TAKEN_BRANCH),
        .EX_MEM_IR     (EX_MEM_IR),
        .EX_MEM_ALUOut (EX_MEM_ALUOut),
        .EX_MEM_B      (EX_MEM_B),
        .EX_MEM_type   (EX_MEM_type),
        .mem_rdata     (mem_rdata),
        .mem_we        (mem_we),
        .mem_daddr     (mem_daddr),
        .mem_wdata     (mem_wdata),
        .MEM_WB_IR     (MEM_WB_IR),
        .MEM_WB_ALUOut (MEM_WB_ALUOut),
        .MEM_WB_LMD    (MEM_WB_LMD),
        .MEM_WB_type   (MEM_WB_type)
    );

    wb_stage wb0 (
        .clk1          (clk1),
        .MEM_WB_IR     (MEM_WB_IR),
        .MEM_WB_ALUOut (MEM_WB_ALUOut),
        .MEM_WB_LMD    (MEM_WB_LMD),
        .MEM_WB_type   (MEM_WB_type),
        .reg_we        (reg_we),
        .reg_waddr     (reg_waddr),
        .reg_wdata     (reg_wdata),
        .HALTED        (HALTED)
    );

endmodule
