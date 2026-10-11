`timescale 1ns/1ps

module soc_step6 (
    input logic clk,
    input logic rst,
    output logic dma_irq
);

    // =========================
    // CPU
    // =========================
    logic [31:0] instr_addr;
    logic [31:0] instr_rdata;

    logic        data_valid;
    logic        data_we;
    logic [31:0] data_addr;
    logic [31:0] data_wdata;
    logic [31:0] data_rdata;
    logic        data_ready;

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

    // =========================
    // Internal bus
    // =========================
    logic        bus_rdata_valid;
    logic [31:0] bus_rdata;
    logic        bus_ready;

    logic        bram_valid;
    logic        bram_we;
    logic [9:0]  bram_addr;
    logic [31:0] bram_wdata;
    logic [31:0] bram_rdata;
    logic        bram_ready;

    logic        dma_valid;
    logic        dma_we;
    logic [4:0]  dma_addr;
    logic [31:0] dma_wdata;
    logic [31:0] dma_rdata;
    logic        dma_ready;

    internal_bus bus (
        .clk(clk),
        .rst(rst),

        .m_valid(data_valid),
        .m_we(data_we),
        .m_addr(data_addr),
        .m_wdata(data_wdata),

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

    assign data_rdata  = bus_rdata;
    assign data_ready  = bus_ready;

    // =========================
    // DMA
    // =========================
    logic        dma_mem_valid;
    logic        dma_mem_we;
    logic [9:0]  dma_mem_addr;
    logic [31:0] dma_mem_wdata;
    logic [31:0] dma_mem_rdata;
    logic        dma_mem_ready;

    dma_controller dma (
        .clk(clk),
        .rst(rst),

        .valid(dma_valid),
        .we(dma_we),
        .addr(dma_addr),
        .wdata(dma_wdata),

        .rdata(dma_rdata),
        .ready(dma_ready),

        .mem_valid(dma_mem_valid),
        .mem_we(dma_mem_we),
        .mem_addr(dma_mem_addr),
        .mem_wdata(dma_mem_wdata),
        .mem_rdata(dma_mem_rdata),
        .mem_ready(dma_mem_ready),

        .irq(dma_irq)
    );

    // =========================
    // BRAM
    // =========================
    bram memory (
        .clk(clk),
        .rst(rst),

        // Port A: CPU
        .valid_a(bram_valid),
        .we_a(bram_we),
        .addr_a(bram_addr),
        .wdata_a(bram_wdata),
        .ready_a(bram_ready),
        .rdata_a(bram_rdata),

        // Port B: DMA
        .valid_b(dma_mem_valid),
        .we_b(dma_mem_we),
        .addr_b(dma_mem_addr),
        .wdata_b(dma_mem_wdata),
        .ready_b(dma_mem_ready),
        .rdata_b(dma_mem_rdata)
    );

    // =========================
    // Instruction memory
    // =========================
    assign instr_rdata = memory.mem[instr_addr[11:2]];

endmodule
