module bram #(
    parameter ADDR_WIDTH = 10,
    parameter DATA_WIDTH = 32
)(
    input logic clk,
    input logic rst,

    // =========================
    // Port A - CPU / Bus
    // =========================
    input logic valid_a,
    input logic we_a,
    input logic [ADDR_WIDTH-1:0] addr_a,
    input logic [DATA_WIDTH-1:0] wdata_a,
    output logic ready_a,
    output logic [DATA_WIDTH-1:0] rdata_a,

    // =========================
    // Port B - DMA
    // =========================
    input logic valid_b,
    input logic we_b,
    input logic [ADDR_WIDTH-1:0] addr_b,
    input logic [DATA_WIDTH-1:0] wdata_b,
    output logic ready_b,
    output logic [DATA_WIDTH-1:0] rdata_b,

    // Instruction fetch
    input  logic [ADDR_WIDTH-1:0] instr_addr,
    output logic [DATA_WIDTH-1:0] instr_rdata
);

    localparam DEPTH = 1 << ADDR_WIDTH;

    logic [DATA_WIDTH-1:0] mem [0:DEPTH-1];

    assign instr_rdata = mem[instr_addr];

    always_ff @(posedge clk) begin

        if (rst) begin
            ready_a <= 1'b0;
            ready_b <= 1'b0;
            rdata_a <= '0;
            rdata_b <= '0;
        end
        else begin

            ready_a <= 1'b0;
            ready_b <= 1'b0;

            // =========================
            // Port A - CPU / Bus
            // =========================
            if (valid_a) begin

                if (we_a) begin
                    mem[addr_a] <= wdata_a;
                    ready_a <= 1'b1;
                end
                else begin
                    rdata_a <= mem[addr_a];
                    ready_a <= 1'b1;
                end

            end

            // =========================
            // Port B - DMA
            // =========================
            if (valid_b) begin

                if (we_b) begin
                    mem[addr_b] <= wdata_b;
                    ready_b <= 1'b1;
                end
                else begin
                    rdata_b <= mem[addr_b];
                    ready_b <= 1'b1;
                end

            end

        end
    end

endmodule
