`timescale 1ns / 1ps
 
module cpuTop_tb;
 
    logic clk = 0;
    logic reset;
 
    int pass_count = 0;
    int fail_count = 0;
 
    cpuTop dut (
        .clk  (clk),
        .reset(reset)
    );
    
    //Get the test program
    defparam dut.u_iMem.MEM_FILE = "sv_cpuTop/cpu_test_prog.hex";
 
    always #5 clk = ~clk;
 
    //Checker functions
    task automatic check_reg(input [4:0] regnum, input [31:0] expected, input string label);
        logic [31:0] actual;
        actual = dut.u_register.reg_file[regnum];
        if (actual === expected) begin
            pass_count++;
            $display("  PASS  x%0d (%-22s) = 0x%08h", regnum, label, actual);
        end else begin
            fail_count++;
            $display("  FAIL  x%0d (%-22s): expected 0x%08h, got 0x%08h", regnum, label, expected, actual);
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
 
    //TB start
    initial begin
        $dumpfile("cpuTop_tb.vcd");
        $dumpvars(0, cpuTop_tb);
 
        for (int i = 0; i < 32; i++) dut.u_register.reg_file[i] = 32'h0;
 
        reset = 1;
        @(posedge clk);
        @(posedge clk);
        reset = 0;

        repeat (40) @(posedge clk);
 
        $display("========================================================");
        $display("cpuTop_tb results");
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
 
        $display("========================================================");
        $display("%0d passed, %0d failed", pass_count, fail_count);
        $display("========================================================");
 
        $finish;
    end
 
endmodule