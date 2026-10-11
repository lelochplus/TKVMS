`timescale 1ns/1ps

module tb_soc_step6;

    logic clk;
    logic rst;
    logic dma_irq;

    soc_step6 dut (
        .clk(clk),
        .rst(rst),
        .dma_irq(dma_irq)
    );

    always #5 clk = ~clk;

    // =========================
    // CPU program
    // =========================
    function automatic [31:0] ADDI(
        input [4:0] rd,
        input [4:0] rs1,
        input integer imm
    );
        ADDI = {imm[11:0], rs1, 3'b000, rd, 7'b0010011};
    endfunction

    function automatic [31:0] SW(
        input [4:0] rs2,
        input [4:0] rs1,
        input integer imm
    );
        SW = {imm[11:5], rs2, rs1, 3'b010, imm[4:0], 7'b0100011};
    endfunction

    function automatic [31:0] ADD(
        input [4:0] rd,
        input [4:0] rs1,
        input [4:0] rs2
    );
        ADD = {7'b0000000, rs2, rs1, 3'b000, rd, 7'b0110011};
    endfunction

    initial begin
        clk = 1'b0;
        rst = 1'b1;

        #20;
        rst = 1'b0;

        // =================================
        // Nạp chương trình vào BRAM
        // =================================

        // x1 = 0x00000000
        dut.memory.mem[0]  = ADDI(5'd1, 5'd0, 0);
dut.memory.mem[1]  = ADDI(5'd2, 5'd0, 1024);
dut.memory.mem[2]  = ADD(5'd2, 5'd2, 5'd2);
dut.memory.mem[3]  = ADD(5'd2, 5'd2, 5'd2);
dut.memory.mem[4]  = ADDI(5'd3, 5'd0, 64);
dut.memory.mem[5]  = ADDI(5'd4, 5'd0, 80);
dut.memory.mem[6]  = ADDI(5'd5, 5'd0, 4);
dut.memory.mem[7]  = SW(5'd3, 5'd2, 0);
dut.memory.mem[8]  = SW(5'd4, 5'd2, 4);
dut.memory.mem[9]  = SW(5'd5, 5'd2, 8);
dut.memory.mem[10] = ADDI(5'd6, 5'd0, 1);
dut.memory.mem[11] = SW(5'd6, 5'd2, 12);

dut.memory.mem[16] = 32'hAAAA_1111;
        dut.memory.mem[17] = 32'hBBBB_2222;
        dut.memory.mem[18] = 32'hCCCC_3333;
        dut.memory.mem[19] = 32'hDDDD_4444;

        // =================================
        // Chờ IRQ
        // =================================

        fork
            begin
                wait (dma_irq);

                $display("PASS: DMA IRQ");

                #20;

                if (dut.memory.mem[20] == 32'hAAAA_1111 &&
                    dut.memory.mem[21] == 32'hBBBB_2222 &&
                    dut.memory.mem[22] == 32'hCCCC_3333 &&
                    dut.memory.mem[23] == 32'hDDDD_4444) begin

                    $display("PASS: DMA DATA TRANSFER");

                end
                else begin

                    $display("FAIL: DMA DATA TRANSFER");
                    $display("MEM[20] = %h", dut.memory.mem[20]);
                    $display("MEM[21] = %h", dut.memory.mem[21]);
                    $display("MEM[22] = %h", dut.memory.mem[22]);
                    $display("MEM[23] = %h", dut.memory.mem[23]);

                    $finish;
                end

                $display("==============================");
                $display("STEP 6: CPU + DMA + BUS + BRAM");
                $display("==============================");

                $finish;
            end

            begin
                #5_000_000;

                $display("FAIL: TIMEOUT");
                $display("CPU/DMA did not complete within timeout");
                $display("CPU PC      = %h", dut.cpu.pc);
                $display("CPU x2      = %h", dut.cpu.regs[2]);
                $display("CPU x3      = %h", dut.cpu.regs[3]);
                $display("CPU x4      = %h", dut.cpu.regs[4]);
                $display("CPU x5      = %h", dut.cpu.regs[5]);
                $display("DMA SRC     = %h", dut.dma.src_addr);
                $display("DMA DST     = %h", dut.dma.dst_addr);
                $display("DMA LENGTH  = %h", dut.dma.length);
                $display("DMA COUNT   = %h", dut.dma.count);
                $display("DMA STATE   = %d", dut.dma.state);
                $display("DMA BUSY    = %b", dut.dma.busy);
                $display("DMA IRQ     = %b", dma_irq);

                $finish;
            end
        join_any

    end

endmodule
