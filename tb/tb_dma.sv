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

    // ==========================
    // DMA
    // ==========================

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

    // Clock 100 MHz
    always #5 clk = ~clk;

    // ==========================
    // Memory model
    // ==========================

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

    // ==========================
    // Ghi thanh ghi DMA
    // ==========================

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

    end
    endtask

    // ==========================
    // Test
    // ==========================

    initial begin

        clk = 1'b0;
        rst = 1'b1;

        valid = 1'b0;
        we = 1'b0;
        addr = 5'b0;
        wdata = 32'b0;
        mem_ready = 1'b0;
        mem_rdata = 32'b0;

        // Dữ liệu nguồn
        memory[0] = 32'hAAAA_1111;
        memory[1] = 32'hBBBB_2222;
        memory[2] = 32'hCCCC_3333;
        memory[3] = 32'hDDDD_4444;

        #20;
        rst = 1'b0;

        // SRC = 0x0000
        write_reg(5'h00, 32'h0000_0000);

        // DST = 0x0010
        write_reg(5'h04, 32'h0000_0010);

        // LENGTH = 4 word
        write_reg(5'h08, 32'd4);

        // START
        write_reg(5'h0C, 32'h0000_0001);

        // Chờ DMA hoàn thành
        wait (irq);

        #10;

        // ==========================
        // Kiểm tra kết quả
        // ==========================

        if (memory[4] == 32'hAAAA_1111 &&
            memory[5] == 32'hBBBB_2222 &&
            memory[6] == 32'hCCCC_3333 &&
            memory[7] == 32'hDDDD_4444) begin

            $display("PASS: DMA TRANSFER OK");

        end
        else begin

            $display("FAIL: DMA TRANSFER");

            $display("MEM[4] = %h", memory[4]);
            $display("MEM[5] = %h", memory[5]);
            $display("MEM[6] = %h", memory[6]);
            $display("MEM[7] = %h", memory[7]);

        end

        $display("==============================");
        $display("STEP 2: DMA CONTROLLER");
        $display("==============================");

        $finish;

    end

endmodule
