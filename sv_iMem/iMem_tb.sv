`timescale 1ns / 1ps
 
module iMem_tb;

    // empty file
    logic [31:0] addr_blank;
    logic [31:0] instr_blank;
 
    iMem #(
        .DEPTH    (16),
        .MEM_FILE ("")
    ) dut_blank (
        .addr  (addr_blank),
        .instr (instr_blank)
    );

    // Test file
    logic [31:0] addr;
    logic [31:0] instr;
 
    iMem #(
        .DEPTH    (16),
        .MEM_FILE ("test_prog.hex")
    ) dut (
        .addr  (addr),
        .instr (instr)
    );

    // Checker function
    localparam logic [31:0] NOP = 32'h00000013;
    int pass_count = 0;
    int fail_count = 0;
 
    task automatic check(string test_name, logic [31:0] actual, logic [31:0] expected);
        if (actual === expected) begin
            $display("[PASS] %-40s addr-driven value = 0x%08h", test_name, actual);
            pass_count++;
        end else begin
            $display("[FAIL] %-40s got 0x%08h, expected 0x%08h", test_name, actual, expected);
            fail_count++;
        end
    endtask

    // Test sequence
    initial begin
        // Test 1: Pre-load NOP fill
        $display("Test 1: Pre-load NOP fill");
        addr_blank = 32'h00000000;  #1;
        check("NOP fill @ word 0",  instr_blank, NOP);
 
        addr_blank = 32'h00000020;  #1;  // word index 8
        check("NOP fill @ word 8 (mid)", instr_blank, NOP);
 
        addr_blank = 32'h0000003C;  #1;  // word index 15
        check("NOP fill @ word 15 (last)", instr_blank, NOP);

        // Test 2: Correct load from hex file
        $display("\nTest 2: Correct load from hex file");
        addr = 32'h00000000;  #1;
        check("loaded word 0", instr, 32'h11111111);
 
        addr = 32'h00000004;  #1;
        check("loaded word 1", instr, 32'h22222222);
 
        addr = 32'h00000008;  #1;
        check("loaded word 2", instr, 32'h33333333);
 
        addr = 32'h0000000C;  #1;
        check("loaded word 3", instr, 32'h44444444);
 
        addr = 32'h00000010;  #1;
        check("loaded word 4", instr, 32'h55555555);

        addr = 32'h00000014;  #1;
        check("loaded word 5", instr, 32'h00000013);











        $finish;
    end
 
endmodule