module forwarding_unit(
    input [4:0] rs1,
    input [4:0] rs2,
    input [4:0] rd_ex,
    input [4:0] rd_mem,
    input reg_write_ex,
    input reg_write_mem,
    output reg [1:0] forward_a,
    output reg [1:0] forward_b
);
    always @(*) begin
        // Default forwarding signals
        forward_a = 2'b00; // No forwarding
        forward_b = 2'b00; // No forwarding

        // Check for EX stage forwarding
        if (reg_write_ex && (rd_ex != 0) && (rd_ex == rs1)) begin
            forward_a = 2'b10; // Forward from EX stage
        end else if (reg_write_mem && (rd_mem != 0) && (rd_mem == rs1)) begin
            forward_a = 2'b01; // Forward from MEM stage
        end

        if (reg_write_ex && (rd_ex != 0) && (rd_ex == rs2)) begin
            forward_b = 2'b10; // Forward from EX stage
        end else if (reg_write_mem && (rd_mem != 0) && (rd_mem == rs2)) begin
            forward_b = 2'b01; // Forward from MEM stage
        end
    end
endmodule