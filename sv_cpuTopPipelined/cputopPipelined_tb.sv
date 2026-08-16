`timescale 1ns / 1ps
 
module cpuTopPipelined_tb;
 
    logic clk = 0;
    logic reset;
 
    int pass_count = 0;
    int fail_count = 0;
 
    cpuTopPipelined dut (
        .clk  (clk),
        .reset(reset)
    );
 
    always #5 clk = ~clk;
 
    //-----------------------------------------------------------------
    // Checker tasks (same style/output format as cpuTop_tb)
    //-----------------------------------------------------------------
    task automatic check_reg(input [4:0] regnum, input [31:0] expected, input string label);
        logic [31:0] actual;
        actual = dut.u_register.reg_file[regnum];
        if (actual === expected) begin
            pass_count++;
            $display("  PASS  x%0d (%-28s) = 0x%08h", regnum, label, actual);
        end else begin
            fail_count++;
            $display("  FAIL  x%0d (%-28s): expected 0x%08h, got 0x%08h", regnum, label, expected, actual);
        end
    endtask
 
    task automatic check_mem_word(input [31:0] word_idx, input [31:0] expected, input string label);
        logic [31:0] actual;
        actual = dut.u_dMem.mem[word_idx];
        if (actual === expected) begin
            pass_count++;
            $display("  PASS  dMem[%0d] (%-16s) = 0x%08h", word_idx, label, actual);
        end else begin
            fail_count++;
            $display("  FAIL  dMem[%0d] (%-16s): expected 0x%08h, got 0x%08h", word_idx, label, expected, actual);
        end
    endtask
 
    task automatic check_count(input int actual, input int expected, input string label);
        if (actual === expected) begin
            pass_count++;
            $display("  PASS  %-32s = %0d", label, actual);
        end else begin
            fail_count++;
            $display("  FAIL  %-32s: expected %0d, got %0d", label, expected, actual);
        end
    endtask
 

    // Stall / flush instrumentation
    int stall_count;
    int flush_count;
 
    always @(posedge clk) begin
        if (!reset) begin
            if (dut.loadUseStall) stall_count++;
            if (dut.ifidFlush)    flush_count++;
        end
    end
 
    task automatic clear_dut_state();
        for (int i = 0; i < 32; i++) dut.u_register.reg_file[i] = 32'h0;
        for (int i = 0; i < 4096; i++) dut.u_dMem.mem[i] = 32'h0;
        stall_count = 0;
        flush_count = 0;
    endtask
 
    task automatic run_reset(int settle_cycles);
        reset = 1;
        @(posedge clk);
        @(posedge clk);
        reset = 0;
        repeat (settle_cycles) @(posedge clk);
    endtask
 


    // Testbench main
    initial begin
        $dumpfile("cpuTopPipelined_tb.vcd");
        $dumpvars(0, cpuTopPipelined_tb);
 

        // PHASE 1: original cpu_test_prog.hex
        $readmemh("sv_cpuTopPipelined/cpu_test_prog.hex", dut.u_iMem.mem);
        clear_dut_state();
        run_reset(60);
 
        $display("========================================================");
        $display("PHASE 1: cpu_test_prog.hex (equivalence vs. single-cycle)");
        $display("========================================================");
 
        check_reg(1,  32'd5,          "addi x1,x0,5");
        check_reg(2,  32'd7,          "addi x2,x0,7");
        check_reg(3,  32'd12,         "add x3,x1,x2");
        check_reg(4,  32'd2,          "sub x4,x2,x1");
        check_reg(5,  32'd5,          "and x5,x1,x2");
        check_reg(6,  32'd7,          "or  x6,x1,x2");
        check_reg(7,  32'd1,          "slt x7,x1,x2");
        check_reg(8,  32'd0,          "sltu x8,x2,x1");
        check_reg(9,  32'h12345678,   "lui+addi build");
        check_reg(10, 32'd12,         "lw  x10,0(x0)");
        check_reg(11, 32'd7,          "lbu x11,8(x0)");
        check_reg(12, 32'd1,          "beq landing");
        check_reg(13, 32'd44,         "bne fallthrough");
        check_reg(14, 32'd80,         "jal link addr");
        check_reg(15, 32'd84,         "auipc own addr");
        check_reg(16, 32'd100,        "computed jalr target");
        check_reg(17, 32'd96,         "jalr link addr");
        check_reg(18, 32'd9,          "jalr landing");
        check_reg(20, 32'd0,          "POISON A untouched");
        check_reg(21, 32'd0,          "POISON B untouched");
        check_reg(22, 32'd0,          "POISON C untouched");
 
        check_mem_word(0, 32'd12, "sw x3,0(x0)");
        if (dut.u_dMem.mem[2][7:0] === 8'd7) begin
            pass_count++;
            $display("  PASS  dMem[2][7:0] (sb x2,8(x0)  ) = 0x%02h", dut.u_dMem.mem[2][7:0]);
        end else begin
            fail_count++;
            $display("  FAIL  dMem[2][7:0] (sb x2,8(x0)  ): expected 0x07, got 0x%02h", dut.u_dMem.mem[2][7:0]);
        end
 
        // Rule 2 hazard (addi x16 -> jalr) + 3 taken control transfers
        // (beq, jal, jalr) are the only pipeline events this program
        // can trigger - confirm the counts match exactly.
        check_count(stall_count, 1, "phase1 stall_count (Rule 2 x1)");
        check_count(flush_count, 3, "phase1 flush_count (beq+jal+jalr)");
 
        //=============================================================
        // PHASE 2: hazard_prog.hex - dedicated hazard/forward coverage
        //=============================================================
        $readmemh("sv_cpuTopPipelined/hazard_prog.hex", dut.u_iMem.mem);
        clear_dut_state();
        run_reset(90);
 
        $display("========================================================");
        $display("PHASE 2: hazard_prog.hex (hazard/forward coverage)");
        $display("========================================================");
 
        $display("--- Block A: EX forward, distance 1 (zero stall) ---");
        check_reg(1, 32'd10, "addi x1,x0,10");
        check_reg(2, 32'd15, "addi x2,x1,5 (EX/MEM fwd)");
 
        $display("--- Block B: EX forward, distance 2 (zero stall) ---");
        check_reg(3, 32'd20, "addi x3,x0,20");
        check_reg(4, 32'd21, "addi x4,x3,1 (MEM/WB fwd)");
 
        $display("--- Block C: universal load-use, Rule 1 (1 stall) ---");
        check_reg(5, 32'd99,  "addi x5,x0,99");
        check_reg(6, 32'd99,  "lw x6,0(x0)");
        check_reg(7, 32'd100, "addi x7,x6,1 (post-stall fwd)");
        check_mem_word(0, 32'd99, "sw x5,0(x0) (store-data fwd)");
 
        $display("--- Block D: ALU-adjacent-to-branch, Rule 2 (1 stall) ---");
        check_reg(8,  32'd10, "addi x8,x0,10");
        check_reg(9,  32'd1,  "d_land reached");
        check_reg(29, 32'd0,  "POISON D untouched");
 
        $display("--- Block E: load 2-away-from-branch, Rule 3 (1 stall) ---");
        check_reg(11, 32'd77, "addi x11,x0,77");
        check_reg(12, 32'd77, "lw x12,4(x0)");
        check_reg(13, 32'd3,  "addi x13,x0,3 (spacer)");
        check_reg(14, 32'd2,  "e_land reached");
        check_reg(28, 32'd0,  "POISON E untouched");
        check_mem_word(1, 32'd77, "sw x11,4(x0)");
 
        $display("--- Block F: load immediately before branch (2 stalls) ---");
        check_reg(15, 32'd88, "addi x15,x0,88");
        check_reg(16, 32'd88, "lw x16,8(x0)");
        check_reg(17, 32'd3,  "f_land reached");
        check_reg(27, 32'd0,  "POISON F untouched");
        check_mem_word(2, 32'd88, "sw x15,8(x0)");
 
        $display("--- Block G: distance-3 forward into ID (zero stall) ---");
        check_reg(18, 32'd20, "addi x18,x0,20 (matches x3)");
        check_reg(19, 32'd4, "g_land reached");
        check_reg(26, 32'd0, "POISON G untouched");
 
        $display("--- Block H: JALR target fwd, distance 2 (zero stall) ---");
        check_reg(20, 32'd128,  "auipc x20 own addr");
        check_reg(21, 32'd140,  "jalr x21 link addr");
        check_reg(24, 32'd1900, "h_land reached");
        check_reg(25, 32'd0,    "POISON H untouched");
 
        $display("--- Block I: full branch comparator coverage ---");
        check_reg(22, 32'd3,  "addi x22,x0,3");
        check_reg(23, 32'd5,  "addi x23,x0,5");
        check_reg(10, 32'd10, "all 4 branch types landed");
        check_reg(30, 32'd0,  "POISON I untouched (blt/bge/bltu/bgeu)");
 
        $display("--- Hazard/flush timing totals ---");
        check_count(stall_count, 6, "phase2 stall_count");
        check_count(flush_count, 9, "phase2 flush_count (D+E+F+G+H+I(x4))");
 
        $display("========================================================");
        $display("%0d passed, %0d failed", pass_count, fail_count);
        $display("========================================================");
 
        $finish;
    end
 
endmodule
 