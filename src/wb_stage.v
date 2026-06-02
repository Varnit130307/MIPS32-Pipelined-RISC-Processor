
`include "mips32_defs.vh"

module wb_stage (
    input         clk1,
   
    input  [31:0] MEM_WB_IR,
    input  [31:0] MEM_WB_ALUOut,
    input  [31:0] MEM_WB_LMD,
    input  [2:0]  MEM_WB_type,
   
    output reg        reg_we,
    output reg [4:0]  reg_waddr,
    output reg [31:0] reg_wdata,
    
    output reg HALTED
);
    initial HALTED = 1'b0;

    always @(*) begin
        reg_we    <=  1'b0;
        reg_waddr <=  5'b0;  // default to $zero for safety; writes to $zero are ignored in regbank
        reg_wdata <=  32'b0;

        if (!HALTED) begin
            case (MEM_WB_type)
                `RR_ALU : begin
                    reg_we    <=  1'b1;
                    reg_waddr <=  MEM_WB_IR[15:11];  
                    reg_wdata <=  MEM_WB_ALUOut;
                end
                `RM_ALU : begin
                    reg_we    <=  1'b1;
                    reg_waddr <=  MEM_WB_IR[20:16];  
                    reg_wdata <=  MEM_WB_ALUOut;
                end
                `LOAD : begin
                    reg_we    <=  1'b1;
                    reg_waddr <=  MEM_WB_IR[20:16];  
                    reg_wdata <=  MEM_WB_LMD;
                end
                `STORE : ;   
                `HALT  : HALTED <= 1'b1;
                default : ;
            endcase
        end
    end
endmodule
