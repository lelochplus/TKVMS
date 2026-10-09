`timescale 1ns/1ps

module tb_soc_step3;

    logic clk;
    logic rst;

    logic        valid;
    logic        we;
    logic [31:0] addr;
    logic [31:0] wdata;

    logic [31:0] rdata;
    logic        ready;
    logic        irq;

    soc_step3 dut (
        .clk   (clk),
        .rst   (rst),

        .valid (valid),
        .we    (we),
        .addr  (addr),
        .wdata (wdata),

        .rdata (rdata),
        .ready (ready),

        .irq   (irq)
    );

    always #5 clk = ~clk;

    task write_mem(
        input [31:0] a,
        input [31:0] d
    );
    begin

        @(negedge clk);

        valid = 1;
        we    = 1;
        addr  = a;
        wdata = d;

        @(negedge clk);

        valid = 0;
        we    = 0;

    end
    endtask

    task write_dma(
        input [31:0] a,
        input [31:0] d
    );
    begin

        @(negedge clk);

        valid = 1;
        we    = 1;
        addr  = a;
        wdata = d;

        @(negedge clk);

        valid = 0;
        we    = 0;

    end
    endtask

    initial begin

        clk = 0;
        rst = 1;

        valid = 0;
        we = 0;
        addr = 0;
        wdata = 0;

        #20;
        rst = 0;

        // ==========================
        // Ghi dữ liệu nguồn vào BRAM
        // ==========================

        write_mem(32'h0000_0000, 32'hAAAA_1111);
        write_mem(32'h0000_0004, 32'hBBBB_2222);
        write_mem(32'h0000_0008, 32'hCCCC_3333);
        write_mem(32'h0000_000C, 32'hDDDD_4444);

        // ==========================
        // Cấu hình DMA
        // ==========================

        // SRC = 0x0000
        write_dma(32'h0000_1000, 32'h0000_0000);

        // DST = 0x0010
        write_dma(32'h0000_1004, 32'h0000_0010);

        // LENGTH = 4
        write_dma(32'h0000_1008, 32'd4);

        // START
        write_dma(32'h0000_100C, 32'h1);

        // ==========================
        // Chờ DMA hoàn thành
        // ==========================

        wait(irq);

        #10;

        // ==========================
        // Kiểm tra BRAM
        // ==========================

        if (dut.memory.mem[4] == 32'hAAAA_1111 &&
            dut.memory.mem[5] == 32'hBBBB_2222 &&
            dut.memory.mem[6] == 32'hCCCC_3333 &&
            dut.memory.mem[7] == 32'hDDDD_4444) begin

            $display("PASS: DMA + BUS + BRAM OK");

        end
        else begin

            $display("FAIL: DMA + BUS + BRAM");

            $display("MEM[4] = %h", dut.memory.mem[4]);
            $display("MEM[5] = %h", dut.memory.mem[5]);
            $display("MEM[6] = %h", dut.memory.mem[6]);
            $display("MEM[7] = %h", dut.memory.mem[7]);

        end

        $display("==============================");
        $display("STEP 3: DMA + BUS + BRAM");
        $display("==============================");

        $finish;

    end

endmodule
