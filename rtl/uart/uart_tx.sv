module uart_tx #(
    parameter integer CLK_FREQ = 50_000_000,
    parameter integer BAUD_RATE = 115_200
)(
    input  logic clk,
    input  logic rst,

    input  logic       valid,
    input  logic       we,
    input  logic [4:0] addr,
    input  logic [31:0] wdata,

    output logic [31:0] rdata,
    output logic        ready,

    output logic tx
);

    localparam integer BAUD_DIV = CLK_FREQ / BAUD_RATE;

    logic [31:0] baud_count;
    logic [9:0]  shift_reg;
    logic [3:0]  bit_count;
    logic        busy;

    wire tx_ready = ~busy;

    always_ff @(posedge clk) begin
        if (rst) begin
            baud_count <= 0;
            shift_reg  <= 10'b1111111111;
            bit_count  <= 0;
            busy       <= 1'b0;
        end else begin

            if (!busy) begin
                baud_count <= 0;
                bit_count  <= 0;

                if (valid && we && addr == 5'h00) begin
                    shift_reg <= {1'b1, wdata[7:0], 1'b0};
                    busy      <= 1'b1;
                end

            end else begin

                if (baud_count == BAUD_DIV - 1) begin
                    baud_count <= 0;

                    if (bit_count == 9) begin
                        busy      <= 1'b0;
                        bit_count <= 0;
                        shift_reg <= 10'b1111111111;
                    end else begin
                        shift_reg <= {1'b1, shift_reg[9:1]};
                        bit_count <= bit_count + 1'b1;
                    end

                end else begin
                    baud_count <= baud_count + 1'b1;
                end

            end
        end
    end

    assign tx = shift_reg[0];

    always_comb begin
        rdata = 32'b0;

        case (addr)
            5'h00: rdata = 32'b0;
            5'h04: rdata = {31'b0, tx_ready};
            default: rdata = 32'b0;
        endcase
    end

    assign ready = valid && (
                   (addr == 5'h04) ||
                   (addr == 5'h00 && we && tx_ready)
                   );

endmodule
