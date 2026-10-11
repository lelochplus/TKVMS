`timescale 1ns/1ps

module tb_rv32i_cpu;

    logic clk;
    logic rst;

    logic [31:0] instr_addr;
    logic [31:0] instr_rdata;

    logic        data_valid;
    logic        data_we;
    logic [31:0] data_addr;
    logic [31:0] data_wdata;
    logic [31:0] data_rdata;
    logic        data_ready;

    logic [31:0] imem [0:255];
    logic [31:0] dmem [0:255];

    integer i;
    integer pass_count;
    integer fail_count;

    rv32i_cpu dut (
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

    // Instruction memory
    assign instr_rdata = imem[instr_addr[9:2]];

    // Data memory
    assign data_rdata = dmem[data_addr[9:2]];
    assign data_ready = data_valid;

    always #5 clk = ~clk;

    // Data write
    always_ff @(posedge clk) begin
        if (data_valid && data_we)
            dmem[data_addr[9:2]] <= data_wdata;
    end

    // ==============================
    // Kiểm tra thanh ghi
    // ==============================
    task check_reg(
        input integer reg_num,
        input [31:0] expected
    );
    begin
        if (dut.regs[reg_num] === expected) begin
            $display("PASS: x%0d = %0d", reg_num, expected);
            pass_count = pass_count + 1;
        end
        else begin
            $display("FAIL: x%0d = %0d, expected %0d",
                     reg_num,
                     dut.regs[reg_num],
                     expected);
            fail_count = fail_count + 1;
        end
    end
    endtask

    // ==============================
    // Kiểm tra memory
    // ==============================
    task check_mem(
        input integer addr,
        input [31:0] expected
    );
    begin
        if (dmem[addr] === expected) begin
            $display("PASS: MEM[%0d] = %0d", addr, expected);
            pass_count = pass_count + 1;
        end
        else begin
            $display("FAIL: MEM[%0d] = %0d, expected %0d",
                     addr,
                     dmem[addr],
                     expected);
            fail_count = fail_count + 1;
        end
    end
    endtask

    initial begin

        clk = 0;
        rst = 1;

        pass_count = 0;
        fail_count = 0;

        // Xóa memory
        for (i = 0; i < 256; i = i + 1) begin
            imem[i] = 32'h00000013; // NOP = ADDI x0,x0,0
            dmem[i] = 32'b0;
        end

        // ==========================================
        // TEST 1: ADDI
        // x1 = 10
        // x2 = 20
        // ==========================================

        imem[0] = 32'h00A00093; // ADDI x1,x0,10
        imem[1] = 32'h01400113; // ADDI x2,x0,20

        // ==========================================
        // TEST 2: ADD
        // x3 = x1 + x2 = 30
        // ==========================================

        imem[2] = 32'h002081B3; // ADD x3,x1,x2

        // ==========================================
        // TEST 3: SUB
        // x4 = x2 - x1 = 10
        // ==========================================

        imem[3] = 32'h40110233; // SUB x4,x2,x1

        // ==========================================
        // TEST 4: AND
        // x5 = x1 & x2
        // 10 & 20 = 0
        // ==========================================

        imem[4] = 32'h0020F2B3; // AND x5,x1,x2

        // ==========================================
        // TEST 5: OR
        // x6 = x1 | x2
        // 10 | 20 = 30
        // ==========================================

        imem[5] = 32'h0020E333; // OR x6,x1,x2

        // ==========================================
        // TEST 6: XOR
        // x7 = x1 ^ x2
        // 10 ^ 20 = 30
        // ==========================================

        imem[6] = 32'h0020C3B3; // XOR x7,x1,x2

        // ==========================================
        // TEST 7: SW
        // MEM[0] = x3 = 30
        // ==========================================

        imem[7] = 32'h00302023; // SW x3,0(x0)

        // ==========================================
        // TEST 8: LW
        // x8 = MEM[0] = 30
        // ==========================================

        imem[8] = 32'h00002403; // LW x8,0(x0)

        // ==========================================
        // TEST 9: BEQ
        //
        // x9 = 1
        // x10 = 1
        // BEQ -> bỏ qua ADDI x11
        // ==========================================

        imem[9]  = 32'h00100493; // ADDI x9,x0,1
        imem[10] = 32'h00100513; // ADDI x10,x0,1

        // BEQ x9,x10,+8
        imem[11] = 32'h00A48463;

        // Lệnh này phải bị bỏ qua
        imem[12] = 32'h06300593; // ADDI x11,x0,99

        // Được thực hiện sau branch
        imem[13] = 32'h03700593; // ADDI x11,x0,55

        // ==========================================
        // TEST 10: BNE
        //
        // x12 = 1
        // x13 = 2
        // BNE -> bỏ qua ADDI x14
        // ==========================================

        imem[14] = 32'h00100613; // ADDI x12,x0,1
        imem[15] = 32'h00200693; // ADDI x13,x0,2

        // BNE x12,x13,+8
        imem[16] = 32'h00D61463;

        // Phải bị bỏ qua
        imem[17] = 32'h04D00713; // ADDI x14,x0,77

        // Được thực hiện
        imem[18] = 32'h04E00713; // ADDI x14,x0,78

        // ==========================================
        // TEST 11: JAL
        //
        // JAL x15,+8
        // Lệnh kế tiếp bị bỏ qua
        // ==========================================

        imem[19] = 32'h008007EF; // JAL x15,+8

        // Bị bỏ qua
        imem[20] = 32'h06300813; // ADDI x16,x0,99

        // Được thực hiện
        imem[21] = 32'h03700813; // ADDI x16,x0,55

        #20;
        rst = 0;

        // Cho CPU chạy
        #700;

        $display("");
        $display("==============================");
        $display("STEP 4: RV32I FULL TEST");
        $display("==============================");

        // ADDI
        check_reg(1, 10);
        check_reg(2, 20);

        // ADD
        check_reg(3, 30);

        // SUB
        check_reg(4, 10);

        // AND
        check_reg(5, 0);

        // OR
        check_reg(6, 30);

        // XOR
        check_reg(7, 30);

        // LW
        check_reg(8, 30);

        // BEQ
        check_reg(11, 55);

        // BNE
        check_reg(14, 78);

        // JAL
        check_reg(16, 55);

        // JAL return address
        check_reg(15, 80);

        // SW
        check_mem(0, 30);

        // x0 phải luôn bằng 0
        check_reg(0, 0);

        $display("");
        $display("==============================");

        if (fail_count == 0) begin
            $display("PASS: RV32I CPU FULL TEST");
            $display("PASS COUNT = %0d", pass_count);
        end
        else begin
            $display("FAIL: RV32I CPU");
            $display("PASS COUNT = %0d", pass_count);
            $display("FAIL COUNT = %0d", fail_count);
        end

        $display("==============================");

        $finish;
    end

endmodule
