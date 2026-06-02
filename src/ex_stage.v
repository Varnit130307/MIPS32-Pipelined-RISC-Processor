`include "mips32_defs.vh"

module ex_stage (
    input         clk1,
    input         halted,
    input  [31:0] ID_EX_IR,
    input  [31:0] ID_EX_NPC,
    input  [31:0] ID_EX_A,
    input  [31:0] ID_EX_B,
    input  [31:0] ID_EX_Imm,
    input  [2:0]  ID_EX_type,

    // Forwarding
    input  [1:0]  forward_a,
    input  [1:0]  forward_b,
    input  [31:0] EX_MEM_fwd,   // EX/MEM ALUOut forwarded value
    input  [31:0] MEM_WB_fwd,   // MEM/WB result (ALUOut or LMD)

    output reg [31:0] EX_MEM_IR,
    output reg [31:0] EX_MEM_ALUOut,   // single, clean output name
    output reg [31:0] EX_MEM_B,
    output reg [31:0] EX_MEM_COND,
    output reg [2:0]  EX_MEM_type
);
    initial begin
        EX_MEM_IR     = 32'b0;
        EX_MEM_ALUOut = 32'b0;
        EX_MEM_B      = 32'b0;
        EX_MEM_COND   = 32'b0;
        EX_MEM_type   = `BRANCH; // not a write type ( forwarding stays quiet; won't trigger HALT )
    end

    // Forwarding muxes (combinational)
        wire [31:0] alua = (forward_a == 2'b10) ? EX_MEM_fwd :
                       (forward_a == 2'b01) ? MEM_WB_fwd : ID_EX_A;

        wire [31:0] alub = (forward_b == 2'b10) ? EX_MEM_fwd :
                       (forward_b == 2'b01) ? MEM_WB_fwd : ID_EX_B;

    always @(posedge clk1) begin

        if (!halted) begin
            EX_MEM_IR   <= ID_EX_IR;
            EX_MEM_type <= ID_EX_type;
            EX_MEM_B    <= alub;    // use forwarded B (needed for STORE)

            case (ID_EX_type)
                `RR_ALU : begin
                    case (ID_EX_IR[31:26])
                        `ADD  : EX_MEM_ALUOut <= alua + alub;
                        `SUB  : EX_MEM_ALUOut <= alua - alub;
                        `AND  : EX_MEM_ALUOut <= alua & alub;
                        `OR   : EX_MEM_ALUOut <= alua | alub;
                        `SLT  : EX_MEM_ALUOut <= (alua < alub) ? 32'd1 : 32'd0;
                        `MUL  : EX_MEM_ALUOut <= alua * alub;
                        default: EX_MEM_ALUOut <= 32'd0;
                    endcase
                    EX_MEM_COND <= 32'd0;
                end
                `RM_ALU : begin
                    case (ID_EX_IR[31:26])
                        `ADDI : EX_MEM_ALUOut <= alua + ID_EX_Imm;
                        `SUBI : EX_MEM_ALUOut <= alua - ID_EX_Imm;
                        `SLTI : EX_MEM_ALUOut <= (alua < ID_EX_Imm) ? 32'd1 : 32'd0;
                        default: EX_MEM_ALUOut <= 32'd0;
                    endcase
                    EX_MEM_COND <= 32'd0;
                end
                `LOAD : begin
                    EX_MEM_ALUOut <= alua + ID_EX_Imm;
                    EX_MEM_COND   <= 32'd0;
                end
                `STORE : begin
                    EX_MEM_ALUOut <= alua + ID_EX_Imm;
                    EX_MEM_COND   <= 32'd0;
                end
                `BRANCH : begin
                    EX_MEM_ALUOut <= ID_EX_NPC + ID_EX_Imm;
                    case (ID_EX_IR[31:26])
                        `BEQZ  : EX_MEM_COND <= (alua == 32'd0) ? 32'd1 : 32'd0;
                        `BNEQZ : EX_MEM_COND <= (alua != 32'd0) ? 32'd1 : 32'd0;
                        default: EX_MEM_COND <= 32'd0;
                    endcase
                end
                default : begin
                    EX_MEM_ALUOut <= 32'd0;
                    EX_MEM_COND   <= 32'd0;
                end
            endcase
        end
    end
endmodule
