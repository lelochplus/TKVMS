`timescale 1ns/1ps

module tb_soc_step7;

    logic clk;
    logic rst;

    logic dma_irq;
    logic uart_tx;

    logic prev_uart_tx;
    logic uart_start_seen;
    logic dma_irq_seen;

    integer i;

    soc_step7 dut (
        .clk(clk),
        .rst(rst),
        .dma_irq(dma_irq),
        .uart_tx(uart_tx)
    );

    always #5 clk = ~clk;

    // Monitor UART start bit and DMA IRQ during the whole simulation
    always @(posedge clk) begin
        if (rst) begin
            prev_uart_tx  <= 1'b1;
            uart_start_seen <= 1'b0;
            dma_irq_seen  <= 1'b0;
        end else begin
            if (prev_uart_tx && !uart_tx)
                uart_start_seen <= 1'b1;

            prev_uart_tx <= uart_tx;

            if (dma_irq)
                dma_irq_seen <= 1'b1;
        end
    end

    initial begin
        clk = 0;
        rst = 1;
        prev_uart_tx = 1'b1;
        uart_start_seen = 1'b0;
        dma_irq_seen = 1'b0;

        // ====================================================
        // CPU PROGRAM
        // ====================================================

        // UART base = 0x2000, stored safely at word 24
        dut.memory.mem[0] = 32'h06002503; // LW x10,96(x0)
        dut.memory.mem[1] = 32'h04100593; // ADDI x11,x0,65
        dut.memory.mem[2] = 32'h00B52023; // SW x11,0(x10)

        // DMA base = 0x1000, stored safely at word 25
        dut.memory.mem[3] = 32'h06402603; // LW x12,100(x0)

        // SRC = 64
        dut.memory.mem[4] = 32'h04000693; // ADDI x13,x0,64
        dut.memory.mem[5] = 32'h00D62023; // SW x13,0(x12)

        // DST = 80
        dut.memory.mem[6] = 32'h05000713; // ADDI x14,x0,80
        dut.memory.mem[7] = 32'h00E62223; // SW x14,4(x12)

        // LENGTH = 4
        dut.memory.mem[8] = 32'h00400793; // ADDI x15,x0,4
        dut.memory.mem[9] = 32'h00F62423; // SW x15,8(x12)

        // CONTROL = 1
        dut.memory.mem[10] = 32'h00100813; // ADDI x16,x0,1
        dut.memory.mem[11] = 32'h01062623; // SW x16,12(x12)

        // NOPs after starting DMA
        dut.memory.mem[12] = 32'h00000013;
        dut.memory.mem[13] = 32'h00000013;
        dut.memory.mem[14] = 32'h00000013;
        dut.memory.mem[15] = 32'h00000013;

        // ====================================================
        // DMA SOURCE DATA
        // words 16..19 = addresses 64..76
        // ====================================================

        dut.memory.mem[16] = 32'hAAAA1111;
        dut.memory.mem[17] = 32'hBBBB2222;
        dut.memory.mem[18] = 32'hCCCC3333;
        dut.memory.mem[19] = 32'hDDDD4444;

        // ====================================================
        // DMA DESTINATION
        // words 20..23 = addresses 80..92
        // ====================================================

        dut.memory.mem[20] = 32'h00000000;
        dut.memory.mem[21] = 32'h00000000;
        dut.memory.mem[22] = 32'h00000000;
        dut.memory.mem[23] = 32'h00000000;

        // ====================================================
        // CONSTANTS
        // ====================================================

        dut.memory.mem[24] = 32'h00002000; // UART base
        dut.memory.mem[25] = 32'h00001000; // DMA base

        #20;
        rst = 0;

        // CPU + DMA + UART
        repeat (1000)
            @(posedge clk);

        // ====================================================
        // CHECK DMA
        // ====================================================

        if (dut.memory.mem[20] !== 32'hAAAA1111) begin
            $display("FAIL: DMA word 0 = %h", dut.memory.mem[20]);
            $finish;
        end

        if (dut.memory.mem[21] !== 32'hBBBB2222) begin
            $display("FAIL: DMA word 1 = %h", dut.memory.mem[21]);
            $finish;
        end

        if (dut.memory.mem[22] !== 32'hCCCC3333) begin
            $display("FAIL: DMA word 2 = %h", dut.memory.mem[22]);
            $finish;
        end

        if (dut.memory.mem[23] !== 32'hDDDD4444) begin
            $display("FAIL: DMA word 3 = %h", dut.memory.mem[23]);
            $finish;
        end

        $display("PASS: DMA DATA TRANSFER");

        // ====================================================
        // CHECK UART
        // ====================================================

        if (!uart_start_seen) begin
            $display("FAIL: UART START BIT");
            $finish;
        end

        $display("PASS: UART TX THROUGH BUS");

        // ====================================================
        // CHECK DMA IRQ
        // ====================================================

        if (!dma_irq_seen) begin
            $display("FAIL: DMA IRQ");
            $finish;
        end

        $display("PASS: DMA IRQ");
        $display("PASS: STEP 7 CPU + DMA + UART + BUS + BRAM");

        $finish;
    end

endmodule
