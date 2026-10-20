`timescale 1ns/1ps

module tb_soc_step12;

    logic clk;
    logic rst;
    logic dma_irq;
    logic uart_tx;

    soc_step7 dut (
        .clk     (clk),
        .rst     (rst),
        .dma_irq (dma_irq),
        .uart_tx (uart_tx)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst = 1;

        // Clear BRAM
        for (integer i = 0; i < 1024; i = i + 1)
            dut.memory.mem[i] = 32'b0;

        // Clear IMEM
        for (integer i = 0; i < 64; i = i + 1)
            dut.instruction_memory.mem[i] = 32'h00000013;

        /*
         * ==========================================
         * MAIN PROGRAM
         * ==========================================
         *
         * mtvec = 0x80
         * mstatus.MIE = 1
         * mie.MEIE = 1
         *
         * DMA:
         *   SRC    = 0x0000
         *   DST    = 0x0010
         *   LENGTH = 16 bytes
         *   START
         *
         * Sau đó CPU tiếp tục chạy.
         */

        // x1 = 0x80
        dut.instruction_memory.mem[0] = 32'h08000093;

        // CSRRW x0, mtvec, x1
        dut.instruction_memory.mem[1] = 32'h30509073;

        // x2 = 8 -> MIE = 1
        dut.instruction_memory.mem[2] = 32'h00800113;

        // CSRRW x0, mstatus, x2
        dut.instruction_memory.mem[3] = 32'h30011073;

        // x3 = -2048 -> bit 11 = 1
        dut.instruction_memory.mem[4] = 32'h80000193;

        // CSRRW x0, mie, x3
        dut.instruction_memory.mem[5] = 32'h30419073;

        // x10 = 0x0000
        dut.instruction_memory.mem[6] = 32'h00000513;

        // x11 = 0x0010
        dut.instruction_memory.mem[7] = 32'h01000593;

        // x16 = 16 bytes
        dut.instruction_memory.mem[8] = 32'h01000813;

        // x12 = DMA base 0x1000
        dut.instruction_memory.mem[9] = 32'h06402603;

        /*
         * DMA register map
         *
         * SRC    0x00
         * DST    0x04
         * LENGTH 0x08
         * CTRL   0x0C
         */

        // DMA SRC = 0
        dut.instruction_memory.mem[10] = 32'h00A62023;

        // DMA DST = 0x10
        dut.instruction_memory.mem[11] = 32'h00B62223;

        // DMA LENGTH = 16 bytes
        dut.instruction_memory.mem[12] = 32'h01062423;

        // x13 = 1
        dut.instruction_memory.mem[13] = 32'h00100693;

        // DMA START
        dut.instruction_memory.mem[14] = 32'h00D62623;

        // x20 = 42 - marker main
        dut.instruction_memory.mem[15] = 32'h02A00A13;

        // Infinite loop
        dut.instruction_memory.mem[16] = 32'h0000006F;

        /*
         * ==========================================
         * ISR @ 0x80 = instruction 32
         * ==========================================
         *
         * x20 = 99
         *
         * DMA INT_STATUS = 1
         *
         * DMA INT_STATUS address:
         * DMA base + 0x18
         *
         * DMA base = 0x1000
         * address = 0x1018
         */

        // x20 = 99
        dut.instruction_memory.mem[32] = 32'h06300A13;

        // x14 = 0x1000
        dut.instruction_memory.mem[33] = 32'h06402703;

        // x15 = 1
        dut.instruction_memory.mem[34] = 32'h00100793;

        // SW x15, 0x18(x14)
        dut.instruction_memory.mem[35] = 32'h00F72C23;

        // MRET
        dut.instruction_memory.mem[36] = 32'h30200073;

        /*
         * DMA source data
         */
        dut.memory.mem[0] = 32'h11111111;
        dut.memory.mem[1] = 32'h22222222;
        dut.memory.mem[2] = 32'h33333333;
        dut.memory.mem[3] = 32'h44444444;
        dut.memory.mem[25] = 32'h00001000;

        #20;
        rst = 0;

        // Chạy đủ thời gian cho CPU + DMA + IRQ + ISR
        repeat (250) @(posedge clk);

        $display("");
        $display("======================================");
        $display("STEP 12.2: DMA IRQ -> CPU INTERRUPT");
        $display("======================================");

        if (dut.memory.mem[4] == 32'h11111111)
            $display("PASS: DMA WORD 0");
        else
            $display("FAIL: DMA WORD 0 = %h", dut.memory.mem[4]);

        if (dut.memory.mem[5] == 32'h22222222)
            $display("PASS: DMA WORD 1");
        else
            $display("FAIL: DMA WORD 1 = %h", dut.memory.mem[5]);

        if (dut.memory.mem[6] == 32'h33333333)
            $display("PASS: DMA WORD 2");
        else
            $display("FAIL: DMA WORD 2 = %h", dut.memory.mem[6]);

        if (dut.memory.mem[7] == 32'h44444444)
            $display("PASS: DMA WORD 3");
        else
            $display("FAIL: DMA WORD 3 = %h", dut.memory.mem[7]);

        if (dut.dma.done)
            $display("PASS: DMA DONE");
        else
            $display("FAIL: DMA DONE");

        if (dut.dma.int_status == 1'b0)
            $display("PASS: DMA IRQ CLEARED BY ISR");
        else
            $display("FAIL: DMA INT_STATUS STILL SET");

        if (dut.cpu.regs[20] == 32'd99)
            $display("PASS: CPU ISR EXECUTED");
        else
            $display("FAIL: CPU ISR NOT EXECUTED, x20=%0d",
                     dut.cpu.regs[20]);

        if (dma_irq == 1'b0)
            $display("PASS: DMA IRQ DEASSERTED");
        else
            $display("FAIL: DMA IRQ STILL HIGH");

        $display("======================================");
        $display("STEP 12.2: TEST COMPLETE");
        $display("======================================");

        $finish;
    end

endmodule
