`timescale 1ns/1ps

module tb_dma_debug;

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

    // Mô hình bộ nhớ đơn giản
    always_comb begin
        mem_ready = mem_valid;

        if (mem_valid && !mem_we)
            mem_rdata = memory[mem_addr];
        else
            mem_rdata = 32'b0;
    end

    always_ff @(posedge clk) begin
        if (mem_valid && mem_we)
            memory[mem_addr] <= mem_wdata;
    end

    // Theo dõi DMA
    always @(posedge clk) begin
        $display(
            "T=%0t STATE=%0d VALID=%b WE=%b ADDR=%h MEM_V=%b MEM_WE=%b MEM_ADDR=%0d IRQ=%b",
            $time,
            dma.state,
            valid,
            we,
            addr,
            mem_valid,
            mem_we,
            mem_addr,
            irq
        );
    end

    task write_reg(
        input [4:0] a,
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

        clk   = 0;
        rst   = 1;

        valid = 0;
        we    = 0;
        addr  = 0;
        wdata = 0;

        memory[0] = 32'hAAAA_1111;
        memory[1] = 32'hBBBB_2222;
        memory[2] = 32'hCCCC_3333;
        memory[3] = 32'hDDDD_4444;

        #20;
        rst = 0;

        $display("========== CONFIG DMA ==========");

        write_reg(5'h00, 32'h0000_0000);
        write_reg(5'h04, 32'h0000_0010);
        write_reg(5'h08, 32'd4);
        write_reg(5'h0C, 32'h0000_0001);

        #200;

        $display("========== RESULT ==========");
        $display("MEM[4] = %h", memory[4]);
        $display("MEM[5] = %h", memory[5]);
        $display("MEM[6] = %h", memory[6]);
        $display("MEM[7] = %h", memory[7]);

        $finish;

    end

endmodule
