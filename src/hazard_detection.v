`include "mips32_defs.vh"
module hazard_detection(
    input [31:0] IF_ID_IR,
    input [31:0] ID_EX_IR,

    output reg stall_IF_ID,
    output reg stall_ID_EX,
    output reg flush_ID_EX
);

    wire [5:0] id_ex_opcode;

    wire [4:0] load_rd;
    wire [4:0] if_id_rs;
    wire [4:0] if_id_rt;

    assign id_ex_opcode = ID_EX_IR[31:26];

    // For LW rt,imm(rs)
    assign load_rd = ID_EX_IR[20:16];

    assign if_id_rs = IF_ID_IR[25:21];
    assign if_id_rt = IF_ID_IR[20:16];

    always @(*) begin

        stall_IF_ID = 1'b0;
        stall_ID_EX = 1'b0;
        flush_ID_EX = 1'b0;

        // Load-use hazard
        if ((id_ex_opcode == `LW) &&
            ((load_rd == if_id_rs) ||
             (load_rd == if_id_rt)))
        begin
            stall_IF_ID = 1'b1;
            stall_ID_EX = 1'b0;
            flush_ID_EX = 1'b1;
        end
    end

endmodule