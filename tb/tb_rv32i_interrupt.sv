`timescale 1ns/1ps

module tb_rv32i_interrupt;

    logic clk;
    logic rst;
    logic dma_irq;

    logic [31:0] instr_addr;
    logic [31:0] instr_rdata;

    logic        data_valid;
    logic        data_we;
    logic [31:0] data_addr;
    logic [31:0] data_wdata;
    logic [31:0] data_rdata;
    logic        data_ready;

    logic [31:0] imem [0:255];
    logic [31:0] dmem [0:255];

    rv32i_cpu dut (
        .clk        (clk),
        .rst        (rst),
        .instr_addr (instr_addr),
        .instr_rdata(instr_rdata),

        .data_valid (data_valid),
        .data_we    (data_we),
        .data_addr  (data_addr),
        .data_wdata (data_wdata),
        .data_rdata (data_rdata),
        .data_ready (data_ready),

        .dma_irq    (dma_irq)
    );

    assign instr_rdata = imem[instr_addr[9:2]];
    assign data_rdata  = dmem[data_addr[9:2]];
    assign data_ready  = data_valid;

    always #5 clk = ~clk;

    always_ff @(posedge clk) begin
        if (data_valid && data_we)
            dmem[data_addr[9:2]] <= data_wdata;
    end

    initial begin
        clk     = 0;
        rst     = 1;
        dma_irq = 0;

        for (integer i = 0; i < 256; i = i + 1) begin
            imem[i] = 32'h00000013; // NOP
            dmem[i] = 32'b0;
        end

        /*
         * MAIN PROGRAM
         *
         * x1 = 64
         * mtvec = 64
         *
         * x2 = 8
         * mstatus.MIE = 1
         *
         * x3 = -2048
         * mie.MEIE = 1
         *
         * x5 = 55
         * x5 = x5 + 1
         *
         * loop
         */

        // 0: ADDI x1, x0, 64
        imem[0] = 32'h04000093;

        // 4: CSRRW x0, mtvec, x1
        imem[1] = 32'h30509073;

        // 8: ADDI x2, x0, 8
        imem[2] = 32'h00800113;

        // 12: CSRRW x0, mstatus, x2
        imem[3] = 32'h30011073;

        // 16: ADDI x3, x0, -2048
        imem[4] = 32'h80000193;

        // 20: CSRRW x0, mie, x3
        imem[5] = 32'h30419073;

        // 24: ADDI x5, x0, 55
        imem[6] = 32'h03700293;

        // 28: ADDI x5, x5, 1
        imem[7] = 32'h00128293;

        // 32: BEQ x0, x0, -4
        imem[8] = 32'hFE000EE3;

        /*
         * ISR @ 64
         *
         * x6 = 99
         * MRET
         */

        // 64: ADDI x6, x0, 99
        imem[16] = 32'h06300313;

        // 68: MRET
        imem[17] = 32'h30200073;

        #20;
        rst = 0;

        // Wait until main reaches ADDI x5,x5,1
        wait (dut.pc == 32'd28);

        // Trigger DMA interrupt
        @(posedge clk);
        dma_irq = 1;

        @(posedge clk);
        dma_irq = 0;

        // Allow ISR + MRET + main to execute
        repeat (20) @(posedge clk);

        $display("");
        $display("==============================");
        $display("STEP 12: CPU INTERRUPT TEST");
        $display("==============================");

        if (dut.csr_mtvec == 32'd64)
            $display("PASS: MTVEC = 64");
        else
            $display("FAIL: MTVEC = %0d", dut.csr_mtvec);

        if (dut.csr_meie == 1'b1)
            $display("PASS: MEIE = 1");
        else
            $display("FAIL: MEIE = %0d", dut.csr_meie);

        if (dut.csr_mie == 1'b1)
            $display("PASS: MIE RESTORED AFTER MRET");
        else
            $display("FAIL: MIE = %0d", dut.csr_mie);

        if (dut.regs[6] == 32'd99)
            $display("PASS: ISR EXECUTED");
        else
            $display("FAIL: ISR x6 = %0d", dut.regs[6]);

        if (dut.csr_mepc == 32'd28)
            $display("PASS: MEPC = 28");
        else
            $display("FAIL: MEPC = %0d", dut.csr_mepc);

        if (dut.regs[5] >= 32'd56)
            $display("PASS: MRET RESUME");
        else
            $display("FAIL: MRET x5 = %0d", dut.regs[5]);

        $display("==============================");
        $display("STEP 12: INTERRUPT TEST DONE");
        $display("==============================");

        $finish;
    end

endmodule
