`timescale 1ns/1ps
module rv32i_cpu (
    input  logic        clk,
    input  logic        rst,

    // Instruction interface
    output logic [31:0] instr_addr,
    input  logic [31:0] instr_rdata,

    // Data interface
    output logic        data_valid,
    output logic        data_we,
    output logic [31:0] data_addr,
    output logic [31:0] data_wdata,
    input  logic [31:0] data_rdata,
    input  logic        data_ready
);

    logic [31:0] pc;
    logic [31:0] instr;

    logic [31:0] regs [0:31];

    logic [31:0] alu_result;
    logic [31:0] load_data;

    logic [4:0] rd;

    typedef enum logic [2:0] {
        FETCH,
        EXEC,
        MEM,
        WB_LOAD
    } state_t;

    state_t state;

    wire [6:0] opcode = instr[6:0];
    wire [4:0] rd_w   = instr[11:7];
    wire [2:0] funct3 = instr[14:12];
    wire [4:0] rs1    = instr[19:15];
    wire [4:0] rs2    = instr[24:20];
    wire [6:0] funct7 = instr[31:25];

    wire [31:0] rs1_data =
        (rs1 == 0) ? 32'b0 : regs[rs1];

    wire [31:0] rs2_data =
        (rs2 == 0) ? 32'b0 : regs[rs2];

    wire [31:0] imm_i =
        {{20{instr[31]}}, instr[31:20]};

    wire [31:0] imm_s =
        {{20{instr[31]}}, instr[31:25], instr[11:7]};

    wire [31:0] imm_b =
        {{19{instr[31]}},
         instr[31],
         instr[7],
         instr[30:25],
         instr[11:8],
         1'b0};

    wire [31:0] imm_j =
        {{11{instr[31]}},
         instr[31],
         instr[19:12],
         instr[20],
         instr[30:21],
         1'b0};

    assign instr_addr = pc;

    always_comb begin
        data_valid = 1'b0;
        data_we    = 1'b0;
        data_addr  = 32'b0;
        data_wdata = 32'b0;

        if (state == MEM) begin
            data_valid = 1'b1;
            data_addr  = alu_result;
            data_wdata = rs2_data;

            if (opcode == 7'b0100011)
                data_we = 1'b1;
        end
    end

    integer i;

    always_ff @(posedge clk) begin
        if (rst) begin
            pc         <= 32'b0;
            instr      <= 32'b0;
            alu_result <= 32'b0;
            load_data  <= 32'b0;
            rd         <= 5'b0;
            state      <= FETCH;

            for (i = 0; i < 32; i = i + 1)
                regs[i] <= 32'b0;
        end
        else begin

            regs[0] <= 32'b0;

            case (state)

                FETCH: begin
                    instr <= instr_rdata;
                    state <= EXEC;
                end

                EXEC: begin

                    case (opcode)

                        // ADDI / ANDI / ORI / XORI
                        7'b0010011: begin

                            case (funct3)

                                3'b000: begin
                                    regs[rd_w] <= rs1_data + imm_i;
                                    pc <= pc + 4;
                                end

                                3'b111: begin
                                    regs[rd_w] <= rs1_data & imm_i;
                                    pc <= pc + 4;
                                end

                                3'b110: begin
                                    regs[rd_w] <= rs1_data | imm_i;
                                    pc <= pc + 4;
                                end

                                3'b100: begin
                                    regs[rd_w] <= rs1_data ^ imm_i;
                                    pc <= pc + 4;
                                end

                                default: begin
                                    pc <= pc + 4;
                                end

                            endcase

                            state <= FETCH;
                        end

                        // ADD / SUB / AND / OR / XOR
                        7'b0110011: begin

                            case (funct3)

                                3'b000: begin
                                    if (funct7 == 7'b0100000)
                                        regs[rd_w] <= rs1_data - rs2_data;
                                    else
                                        regs[rd_w] <= rs1_data + rs2_data;
                                end

                                3'b111:
                                    regs[rd_w] <= rs1_data & rs2_data;

                                3'b110:
                                    regs[rd_w] <= rs1_data | rs2_data;

                                3'b100:
                                    regs[rd_w] <= rs1_data ^ rs2_data;

                                default: ;
                            endcase

                            pc <= pc + 4;
                            state <= FETCH;
                        end

                        // LW
                        7'b0000011: begin
                            if (funct3 == 3'b010) begin
                                alu_result <= rs1_data + imm_i;
                                rd <= rd_w;
                                state <= MEM;
                            end
                            else begin
                                pc <= pc + 4;
                                state <= FETCH;
                            end
                        end

                        // SW
                        7'b0100011: begin
                            if (funct3 == 3'b010) begin
                                alu_result <= rs1_data + imm_s;
                                state <= MEM;
                            end
                            else begin
                                pc <= pc + 4;
                                state <= FETCH;
                            end
                        end

                        // BEQ / BNE
                        7'b1100011: begin

                            case (funct3)

                                3'b000: begin
                                    if (rs1_data == rs2_data)
                                        pc <= pc + imm_b;
                                    else
                                        pc <= pc + 4;
                                end

                                3'b001: begin
                                    if (rs1_data != rs2_data)
                                        pc <= pc + imm_b;
                                    else
                                        pc <= pc + 4;
                                end

                                default:
                                    pc <= pc + 4;

                            endcase

                            state <= FETCH;
                        end

                        // JAL
                        7'b1101111: begin
                            regs[rd_w] <= pc + 4;
                            pc <= pc + imm_j;
                            state <= FETCH;
                        end

                        default: begin
                            pc <= pc + 4;
                            state <= FETCH;
                        end

                    endcase
                end

                MEM: begin

                    if (data_ready) begin

                        if (opcode == 7'b0000011) begin
                            load_data <= data_rdata;
                            state <= WB_LOAD;
                        end
                        else begin
                            pc <= pc + 4;
                            state <= FETCH;
                        end

                    end
                end

                WB_LOAD: begin
                    regs[rd] <= load_data;
                    pc <= pc + 4;
                    state <= FETCH;
                end

                default:
                    state <= FETCH;

            endcase
        end
    end

endmodule

