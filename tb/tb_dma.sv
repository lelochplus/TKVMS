`timescale 1ns/1ps

module tb_dma;

    logic clk;
    logic rst;

    logic        valid;
    logic        we;
    logic [4:0]  addr;
    logic [31:0] wdata;

    logic [31:0] rdata;
    logic        ready;

    logic        mem_valid;
    logic        mem_we;
    logic [9:0]  mem_addr;
    logic [31:0] mem_wdata;
    logic [31:0] mem_rdata;
    logic        mem_ready;

    logic irq;

    logic [31:0] memory [0:1023];

    integer errors;

    dma_controller dma (
        .clk       (clk),
        .rst       (rst),

        .valid     (valid),
        .we        (we),
        .addr      (addr),
        .wdata     (wdata),

        .rdata     (rdata),
        .ready     (ready),

        .mem_valid (mem_valid),
        .mem_we    (mem_we),
        .mem_addr  (mem_addr),
        .mem_wdata (mem_wdata),
        .mem_rdata (mem_rdata),
        .mem_ready (mem_ready),

        .irq       (irq)
    );

    always #5 clk = ~clk;

    // =========================================
    // Memory model
    // =========================================

    always_ff @(posedge clk) begin

        mem_ready <= 1'b0;

        if (mem_valid) begin

            mem_ready <= 1'b1;

            if (mem_we)
                memory[mem_addr] <= mem_wdata;
            else
                mem_rdata <= memory[mem_addr];

        end

    end

    // =========================================
    // Write DMA register
    // =========================================

    task write_reg(
        input [4:0] a,
        input [31:0] d
    );
    begin

        @(negedge clk);

        valid = 1'b1;
        we    = 1'b1;
        addr  = a;
        wdata = d;

        @(negedge clk);

        valid = 1'b0;
        we    = 1'b0;
        addr  = 5'b0;
        wdata = 32'b0;

    end
    endtask

    // =========================================
    // Read DMA register
    // =========================================

    task read_reg(
        input [4:0] a,
        output [31:0] d
    );
    begin

        @(negedge clk);

        valid = 1'b1;
        we    = 1'b0;
        addr  = a;

        #1;
        d = rdata;

        @(negedge clk);

        valid = 1'b0;
        addr  = 5'b0;

    end
    endtask

    // =========================================
    // Check
    // =========================================

    task check(
        input logic condition,
        input [255:0] message
    );
    begin

        if (condition) begin
            $display("PASS: %s", message);
        end
        else begin
            $display("FAIL: %s", message);
            errors = errors + 1;
        end

    end
    endtask

    // =========================================
    // Test
    // =========================================

    reg [31:0] status;

    initial begin

        clk = 1'b0;
        rst = 1'b1;

        valid = 1'b0;
        we = 1'b0;
        addr = 5'b0;
        wdata = 32'b0;

        mem_ready = 1'b0;
        mem_rdata = 32'b0;

        errors = 0;

        // -----------------------------------------
        // Source data
        // -----------------------------------------

        memory[0] = 32'hAAAA_1111;
        memory[1] = 32'hBBBB_2222;
        memory[2] = 32'hCCCC_3333;
        memory[3] = 32'hDDDD_4444;

        #20;
        rst = 1'b0;

        // =========================================
        // TEST 1: DMA transfer
        // =========================================

        write_reg(5'h00, 32'h0000_0000);
        write_reg(5'h04, 32'h0000_0010);
        write_reg(5'h08, 32'd4);

        // Enable interrupt
        write_reg(5'h14, 32'h0000_0001);

        // Start
        write_reg(5'h0C, 32'h0000_0001);

        wait (irq);

        check(
            memory[4] == 32'hAAAA_1111 &&
            memory[5] == 32'hBBBB_2222 &&
            memory[6] == 32'hCCCC_3333 &&
            memory[7] == 32'hDDDD_4444,
            "DMA DATA TRANSFER"
        );

        // =========================================
        // TEST 2: DONE sticky
        // =========================================

        read_reg(5'h10, status);

        check(
            status[1] == 1'b1,
            "DONE STICKY"
        );

        // =========================================
        // TEST 3: IRQ sticky
        // =========================================

        #50;

        check(
            irq == 1'b1,
            "IRQ STICKY"
        );

        // =========================================
        // TEST 4: INT_STATUS
        // =========================================

        read_reg(5'h18, status);

        check(
            status[0] == 1'b1,
            "INT_STATUS SET"
        );

        // =========================================
        // TEST 5: Clear interrupt
        // =========================================

        write_reg(5'h18, 32'h0000_0001);

        #10;

        check(
            irq == 1'b0,
            "IRQ CLEAR"
        );

        read_reg(5'h18, status);

        check(
            status[0] == 1'b0,
            "INT_STATUS CLEAR"
        );

        // =========================================
        // TEST 6: LENGTH = 0
        // =========================================

        write_reg(5'h08, 32'd0);
        write_reg(5'h0C, 32'h0000_0001);

        #20;

        read_reg(5'h10, status);

        check(
            status[1] == 1'b1 &&
            status[0] == 1'b0,
            "LENGTH ZERO"
        );

        // Clear interrupt
        write_reg(5'h18, 32'h0000_0001);

        // =========================================
        // TEST 7: Invalid address
        // =========================================

        write_reg(5'h00, 32'h0000_1000);
        write_reg(5'h04, 32'h0000_0020);
        write_reg(5'h08, 32'd1);

        write_reg(5'h0C, 32'h0000_0001);

        #20;

        read_reg(5'h10, status);

        check(
            status[2] == 1'b1,
            "INVALID ADDRESS"
        );

        // =========================================
        // TEST 8: Latch SRC/DST/LENGTH
        // =========================================

        // Dữ liệu nguồn mới
        memory[8]  = 32'h1111_AAAA;
        memory[9]  = 32'h2222_BBBB;
        memory[10] = 32'h3333_CCCC;
        memory[11] = 32'h4444_DDDD;

        // Cấu hình DMA
        write_reg(5'h00, 32'h0000_0020);
        write_reg(5'h04, 32'h0000_0040);
        write_reg(5'h08, 32'd4);

        // START
        write_reg(5'h0C, 32'h0000_0001);

        // Thay đổi register ngay sau START
        write_reg(5'h00, 32'h0000_0000);
        write_reg(5'h04, 32'h0000_0000);
        write_reg(5'h08, 32'd1);

        // Chờ DMA hoàn thành
        wait (irq);

        check(
            memory[16] == 32'h1111_AAAA &&
            memory[17] == 32'h2222_BBBB &&
            memory[18] == 32'h3333_CCCC &&
            memory[19] == 32'h4444_DDDD,
            "START PARAMETER LATCH"
        );

        // Clear interrupt
        write_reg(5'h18, 32'h0000_0001);

        // =========================================
        // TEST 9: Summary
        // =========================================

        $display("==============================");

        if (errors == 0) begin
            $display("STEP 11.1: PASS");
        end
        else begin
            $display("STEP 11.1: FAIL (%0d errors)", errors);
        end

        $display("==============================");

        $finish;

    end

endmodule
