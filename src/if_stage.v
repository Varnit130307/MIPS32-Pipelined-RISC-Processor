`include "mips32_defs.vh"

module if_stage (
    input         clk1,
    input         halted,
    input         stall_IF_ID,
    input  [31:0] EX_MEM_IR, EX_MEM_ALUOut, EX_MEM_COND,
    input         branch_taken,
    input  [31:0] instr_in,
    output reg [9:0]  PC,
    output reg [31:0] IF_ID_IR,
    output reg [31:0] IF_ID_NPC,
    output reg        TAKEN_BRANCH
);
    initial begin
        PC           = 10'b0;
        IF_ID_IR     = 32'b0;
        IF_ID_NPC    = 32'b0;   // This initial branch is not strictly necessary, but it makes the waveforms cleaner (no X's)
        TAKEN_BRANCH = 1'b0;
    end

    always @(posedge clk1) begin
        if (!halted && !stall_IF_ID) begin
            if ((EX_MEM_IR[31:26] == `BEQZ  && EX_MEM_COND == 32'd1) ||
                (EX_MEM_IR[31:26] == `BNEQZ && EX_MEM_COND == 32'd0)) begin
                // EX_MEM_ALUOut is already the branch target (NPC + offset)
                // fetch from target; NPC for next stage is target+1
                PC           <= EX_MEM_ALUOut[9:0];
                IF_ID_NPC    <= EX_MEM_ALUOut + 1;
                IF_ID_IR     <= instr_in;
                TAKEN_BRANCH <= 1'b1;
            end else begin
                // not a branch, so clear TAKEN_BRANCH
                PC           <= PC + 1;
                IF_ID_NPC    <= PC + 1;
                IF_ID_IR     <= instr_in;
                TAKEN_BRANCH <= 1'b0;
            end
        end
            else if(stall_IF_ID)  begin
            PC <= PC;          // hold PC
            IF_ID_NPC <= IF_ID_NPC;
            IF_ID_IR <= IF_ID_IR;
            TAKEN_BRANCH <= TAKEN_BRANCH;
        end 
    end
    
endmodule
