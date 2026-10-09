module internal_bus (
    input logic        clk,
    input logic        rst,

    // Master
    input logic        m_valid,
    input logic        m_we,
    input logic [31:0] m_addr,
    input logic [31:0] m_wdata,

    output logic [31:0] m_rdata,
    output logic        m_ready,

    // BRAM
    output logic        bram_valid,
    output logic        bram_we,
    output logic [9:0]  bram_addr,
    output logic [31:0] bram_wdata,

    input logic [31:0] bram_rdata,
    input logic        bram_ready,

    // DMA
    output logic        dma_valid,
    output logic        dma_we,
    output logic [4:0]  dma_addr,
    output logic [31:0] dma_wdata,

    input logic [31:0] dma_rdata,
    input logic        dma_ready
);

    // =========================================
    // Address decode
    // =========================================

    wire sel_dma  = m_valid &&
                    (m_addr >= 32'h0000_1000) &&
                    (m_addr <  32'h0000_1100);

    wire sel_bram = m_valid &&
                    (m_addr < 32'h0000_1000);

    // =========================================
    // DMA interface
    // =========================================

    assign dma_valid = sel_dma;
    assign dma_we    = m_we;
    assign dma_addr  = m_addr[4:0];
    assign dma_wdata = m_wdata;

    // =========================================
    // BRAM interface
    // =========================================

    assign bram_valid = sel_bram;
    assign bram_we    = m_we;
    assign bram_addr  = m_addr[11:2];
    assign bram_wdata = m_wdata;

    // =========================================
    // Master response
    // =========================================

    assign m_ready = sel_dma  ? dma_ready :
                     sel_bram ? bram_ready :
                     1'b0;

    assign m_rdata = sel_dma  ? dma_rdata :
                     sel_bram ? bram_rdata :
                     32'b0;

endmodule
