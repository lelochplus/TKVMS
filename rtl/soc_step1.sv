module soc_step1 (
    input logic clk, rst,
    input logic valid, we,
    input logic [31:0] addr, wdata,
    output logic [31:0] rdata,
    output logic ready
);

logic bram_valid, bram_we;
logic [9:0] bram_addr;
logic [31:0] bram_wdata, bram_rdata;
logic bram_ready;

logic dma_valid, dma_we;
logic [4:0] dma_addr;
logic [31:0] dma_wdata, dma_rdata;
logic dma_ready;

assign dma_rdata = 32'b0;
assign dma_ready = 1'b0;

internal_bus bus (
    .clk(clk), .rst(rst),
    .m_valid(valid), .m_we(we),
    .m_addr(addr), .m_wdata(wdata),
    .m_rdata(rdata), .m_ready(ready),

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
    .clk(clk), .rst(rst),

    .valid_a(bram_valid),
    .we_a(bram_we),
    .addr_a(bram_addr),
    .wdata_a(bram_wdata),
    .ready_a(bram_ready),
    .rdata_a(bram_rdata),

    .valid_b(1'b0),
    .we_b(1'b0),
    .addr_b(10'b0),
    .wdata_b(32'b0),
    .ready_b(),
    .rdata_b()
);

endmodule
