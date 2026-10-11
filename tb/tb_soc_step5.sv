`timescale 1ns/1ps

module tb_soc_step5;

    logic clk;
    logic rst;

    soc_step5 dut (
        .clk(clk),
        .rst(rst)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst = 1;

        // NOP
        dut.memory.mem[0] = 32'h00000013;
        dut.memory.mem[1] = 32'h00000013;
        dut.memory.mem[2] = 32'h00000013;

        // ADDI x1, x0, 10
        dut.memory.mem[0] = 32'h00A00093;

        // ADDI x2, x0, 20
        dut.memory.mem[1] = 32'h01400113;

        // ADD x3, x1, x2
        dut.memory.mem[2] = 32'h002081B3;

        // SW x3, 0(x0)
        dut.memory.mem[3] = 32'h00302023;

        // LW x4, 0(x0)
        dut.memory.mem[4] = 32'h00002203;

        #20;
        rst = 0;

        #300;

        $display("");
        $display("==============================");
        $display("STEP 5: CPU + INTERNAL BUS");
        $display("==============================");

        if (dut.cpu.regs[1] == 10)
            $display("PASS: x1 = 10");
        else
            $display("FAIL: x1 = %0d", dut.cpu.regs[1]);

        if (dut.cpu.regs[2] == 20)
            $display("PASS: x2 = 20");
        else
            $display("FAIL: x2 = %0d", dut.cpu.regs[2]);

        if (dut.cpu.regs[3] == 30)
            $display("PASS: x3 = 30");
        else
            $display("FAIL: x3 = %0d", dut.cpu.regs[3]);

        if (dut.cpu.regs[4] == 30)
            $display("PASS: x4 = 30");
        else
            $display("FAIL: x4 = %0d", dut.cpu.regs[4]);

        if (dut.memory.mem[0] == 30)
            $display("PASS: MEM[0] = 30");
        else
            $display("FAIL: MEM[0] = %0d", dut.memory.mem[0]);

        if ((dut.cpu.regs[1] == 10) &&
            (dut.cpu.regs[2] == 20) &&
            (dut.cpu.regs[3] == 30) &&
            (dut.cpu.regs[4] == 30) &&
            (dut.memory.mem[0] == 30)) begin

            $display("==============================");
            $display("PASS: CPU + INTERNAL BUS");
            $display("==============================");

        end else begin

            $display("==============================");
            $display("FAIL: CPU + INTERNAL BUS");
            $display("==============================");

        end

        $finish;
    end

endmodule
