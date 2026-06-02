
`include "mips32_defs.vh"

module regbank (
    input         clk_wb,      
    input         we,           
    input  [4:0]  waddr,        
    input  [31:0] wdata,       
    
    input  [4:0]  raddr1,
    input  [4:0]  raddr2,
    output [31:0] rdata1,
    output [31:0] rdata2
);
    reg [31:0] Reg [0:31];

   
    assign rdata1 = (raddr1 == 5'b00000) ? 32'b0 : Reg[raddr1];
    assign rdata2 = (raddr2 == 5'b00000) ? 32'b0 : Reg[raddr2];

    always @(posedge clk_wb or negedge clk_wb) begin
        if (we && waddr != 5'b00000)
            Reg[waddr] <=  wdata;
    end

    
    
endmodule
