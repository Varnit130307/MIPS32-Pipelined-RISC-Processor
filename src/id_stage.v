
`include "mips32_defs.vh"

module id_stage (
    input         clk1,
    input         halted,
    input         stall_ID_EX,
    input         flush_ID_EX,
    input  [31:0] IF_ID_IR,
    input  [31:0] IF_ID_NPC,
    input  [31:0] reg_rdata1,
    input  [31:0] reg_rdata2,
    output [4:0]  reg_raddr1,
    output [4:0]  reg_raddr2,
    output reg [31:0] ID_EX_IR,
    output reg [31:0] ID_EX_NPC,
    output reg [31:0] ID_EX_A,
    output reg [31:0] ID_EX_B,
    output reg [31:0] ID_EX_Imm,
    output reg [2:0]  ID_EX_type
);
initial begin
        ID_EX_IR   <= 32'b0;
        ID_EX_NPC  <= 32'b0;
        ID_EX_A    <= 32'b0;
        ID_EX_B    <= 32'b0;  // Not strictly necessary to initialize these, but it makes the waveforms cleaner (no X's)
        ID_EX_Imm  <= 32'b0;
        ID_EX_type <= 3'b0; 
        end
    assign reg_raddr1 = IF_ID_IR[25:21];
    assign reg_raddr2 = IF_ID_IR[20:16];
always @(posedge clk1) begin

    if (flush_ID_EX) begin
        // Insert NOP bubble
        ID_EX_IR   <= 32'b0; // Keep the instruction for debugging visibility, but it won't be executed
        ID_EX_NPC  <= 32'b0;
        ID_EX_A    <= 32'b0;
        ID_EX_B    <= 32'b0;
        ID_EX_Imm  <= 32'b0;
        ID_EX_type <= 3'b0;
    end
    else if (!halted) begin
    // Normal operation: pass values to EX stage
        ID_EX_A    <= reg_rdata1;
        ID_EX_B    <= reg_rdata2;
        ID_EX_NPC  <= IF_ID_NPC;
        ID_EX_IR   <= IF_ID_IR;
        ID_EX_Imm  <= {{16{IF_ID_IR[15]}}, IF_ID_IR[15:0]};
        case (IF_ID_IR[31:26])
            `ADD, `SUB, `AND, `OR, `SLT, `MUL : ID_EX_type <= `RR_ALU;
            `ADDI, `SUBI, `SLTI               : ID_EX_type <= `RM_ALU;
            `LW                                : ID_EX_type <= `LOAD;
            `SW                                : ID_EX_type <= `STORE;
            `BEQZ, `BNEQZ                      : ID_EX_type <= `BRANCH;  // for branches, we still want to pass the instruction and register values to EX stage for condition checking and target calculation
            `HLT                               : ID_EX_type <= `HALT;
            default                            : ID_EX_type <= `HALT;
        endcase
    end
end
endmodule
