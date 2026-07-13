`timescale 1ns/1ps
 
module dMem_tb;
 
    localparam int DEPTH      = 16;
    localparam int CLK_PERIOD = 10;
 
    logic        clk;
    logic        mem_write;
    logic [31:0] addr;
    logic [31:0] write_data;
    logic [2:0]  funct3;
    logic [31:0] read_data;

    int pass_count = 0;
    int fail_count = 0;
 
    logic [31:0] rand_addr;
    logic [31:0] rand_data;
 
    dMem #(.DEPTH(DEPTH)) dut (
        .clk        (clk),
        .mem_write  (mem_write),
        .addr       (addr),
        .write_data (write_data),
        .funct3     (funct3),
        .read_data  (read_data)
    );

    //Clock setup
    initial clk = 0;
    always #(CLK_PERIOD/2) clk = ~clk;
 
    // funct3 encodings, named for readability in the test sequence
    localparam logic [2:0] F3_B  = 3'b000;  // SB / LB
    localparam logic [2:0] F3_H  = 3'b001;  // SH / LH
    localparam logic [2:0] F3_W  = 3'b010;  // SW / LW
    localparam logic [2:0] F3_BU = 3'b100;  // LBU
    localparam logic [2:0] F3_HU = 3'b101;  // LHU

    // Checker function
    task automatic check(string name, logic [31:0] got, logic [31:0] exp);
        if (got === exp) begin
            pass_count++;
            $display("  PASS %-32s got=%08h", name, got);
        end else begin
            fail_count++;
            $display("  FAIL %-32s got=%08h exp=%08h", name, got, exp);
        end
    endtask

    // Store function
    task automatic do_store(input logic [31:0] a, input logic [31:0] d, input logic [2:0] f3);
        addr = a; write_data = d; funct3 = f3; mem_write = 1;
        @(posedge clk);
        #1;
        mem_write = 0;
    endtask

    // Load function
    task automatic do_load(input logic [31:0] a, input logic [2:0] f3);
        addr = a; funct3 = f3;
        #1;
    endtask

    initial begin
        $dumpfile("dMem_tb.vcd");
        $dumpvars(0, dMem_tb);
 
        mem_write = 0; addr = 0; write_data = 0; funct3 = 0;
        @(posedge clk); #1;

        //-----------------------------------------------------------
        $display("\nTest 1: Word store/load across the address range");
        do_store(32'h0000_0000, 32'hDEAD_BEEF, F3_W);
        do_load(32'h0000_0000, F3_W);
        check("SW/LW word 0", read_data, 32'hDEAD_BEEF);
 
        do_store(32'h0000_0004, 32'h1234_5678, F3_W);
        do_load(32'h0000_0004, F3_W);
        check("SW/LW word 1", read_data, 32'h1234_5678);
 
        do_store((DEPTH-1)*4, 32'hCAFE_F00D, F3_W);   // highest word for this DEPTH
        do_load((DEPTH-1)*4, F3_W);
        check("SW/LW last word (boundary)", read_data, 32'hCAFE_F00D);
 
        do_load(32'h0000_0000, F3_W);
        check("word 0 unaffected by other writes", read_data, 32'hDEAD_BEEF);


        //-----------------------------------------------------------
        $display("\nTest 2: Byte store at all four offsets");
        do_store(32'h0000_0008, 32'h0000_0000, F3_W);  // clear the word first
 
        do_store(32'h0000_0008, 32'h0000_00AA, F3_B);  // offset 0
        do_load(32'h0000_0008, F3_W);
        check("SB offset0 isolated", read_data, 32'h0000_00AA);
 
        do_store(32'h0000_0009, 32'h0000_00BB, F3_B);  // offset 1
        do_load(32'h0000_0008, F3_W);
        check("SB offset1 preserves offset0", read_data, 32'h0000_BBAA);
 
        do_store(32'h0000_000A, 32'h0000_00CC, F3_B);  // offset 2
        do_load(32'h0000_0008, F3_W);
        check("SB offset2 preserves 0,1", read_data, 32'h00CC_BBAA);
 
        do_store(32'h0000_000B, 32'h0000_00DD, F3_B);  // offset 3
        do_load(32'h0000_0008, F3_W);
        check("SB offset3 completes word", read_data, 32'hDDCC_BBAA);
 

        //-----------------------------------------------------------
        $display("\nTest 3: Halfword store at both aligned offsets");
        do_store(32'h0000_000C, 32'h0000_0000, F3_W);  // clear the word
 
        do_store(32'h0000_000C, 32'h0000_1234, F3_H);  // offset 0
        do_load(32'h0000_000C, F3_W);
        check("SH offset0 isolated", read_data, 32'h0000_1234);
 
        do_store(32'h0000_000E, 32'h0000_5678, F3_H);  // offset 2
        do_load(32'h0000_000C, F3_W);
        check("SH offset2 preserves offset0 half", read_data, 32'h5678_1234);
 

        //-----------------------------------------------------------
        $display("\nTest 4: Sign vs. zero extension: byte loads");
        do_store(32'h0000_0000, 32'h0000_007F, F3_B);  // positive byte
        do_load(32'h0000_0000, F3_B);
        check("LB positive, no sign-fill", read_data, 32'h0000_007F);
        do_load(32'h0000_0000, F3_BU);
        check("LBU positive, zero-fill", read_data, 32'h0000_007F);
 
        do_store(32'h0000_0000, 32'h0000_0080, F3_B);  // negative byte
        do_load(32'h0000_0000, F3_B);
        check("LB negative, sign-fill", read_data, 32'hFFFF_FF80);
        do_load(32'h0000_0000, F3_BU);
        check("LBU negative, zero-fill", read_data, 32'h0000_0080);
 

        //-----------------------------------------------------------
        $display("\nTest 5: Sign vs. zero extension: halfword loads");
        do_store(32'h0000_0000, 32'h0000_7FFF, F3_H);  // positive half
        do_load(32'h0000_0000, F3_H);
        check("LH positive, no sign-fill", read_data, 32'h0000_7FFF);
        do_load(32'h0000_0000, F3_HU);
        check("LHU positive, zero-fill", read_data, 32'h0000_7FFF);
 
        do_store(32'h0000_0000, 32'h0000_8055, F3_H);  // negative half
        do_load(32'h0000_0000, F3_H);
        check("LH negative, sign-fill", read_data, 32'hFFFF_8055);
        do_load(32'h0000_0000, F3_HU);
        check("LHU negative, zero-fill", read_data, 32'h0000_8055);
 

        //-----------------------------------------------------------
        $display("\nTest 6: Byte loads at every offset within a mixed-sign word");
        // byte3=0x81(neg) byte2=0x02(pos) byte1=0x03(pos) byte0=0x84(neg)
        do_store(32'h0000_0010, 32'h8102_0384, F3_W);
 
        do_load(32'h0000_0010, F3_B);
        check("LB word byte0 (neg)", read_data, 32'hFFFF_FF84);
        do_load(32'h0000_0011, F3_B);
        check("LB word byte1 (pos)", read_data, 32'h0000_0003);
        do_load(32'h0000_0012, F3_B);
        check("LB word byte2 (pos)", read_data, 32'h0000_0002);
        do_load(32'h0000_0013, F3_B);
        check("LB word byte3 (neg)", read_data, 32'hFFFF_FF81);
 
        do_load(32'h0000_0010, F3_BU);
        check("LBU word byte0", read_data, 32'h0000_0084);
        do_load(32'h0000_0013, F3_BU);
        check("LBU word byte3", read_data, 32'h0000_0081);
 

        //-----------------------------------------------------------
        $display("\nTest 7: mem_write gating: no write when deasserted");
        do_store(32'h0000_0018, 32'hAAAA_AAAA, F3_W);  // seed a known value
 
        addr = 32'h0000_0018; write_data = 32'h5555_5555; funct3 = F3_W; mem_write = 0;
        @(posedge clk); #1;
        do_load(32'h0000_0018, F3_W);
        check("no write when mem_write=0", read_data, 32'hAAAA_AAAA);
 

        //-----------------------------------------------------------
        $display("\nTest 8: Overwrite: last store wins");
        do_store(32'h0000_001C, 32'h1111_1111, F3_W);
        do_store(32'h0000_001C, 32'h2222_2222, F3_W);
        do_load(32'h0000_001C, F3_W);
        check("overwrite keeps latest value", read_data, 32'h2222_2222);
 

        //-----------------------------------------------------------
        $display("\nTest 9: Undefined funct3 encodings");
        do_store(32'h0000_0020, 32'h0000_0000, F3_W);   // clear
        do_store(32'h0000_0020, 32'hFFFF_FFFF, 3'b011); // undefined store width
        do_load(32'h0000_0020, F3_W);
        check("undefined store funct3 writes nothing", read_data, 32'h0000_0000);
 
        do_store(32'h0000_0024, 32'hFFFF_FFFF, F3_W);
        do_load(32'h0000_0024, 3'b110);
        check("undefined load funct3 (110) returns 0", read_data, 32'h0000_0000);
        do_load(32'h0000_0024, 3'b111);
        check("undefined load funct3 (111) returns 0", read_data, 32'h0000_0000);
 

        //-----------------------------------------------------------
        $display("\nTest 10: Uninitialized location reads zero");
        do_load(32'h0000_0028, F3_W);  // word 10 - never written anywhere above
        check("untouched word reads 0", read_data, 32'h0000_0000);
 

        //-----------------------------------------------------------
        $display("\nTest 11: Randomized word store/load regression");
        for (int i = 0; i < 20; i++) begin
            rand_addr = $urandom_range(0, DEPTH-1) * 4;
            rand_data = $urandom;
            do_store(rand_addr, rand_data, F3_W);
            do_load(rand_addr, F3_W);
            check($sformatf("random SW/LW addr=%0d", rand_addr), read_data, rand_data);
        end


        //-----------------------------------------------------------
        $display("\n=================================================");
        $display(" Results: %0d passed, %0d failed (%0d total)",
                  pass_count, fail_count, pass_count + fail_count);
        $display("=================================================\n");
 
        $finish;
    end
 
endmodule