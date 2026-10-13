module dma_controller #(
    parameter ADDR_WIDTH = 10,
    parameter DATA_WIDTH = 32
)(
    input  logic clk,
    input logic rst,

    // DMA register interface
    input  logic        valid,
    input  logic        we,
    input  logic [4:0]  addr,
    input  logic [31:0] wdata,

    output logic [31:0] rdata,
    output logic        ready,

    // Memory interface
    output logic                  mem_valid,
    output logic                  mem_we,
    output logic [ADDR_WIDTH-1:0] mem_addr,
    output logic [DATA_WIDTH-1:0] mem_wdata,

    input logic [DATA_WIDTH-1:0] mem_rdata,
    input logic                   mem_ready,

    output logic irq
);

    // =========================================
    // DMA registers
    // =========================================

    logic [31:0] src_addr;
    logic [31:0] dst_addr;
    logic [31:0] length;

    // Tham số được chốt tại thời điểm START
    logic [9:0] active_src_addr;
    logic [9:0] active_dst_addr;
    logic [31:0] active_length;

    logic [31:0] read_data;
    logic [31:0] count;

    logic busy;
    logic done;
    logic error;

    logic int_enable;
    logic int_status;

    // =========================================
    // FSM
    // =========================================

    typedef enum logic [2:0] {
        IDLE,
        READ,
        READ_WAIT,
        WRITE,
        DONE
    } state_t;

    state_t state;

    // =========================================
    // Address checking
    // BRAM = 4 KB = 1024 words
    // =========================================

    logic address_valid;

    always_comb begin

        address_valid = 1'b1;

        // Địa chỉ phải căn word
        if (src_addr[1:0] != 2'b00)
            address_valid = 1'b0;

        if (dst_addr[1:0] != 2'b00)
            address_valid = 1'b0;

        // Địa chỉ bắt đầu phải nằm trong BRAM
        if (src_addr > 32'h0000_0FFF)
            address_valid = 1'b0;

        if (dst_addr > 32'h0000_0FFF)
            address_valid = 1'b0;

        // Kiểm tra toàn bộ vùng truyền
        if (({1'b0, src_addr} + ({1'b0, length} << 2))
            > 33'h0000_01000)
            address_valid = 1'b0;

        if (({1'b0, dst_addr} + ({1'b0, length} << 2))
            > 33'h0000_01000)
            address_valid = 1'b0;

    end

    // =========================================
    // Sequential logic
    // =========================================

    always_ff @(posedge clk) begin

        if (rst) begin

            src_addr        <= 32'b0;
            dst_addr        <= 32'b0;
            length          <= 32'b0;

            active_src_addr <= 10'b0;
            active_dst_addr <= 10'b0;
            active_length   <= 32'b0;

            read_data       <= 32'b0;
            count           <= 32'b0;

            busy            <= 1'b0;
            done            <= 1'b0;
            error           <= 1'b0;

            // Giữ = 1 để tương thích các TB Step 6/7 cũ
            int_enable      <= 1'b1;
            int_status      <= 1'b0;

            state           <= IDLE;

        end

        else begin

            // =================================
            // Register writes
            // =================================

            if (valid && we) begin

                case (addr)

                    // SRC_ADDR
                    5'h00: begin
                        src_addr <= wdata;
                    end

                    // DST_ADDR
                    5'h04: begin
                        dst_addr <= wdata;
                    end

                    // LENGTH
                    5'h08: begin
                        length <= wdata;
                    end

                    // CONTROL
                    // bit 0 = START
                    5'h0C: begin

                        // START chỉ được chấp nhận khi DMA IDLE
                        if (wdata[0] && !busy && state == IDLE) begin

                            active_src_addr <= src_addr[11:2];
                            active_dst_addr <= dst_addr[11:2];
                            active_length   <= length;

                            count <= 32'b0;

                            done       <= 1'b0;
                            error      <= 1'b0;
                            int_status <= 1'b0;

                            // LENGTH = 0
                            if (length == 0) begin

                                busy  <= 1'b0;
                                state <= DONE;

                            end

                            // Địa chỉ không hợp lệ
                            else if (!address_valid) begin

                                busy  <= 1'b0;
                                error <= 1'b1;
                                state <= DONE;

                            end

                            // Bắt đầu truyền
                            else begin

                                busy  <= 1'b1;
                                state <= READ;

                            end

                        end

                    end

                    // INT_ENABLE
                    5'h14: begin
                        int_enable <= wdata[0];
                    end

                    // INT_STATUS
                    // Ghi 1 để xóa pending
                    5'h18: begin
                        if (wdata[0])
                            int_status <= 1'b0;
                    end

                    default: begin
                    end

                endcase

            end

            // =================================
            // DMA FSM
            // =================================

            case (state)

                // =================================
                // IDLE
                // =================================

                IDLE: begin

                    busy <= 1'b0;

                end

                // =================================
                // READ
                // =================================

                READ: begin

                    state <= READ_WAIT;

                end

                // =================================
                // READ_WAIT
                // =================================

                READ_WAIT: begin

                    if (mem_ready) begin

                        read_data <= mem_rdata;

                        state <= WRITE;

                    end

                end

                // =================================
                // WRITE
                // =================================

                WRITE: begin

                    if (mem_ready) begin

                        if (count + 1 >= active_length) begin

                            state <= DONE;

                        end

                        else begin

                            count <= count + 1;

                            state <= READ;

                        end

                    end

                end

                // =================================
                // DONE
                // =================================

                DONE: begin

                    busy       <= 1'b0;
                    done       <= 1'b1;
                    int_status <= 1'b1;

                    state <= IDLE;

                end

                // =================================
                // DEFAULT
                // =================================

                default: begin

                    state <= IDLE;
                    busy  <= 1'b0;

                end

            endcase

        end

    end

    // =========================================
    // Memory interface
    // =========================================

    always_comb begin

        mem_valid = 1'b0;
        mem_we    = 1'b0;
        mem_addr  = '0;
        mem_wdata = '0;

        case (state)

            READ: begin

                mem_valid = 1'b1;
                mem_we    = 1'b0;

                // Địa chỉ byte -> địa chỉ word
                mem_addr = active_src_addr
                         + count[ADDR_WIDTH-1:0];

            end

            WRITE: begin

                mem_valid = 1'b1;
                mem_we    = 1'b1;

                mem_addr = active_dst_addr
                         + count[ADDR_WIDTH-1:0];

                mem_wdata = read_data;

            end

            default: begin
            end

        endcase

    end

    // =========================================
    // DMA register read
    // =========================================

    always_comb begin

        ready = valid;
        rdata = 32'b0;

        case (addr)

            // SRC_ADDR
            5'h00:
                rdata = src_addr;

            // DST_ADDR
            5'h04:
                rdata = dst_addr;

            // LENGTH
            5'h08:
                rdata = length;

            // CONTROL
            5'h0C:
                rdata = {31'b0, busy};

            // STATUS
            // bit 0 = BUSY
            // bit 1 = DONE
            // bit 2 = ERROR
            5'h10:
                rdata = {29'b0, error, done, busy};

            // INT_ENABLE
            5'h14:
                rdata = {31'b0, int_enable};

            // INT_STATUS
            5'h18:
                rdata = {31'b0, int_status};

            default:
                rdata = 32'b0;

        endcase

    end

    // =========================================
    // IRQ
    // =========================================

    always_comb begin

        irq = int_enable && int_status;

    end

endmodule
