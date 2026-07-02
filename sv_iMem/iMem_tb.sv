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

 
    task automatic check(string test_name, logic [31:0] actual, logic [31:0] expected);
        if (actual === expected) begin
            $display("[PASS] %-40s addr-driven value = 0x%08h", test_name, actual);
        end else begin
            $display("[FAIL] %-40s got 0x%08h, expected 0x%08h", test_name, actual, expected);
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


        // TEST 3: Post-program NOP fill
        $display("\nTest 3: Post-program NOP fill");
        addr = 32'h00000014;  #1;  // word 5, immediately after program
        check("NOP fill @ word 5 (boundary)", instr, NOP);
 
        addr = 32'h00000024;  #1;  // word 9
        check("NOP fill @ word 9", instr, NOP);
 
        addr = 32'h0000003C;  #1;  // word 15, last valid index
        check("NOP fill @ word 15 (last)", instr, NOP);


        // TEST 4: Byte-to-word address mapping correctness
        $display("\nTest 4: Byte-to-word address mapping correctness");
        for (int w = 0; w < 5; w++) begin
            addr = w * 4;  #1;
            check($sformatf("word_index for byte addr 0x%08h", addr),
                  instr, (w == 0) ? 32'h11111111 :
                         (w == 1) ? 32'h22222222 :
                         (w == 2) ? 32'h33333333 :
                         (w == 3) ? 32'h44444444 : 32'h55555555);
        end


        // TEST 5: Combinational behavior without clock
        $display("\nTest 5: Combinational behavior without clock");
        addr = 32'h00000000;  #1;  check("comb read, addr=word0", instr, 32'h11111111);
        addr = 32'h0000000C;  #1;  check("comb read, addr=word3", instr, 32'h44444444);
        addr = 32'h00000000;  #1;  check("comb read, back to word0", instr, 32'h11111111);


        // TEST 6: Misalignment assertion
        $display("\nTest 6: Misalignment assertion");
        $display("  >>> expect instr_mem $error below (addr[1:0] = 01) <<<");
        addr = 32'h00000001;  #1;
        $display("  >>> end expected error region <<<");
 
        $display("  >>> expect instr_mem $error below (addr[1:0] = 10) <<<");
        addr = 32'h00000006;  #1;
        $display("  >>> end expected error region <<<");
 
        $display("  >>> expect NO instr_mem error below (aligned addr) <<<");
        addr = 32'h00000008;  #1;
        $display("  >>> end region (confirm nothing printed above) <<<");


        // TEST 7: Out-of-range assertion
        $display("\nTest 7: Out-of-range assertion");
        $display("  >>> expect instr_mem $error below (word 16) <<<");
        addr = 32'h00000040;  #1;  // word index 16 -- out of range
        $display("  >>> end expected error region <<<");
 
        $display("  >>> expect instr_mem $error below (word 1000) <<<");
        addr = 32'h00000FA0;  #1;  // word index 1000 -- far out of range
        $display("  >>> end expected error region <<<");


        $finish;
    end
 
endmodule