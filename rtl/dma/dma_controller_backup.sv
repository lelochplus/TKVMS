module dma_controller #(
    parameter ADDR_WIDTH = 10,
    parameter DATA_WIDTH = 32
)(
    input  logic                  clk,
    input  logic                  rst,

    // CPU / Bus interface
    input  logic                  valid,
    input  logic                  we,
    input  logic [4:0]            addr,
    input  logic [31:0]           wdata,
    output logic [31:0]           rdata,
    output logic                  ready,

    // Memory interface
    output logic                  mem_valid,
    output logic                  mem_we,
    output logic [ADDR_WIDTH-1:0] mem_addr,
    output logic [DATA_WIDTH-1:0] mem_wdata,
    input  logic [DATA_WIDTH-1:0] mem_rdata,
    input  logic                  mem_ready,

    // Interrupt
    output logic                  irq
);

    logic [31:0] src_addr;
    logic [31:0] dst_addr;
    logic [31:0] length;

    logic [31:0] read_data;
    logic [31:0] count;

    logic busy;
    logic done;

    typedef enum logic [1:0] {
        IDLE,
        READ,
        WRITE,
        DONE
    } state_t;

    state_t state;

    // ==========================
    // CPU ghi thanh ghi DMA
    // ==========================

    always_ff @(posedge clk) begin
        if (rst) begin
            src_addr <= 32'b0;
            dst_addr <= 32'b0;
            length   <= 32'b0;
        end
        else if (valid && we) begin
            case (addr)
                5'h00: src_addr <= wdata;
                5'h04: dst_addr <= wdata;
                5'h08: length   <= wdata;
                default: ;
            endcase
        end
    end

    // ==========================
    // DMA FSM
    // ==========================

    always_ff @(posedge clk) begin
        if (rst) begin
            state     <= IDLE;
            busy      <= 1'b0;
            done      <= 1'b0;
            irq       <= 1'b0;
            read_data <= 32'b0;
            count     <= 32'b0;
        end
        else begin
            irq <= 1'b0;

            case (state)

                IDLE: begin
                    busy <= 1'b0;
                    done <= 1'b0;

                    if (valid && we &&
                        addr == 5'h0C &&
                        wdata[0]) begin

                        busy  <= 1'b1;
                        count <= 32'b0;
                        state <= READ;
                    end
                end

                READ: begin
                    if (mem_ready) begin
                        read_data <= mem_rdata;
                        state <= WRITE;
                    end
                end

                WRITE: begin
                    if (mem_ready) begin
                        if (count + 1 >= length) begin
                            state <= DONE;
                        end
                        else begin
                            count <= count + 1;
                            state <= READ;
                        end
                    end
                end

                DONE: begin
                    busy  <= 1'b0;
                    done  <= 1'b1;
                    irq   <= 1'b1;
                    state <= IDLE;
                end

                default: begin
                    state <= IDLE;
                end

            endcase
        end
    end

    // ==========================
    // Memory interface
    // ==========================

    always_comb begin

        mem_valid = 1'b0;
        mem_we    = 1'b0;
        mem_addr  = '0;
        mem_wdata = 32'b0;

        case (state)

            READ: begin
                mem_valid = 1'b1;
                mem_we    = 1'b0;
                mem_addr  = (src_addr + count * 4) >> 2;
            end

            WRITE: begin
                mem_valid = 1'b1;
                mem_we    = 1'b1;
                mem_addr  = (dst_addr + count * 4) >> 2;
                mem_wdata = read_data;
            end

            default: begin
            end

        endcase
    end

    // ==========================
    // CPU đọc thanh ghi DMA
    // ==========================

    always_comb begin

        ready = valid;
        rdata = 32'b0;

        case (addr)

            5'h00:
                rdata = src_addr;

            5'h04:
                rdata = dst_addr;

            5'h08:
                rdata = length;

            5'h0C:
                rdata = {31'b0, busy};

            5'h10:
                rdata = {30'b0, done, busy};

            default:
                rdata = 32'b0;

        endcase
    end

endmodule
