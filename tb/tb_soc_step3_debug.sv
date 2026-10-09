`timescale 1ns/1ps

module tb_soc_step3_debug;

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

    task write_reg(
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
        addr  = 0;
        wdata = 0;
    end
    endtask

    initial begin
        $monitor(
            "T=%0t STATE=%0d valid=%b we=%b addr=%h ready=%b DMA_V=%b DMA_WE=%b DMA_ADDR=%0d BRAM_V=%b BRAM_WE=%b BRAM_ADDR=%0d IRQ=%b",
            $time,
            dut.dma.state,
            valid,
            we,
            addr,
            ready,
            dut.dma_mem_valid,
            dut.dma_mem_we,
            dut.dma_mem_addr,
            dut.bus_bram_valid,
            dut.bus_bram_we,
            dut.bus_bram_addr,
            irq
        );
    end

    initial begin

        clk   = 0;
        rst   = 1;

        valid = 0;
        we    = 0;
        addr  = 0;
        wdata = 0;

        // Dữ liệu nguồn
        #1;
        dut.memory.mem[0] = 32'hAAAA_1111;
        dut.memory.mem[1] = 32'hBBBB_2222;
        dut.memory.mem[2] = 32'hCCCC_3333;
        dut.memory.mem[3] = 32'hDDDD_4444;

        #19;
        rst = 0;

        $display("========== CONFIG DMA ==========");

        write_reg(32'h0000_1000, 32'h0000_0000);
        write_reg(32'h0000_1004, 32'h0000_0010);
        write_reg(32'h0000_1008, 32'd4);
        write_reg(32'h0000_100C, 32'h0000_0001);

        repeat (30) @(posedge clk);

        $display("========== RESULT ==========");
        $display("IRQ = %b", irq);
        $display("MEM[4] = %h", dut.memory.mem[4]);
        $display("MEM[5] = %h", dut.memory.mem[5]);
        $display("MEM[6] = %h", dut.memory.mem[6]);
        $display("MEM[7] = %h", dut.memory.mem[7]);

        $finish;
    end

endmodule
