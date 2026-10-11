`timescale 1ns/1ps

module soc_step5 (
    input  logic        clk,
    input  logic        rst
);

    // CPU
    logic [31:0] instr_addr;
    logic [31:0] instr_rdata;

    logic        data_valid;
    logic        data_we;
    logic [31:0] data_addr;
    logic [31:0] data_wdata;
    logic [31:0] data_rdata;
    logic        data_ready;

    // CPU
    rv32i_cpu cpu (
        .clk(clk),
        .rst(rst),

        .instr_addr(instr_addr),
        .instr_rdata(instr_rdata),

        .data_valid(data_valid),
        .data_we(data_we),
        .data_addr(data_addr),
        .data_wdata(data_wdata),
        .data_rdata(data_rdata),
        .data_ready(data_ready)
    );

    // Internal bus
    logic        bus_valid;
    logic        bus_we;
    logic [31:0] bus_addr;
    logic [31:0] bus_wdata;
    logic [31:0] bus_rdata;
    logic        bus_ready;

    assign bus_valid = data_valid;
    assign bus_we    = data_we;
    assign bus_addr  = data_addr;
    assign bus_wdata = data_wdata;

    assign data_rdata = bus_rdata;
    assign data_ready = bus_ready;

    // BRAM
    logic        bram_valid;
    logic        bram_we;
    logic [9:0]  bram_addr;
    logic [31:0] bram_wdata;
    logic [31:0] bram_rdata;
    logic        bram_ready;

    // DMA chưa sử dụng ở Step 5
    logic        dma_valid;
    logic        dma_we;
    logic [4:0]  dma_addr;
    logic [31:0] dma_wdata;
    logic [31:0] dma_rdata;
    logic        dma_ready;

    assign dma_rdata = 32'b0;
    assign dma_ready = 1'b0;

    internal_bus bus (
        .clk(clk),
        .rst(rst),

        .m_valid(bus_valid),
        .m_we(bus_we),
        .m_addr(bus_addr),
        .m_wdata(bus_wdata),

        .m_rdata(bus_rdata),
        .m_ready(bus_ready),

        .bram_valid(bram_valid),
        .bram_we(bram_we),
        .bram_addr(bram_addr),
        .bram_wdata(bram_wdata),
        .bram_rdata(bram_rdata),
        .bram_ready(bram_ready),

        .dma_valid(dma_valid),
        .dma_we(dma_we),
        .dma_addr(dma_addr),
        .dma_wdata(dma_wdata),
        .dma_rdata(dma_rdata),
        .dma_ready(dma_ready)
    );

    bram memory (
        .clk(clk),
        .rst(rst),

        .valid_a(bram_valid),
        .we_a(bram_we),
        .addr_a(bram_addr),
        .wdata_a(bram_wdata),
        .ready_a(bram_ready),
        .rdata_a(bram_rdata),

        // Port B chưa sử dụng
        .valid_b(1'b0),
        .we_b(1'b0),
        .addr_b(10'b0),
        .wdata_b(32'b0),
        .ready_b(),
        .rdata_b()
    );

    // Cổng đọc lệnh dùng trực tiếp BRAM
    assign instr_rdata = memory.mem[instr_addr[11:2]];

endmodule
