`include "mips32_defs.vh"

module mem_stage (
    input         clk1,
    input         halted,
    input         taken_branch,

    input  [31:0] EX_MEM_IR,
    input  [31:0] EX_MEM_ALUOut,
    input  [31:0] EX_MEM_B,
    input  [2:0]  EX_MEM_type,

    input  [31:0] mem_rdata,

    output reg        mem_we,
    output  [9:0]  mem_daddr,
    output reg [31:0] mem_wdata,

    output reg [31:0] MEM_WB_IR,
    output reg [31:0] MEM_WB_ALUOut,
    output reg [31:0] MEM_WB_LMD,
    output reg [2:0]  MEM_WB_type
);
    // Initialize type to BRANCH: not a write type (no false forwards)
    // and not HALT (won't trigger wb_stage to set HALTED=1 at startup)
    initial begin
        MEM_WB_IR     = 32'b0;
        MEM_WB_ALUOut = 32'b0;
        MEM_WB_LMD    = 32'b0;
        MEM_WB_type   = `BRANCH;
        mem_we        = 1'b0;
        mem_wdata     = 32'b0;

    end
    assign mem_daddr = ((EX_MEM_type == `LOAD) || (EX_MEM_type == `STORE)) ? 
                        EX_MEM_ALUOut[9:0] : 10'b0;

                        
    always @(posedge clk1) begin
        mem_we    <= 1'b0;
        mem_wdata <= 32'b0;


        if (!halted) begin
            case (EX_MEM_type)
                `RR_ALU, `RM_ALU : begin
                    MEM_WB_IR     <= EX_MEM_IR;
                    MEM_WB_ALUOut <= EX_MEM_ALUOut;
                    MEM_WB_type   <= EX_MEM_type;
                end
                `LOAD : begin
                    MEM_WB_IR     <= EX_MEM_IR;
                    MEM_WB_LMD    <= mem_rdata;
                    MEM_WB_type   <= EX_MEM_type;
                    MEM_WB_ALUOut <= EX_MEM_ALUOut; // forward ALUOut for address calculation (if needed)   
                end
                `STORE : begin
                    if (!taken_branch) begin
                        mem_we        <= 1'b1;
                        mem_wdata     <= EX_MEM_B;
                        MEM_WB_IR     <= EX_MEM_IR;
                        MEM_WB_type   <= EX_MEM_type;
                    end
                end
                default : begin
                    MEM_WB_IR     <= EX_MEM_IR;
                    MEM_WB_ALUOut <= EX_MEM_ALUOut;
                    MEM_WB_type   <= EX_MEM_type;
                end
            endcase
        end
    end
endmodule
