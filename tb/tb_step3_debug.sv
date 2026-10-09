`timescale 1ns/1ps

module tb_step3_debug;

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

    initial begin
        $monitor(
            "T=%0t clk=%b rst=%b valid=%b we=%b addr=%h ready=%b irq=%b",
            $time, clk, rst, valid, we, addr, ready, irq
        );
    end

    initial begin
        clk   = 0;
        rst   = 1;
        valid = 0;
        we    = 0;
        addr  = 0;
        wdata = 0;

        #20;

        $display("DEBUG: release reset");
        rst = 0;

        // Ghi BRAM
        @(negedge clk);
        valid = 1;
        we    = 1;
        addr  = 32'h0000_0000;
        wdata = 32'hAAAA_1111;

        @(negedge clk);
        valid = 0;
        we    = 0;

        $display("DEBUG: BRAM write done");

        #20;

        $display("DEBUG: testbench still running");

        $finish;
    end

endmodule
