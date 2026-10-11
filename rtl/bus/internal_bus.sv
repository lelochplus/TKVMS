module internal_bus (
    input logic clk, rst,
    input logic m_valid, m_we,
    input logic [31:0] m_addr, m_wdata,
    output logic [31:0] m_rdata,
    output logic m_ready,

    output logic bram_valid, bram_we,
    output logic [9:0] bram_addr,
    output logic [31:0] bram_wdata,
    input logic [31:0] bram_rdata,
    input logic bram_ready,

    output logic dma_valid, dma_we,
    output logic [4:0] dma_addr,
    output logic [31:0] dma_wdata,
    input logic [31:0] dma_rdata,
    input logic dma_ready,

    output logic uart_valid, uart_we,
    output logic [4:0] uart_addr,
    output logic [31:0] uart_wdata,
    input logic [31:0] uart_rdata,
    input logic uart_ready
);

    wire sel_dma =
        m_valid &&
        (m_addr >= 32'h0000_1000) &&
        (m_addr <  32'h0000_1100);

    wire sel_bram =
        m_valid &&
        (m_addr < 32'h0000_1000);

    wire sel_uart =
        m_valid &&
        (m_addr >= 32'h0000_2000) &&
        (m_addr <  32'h0000_2100);

    assign dma_valid = sel_dma;
    assign dma_we    = m_we;
    assign dma_addr  = m_addr[4:0];
    assign dma_wdata = m_wdata;

    assign bram_valid = sel_bram;
    assign bram_we    = m_we;
    assign bram_addr  = m_addr[11:2];
    assign bram_wdata = m_wdata;

    assign uart_valid = sel_uart;
    assign uart_we    = m_we;
    assign uart_addr  = m_addr[4:0];
    assign uart_wdata = m_wdata;

    assign m_ready =
        sel_dma  ? dma_ready  :
        sel_bram ? bram_ready :
        sel_uart ? uart_ready :
        1'b0;

    assign m_rdata =
        sel_dma  ? dma_rdata  :
        sel_bram ? bram_rdata :
        sel_uart ? uart_rdata :
        32'b0;

endmodule
