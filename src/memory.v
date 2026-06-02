`include "mips32_defs.vh"

module memory (
    input        clk_mem,


    input  [9:0]  iaddr,
    output [31:0] idata,

    input         we,
    input  [9:0]  daddr,
    input  [31:0] wdata,
    output [31:0] rdata
);
    reg [31:0] Mem [0:1023];

    assign idata = Mem[iaddr];
    assign rdata = Mem[daddr];

    always @(posedge clk_mem or negedge clk_mem) begin
        if (we)
            Mem[daddr] <= wdata;
    end
endmodule
