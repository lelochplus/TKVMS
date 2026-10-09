`timescale 1ns/1ps

module tb_soc_step1;

    logic        clk;
    logic        rst;

    logic        valid;
    logic        we;
    logic [31:0] addr;
    logic [31:0] wdata;

    logic [31:0] rdata;
    logic        ready;

    soc_step1 dut (
        .clk   (clk),
        .rst   (rst),

        .valid (valid),
        .we    (we),
        .addr  (addr),
        .wdata (wdata),

        .rdata (rdata),
        .ready (ready)
    );

    always #5 clk = ~clk;

    initial begin

        clk   = 0;
        rst   = 1;
        valid = 0;
        we    = 0;
        addr  = 0;
        wdata = 0;

        // Reset
        #20;
        rst = 0;

        // ==========================
        // WRITE 4 địa chỉ
        // ==========================

        @(negedge clk);
        valid = 1;
        we    = 1;
        addr  = 32'h0000_0000;
        wdata = 32'h1111_1111;

        @(negedge clk);
        addr  = 32'h0000_0004;
        wdata = 32'h2222_2222;

        @(negedge clk);
        addr  = 32'h0000_0008;
        wdata = 32'h3333_3333;

        @(negedge clk);
        addr  = 32'h0000_000C;
        wdata = 32'h4444_4444;

        @(negedge clk);
        valid = 0;
        we    = 0;

        // ==========================
        // READ địa chỉ 0x0000
        // ==========================

        @(negedge clk);
        valid = 1;
        addr  = 32'h0000_0000;

        @(posedge clk);
        #1;

        if (ready && rdata == 32'h1111_1111)
            $display("PASS: ADDR 0x0000");
        else
            $display("FAIL: ADDR 0x0000 - rdata = %h ready = %b",
                     rdata, ready);

        // ==========================
        // READ địa chỉ 0x0004
        // ==========================

        @(negedge clk);
        addr = 32'h0000_0004;

        @(posedge clk);
        #1;

        if (ready && rdata == 32'h2222_2222)
            $display("PASS: ADDR 0x0004");
        else
            $display("FAIL: ADDR 0x0004 - rdata = %h ready = %b",
                     rdata, ready);

        // ==========================
        // READ địa chỉ 0x0008
        // ==========================

        @(negedge clk);
        addr = 32'h0000_0008;

        @(posedge clk);
        #1;

        if (ready && rdata == 32'h3333_3333)
            $display("PASS: ADDR 0x0008");
        else
            $display("FAIL: ADDR 0x0008 - rdata = %h ready = %b",
                     rdata, ready);

        // ==========================
        // READ địa chỉ 0x000C
        // ==========================

        @(negedge clk);
        addr = 32'h0000_000C;

        @(posedge clk);
        #1;

        if (ready && rdata == 32'h4444_4444)
            $display("PASS: ADDR 0x000C");
        else
            $display("FAIL: ADDR 0x000C - rdata = %h ready = %b",
                     rdata, ready);

        valid = 0;

        #20;

        $display("==============================");
        $display("STEP 1: INTERNAL BUS + BRAM");
        $display("STEP 1 COMPLETED");
        $display("==============================");

        $finish;

    end

endmodule
