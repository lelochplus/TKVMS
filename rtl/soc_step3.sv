module soc_step3 (
    input logic clk,
    input logic rst,

    // =========================
    // Master / CPU interface
    // =========================
    input logic        valid,
    input logic        we,
    input logic [31:0] addr,
    input logic [31:0] wdata,

    output logic [31:0] rdata,
    output logic        ready,
    output logic        irq
);

    // =========================================================
    // BUS -> BRAM
    // =========================================================

    logic        bus_bram_valid;
    logic        bus_bram_we;
    logic [9:0]  bus_bram_addr;
    logic [31:0] bus_bram_wdata;

    logic [31:0] bus_bram_rdata;
    logic        bus_bram_ready;

    // =========================================================
    // BUS -> DMA
    // =========================================================

    logic        dma_valid;
    logic        dma_we;
    logic [4:0]  dma_addr;
    logic [31:0] dma_wdata;

    logic [31:0] dma_rdata;
    logic        dma_ready;

    // =========================================================
    // DMA -> BRAM
    // =========================================================

    logic        dma_mem_valid;
    logic        dma_mem_we;
    logic [9:0]  dma_mem_addr;
    logic [31:0] dma_mem_wdata;

    logic [31:0] dma_mem_rdata;
    logic        dma_mem_ready;

    // =========================================================
    // BRAM
    // =========================================================

    bram memory (
        .clk(clk),
        .rst(rst),

        // Port A: CPU / Bus
        .valid_a(bus_bram_valid),
        .we_a(bus_bram_we),
        .addr_a(bus_bram_addr),
        .wdata_a(bus_bram_wdata),
        .ready_a(bus_bram_ready),
        .rdata_a(bus_bram_rdata),

        // Port B: DMA
        .valid_b(dma_mem_valid),
        .we_b(dma_mem_we),
        .addr_b(dma_mem_addr),
        .wdata_b(dma_mem_wdata),
        .ready_b(dma_mem_ready),
        .rdata_b(dma_mem_rdata)
    );

    // =========================================================
    // Internal Bus
    // =========================================================

    internal_bus bus (
        .clk(clk),
        .rst(rst),

        .m_valid(valid),
        .m_we(we),
        .m_addr(addr),
        .m_wdata(wdata),

        .m_rdata(rdata),
        .m_ready(ready),

        .bram_valid(bus_bram_valid),
        .bram_we(bus_bram_we),
        .bram_addr(bus_bram_addr),
        .bram_wdata(bus_bram_wdata),

        .bram_rdata(bus_bram_rdata),
        .bram_ready(bus_bram_ready),

        .dma_valid(dma_valid),
        .dma_we(dma_we),
        .dma_addr(dma_addr),
        .dma_wdata(dma_wdata),

        .dma_rdata(dma_rdata),
        .dma_ready(dma_ready)
    );

    // =========================================================
    // DMA Controller
    // =========================================================

    dma_controller dma (
        .clk(clk),
        .rst(rst),

        // Register interface
        .valid(dma_valid),
        .we(dma_we),
        .addr(dma_addr),
        .wdata(dma_wdata),

        .rdata(dma_rdata),
        .ready(dma_ready),

        // Memory interface
        .mem_valid(dma_mem_valid),
        .mem_we(dma_mem_we),
        .mem_addr(dma_mem_addr),
        .mem_wdata(dma_mem_wdata),

        .mem_rdata(dma_mem_rdata),
        .mem_ready(dma_mem_ready),

        .irq(irq)
    );

endmodule
