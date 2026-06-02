`timescale 1ns / 1ps

module tb_pipe_mips32;

    reg clk1;
    integer i;
    pipe_mips32 dut(clk1);

    // Two-phase clocks: SAME period (20ns), clk2 posedge 10ns after clk1 posedge
    // clk1 posedge at: 10, 30, 50, 70 ...
    // clk2 posedge at: 20, 40, 60, 80 ...
    initial begin clk1 = 0;
                   end
    
                   // period = 20n    // same period, shifted by 10ns
    always #5 clk1 = ~clk1; // clk1 toggles every 5ns → period of 10ns // clk2 toggles every 5
    initial begin
        for (i = 0; i < 32; i = i + 1)
            dut.rb_inst.Reg[i] = i;

        // R1 = R0 + R10  → expect R1 = 0 + 10 = 10
        dut.mem_inst.Mem[0] = 32'h2801000A;
        // R2 = R1 + R11  → expect R2 = 10 + 11 = 21
        dut.mem_inst.Mem[1] = 32'h002B1000;
        // R3 = R2 + R12  → expect R3 = 21 + 12 = 33
        dut.mem_inst.Mem[2] = 32'h00221800;
        dut.mem_inst.Mem[3] = 32'h2824000A;
        dut.mem_inst.Mem[4] = 32'h20450064; // R5 = R2 + 100 → expect R5 = 21 + 100 = 121
        dut.mem_inst.Mem[5] = 32'h00a33000; // R4 = R0 + 10 → expect R4 = 10
        // HLT
        dut.mem_inst.Mem[6] = 32'hfc000000;

        dut.mem_inst.Mem[121] = 99;
        dut.if0.PC = 0;

        $monitor("time=%0d PC=%0d R[1]=%0d R[2]=%0d R[3]=%0d R[4]=%0d R[5]=%0d R[6]=%0d",
                 $time,
                 dut.if0.PC,
                 dut.rb_inst.Reg[1],
                 dut.rb_inst.Reg[2],
                 dut.rb_inst.Reg[3],
                 dut.rb_inst.Reg[4],
                 dut.rb_inst.Reg[5],
                 dut.rb_inst.Reg[6]
                 );

    end

    initial begin
        $dumpfile("mips.vcd");
        $dumpvars(0, tb_pipe_mips32);
        $dumpvars(0, dut.rb_inst.Reg[0]);
        $dumpvars(0, dut.rb_inst.Reg[1]);
        $dumpvars(0, dut.rb_inst.Reg[2]);
        $dumpvars(0, dut.rb_inst.Reg[3]);
        $dumpvars(0, dut.rb_inst.Reg[4]);
        $dumpvars(0, dut.rb_inst.Reg[5]);
        $dumpvars(0, dut.rb_inst.Reg[6]); 
        #1000 $finish;
    end

endmodule
