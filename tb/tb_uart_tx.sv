`timescale 1ns/1ps

module tb_uart_tx;

    logic clk;
    logic rst;

    logic        valid;
    logic        we;
    logic [4:0]  addr;
    logic [31:0] wdata;

    logic [31:0] rdata;
    logic        ready;
    logic        tx;

    uart_tx #(
        .CLK_FREQ(10),
        .BAUD_RATE(1)
    ) dut (
        .clk(clk),
        .rst(rst),
        .valid(valid),
        .we(we),
        .addr(addr),
        .wdata(wdata),
        .rdata(rdata),
        .ready(ready),
        .tx(tx)
    );

    always #5 clk = ~clk;

    initial begin
        clk   = 0;
        rst   = 1;
        valid = 0;
        we    = 0;
        addr  = 0;
        wdata = 0;

        #20;
        rst = 0;

        // Kiểm tra TX_READY
        @(negedge clk);
        valid = 1;
        we    = 0;
        addr  = 5'h04;

        @(negedge clk);

        if (rdata[0] !== 1'b1) begin
            $display("FAIL: UART TX_READY");
            $finish;
        end

        // Gửi ký tự A
        @(negedge clk);
        valid = 1;
        we    = 1;
        addr  = 5'h00;
        wdata = 32'h41;

        @(negedge clk);
        valid = 0;
        we    = 0;

        // Chờ truyền xong
        repeat (120)
            @(posedge clk);

        if (dut.busy !== 1'b0) begin
            $display("FAIL: UART BUSY");
            $finish;
        end

        $display("PASS: UART TX");
        $finish;
    end

endmodule
