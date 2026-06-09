module alu_tb;
    // Terminal Run:
    // iverilog -g2012 -o alu_sim alu.sv alu_tb.sv
    // vvp alu_sim
    // gtkwave alu.vcd

    // Testbench signals
    logic [31:0] a;
    logic [31:0] b;
    logic [3:0] op;
    logic [31:0] result;
    logic zero;

    // Instantiate the ALU
    logic negative;
    logic overflow;
    logic carry;

    alu dut (
        .a(a),
        .b(b),
        .op(op),
        .result(result),
        .zero(zero),
        .negative(negative),
        .overflow(overflow),
        .carry(carry)
    );

    // Test procedure
    initial begin
        $display("Starting ALU Testbench");
        $dumpfile("alu.vcd");   // for gtkwave
        $dumpvars(0, alu_tb);

        /////////////////////////////////////////////
        // test ADD
        a = 32'd10; b = 32'd5; op = 4'b0000;
        #10;
        $display("ADD: %0d + %0d = %0d (expect 15)", a, b, result);

        $display("");
        /////////////////////////////////////////////
        // test SUB
        a = 32'd10; b = 32'd10; op = 4'b0001;
        #10;
        $display("SUB: %0d - %0d = %0d  zero=%b (expect 0, zero=1)", a, b, result, zero);

        $display("");
        /////////////////////////////////////////////
        // test AND
        a = 32'hFF; b = 32'h0F; op = 4'b0010;
        #10;
        $display("AND: %h & %h = %h (expect 0f)", a, b, result);

        $display("");
        /////////////////////////////////////////////
        // test OR
        a = 32'hF0; b = 32'h0F; op = 4'b0011;
        #10;
        $display("OR: %h | %h = %h (expect ff)", a, b, result);

        $display("");
        /////////////////////////////////////////////
        // test NOR
        a = 32'hF0; b = 32'h0F; op = 4'b0100;
        #10;
        $display("NOR: %h ~| %h = %h (expect 00)", a, b, result);

        $display("");
        ///////////////////////////////////////////////
        // test XOR
        a = 32'hF0; b = 32'h00; op = 4'b0101;
        #10;
        $display("XOR: %h ^ %h = %h (expect f0)", a, b, result);

        $display("");
        /////////////////////////////////////////////
        // test SLL
        a = 32'd1; b = 32'd4; op = 4'b0110;
        #10;
        $display("SLL: %b << %0d = %b (expect 00000000000000000000000000010000)", a, b[4:0], result);

        // SLL by 0 — result should equal a unchanged
        a = 32'd15; b = 32'd0; op = 4'b0110;
        #10;
        $display("SLL by 0: %b (expect 00000000000000000000000000001111)", result);

        // SLL by 31 — shift all the way to the sign bit
        a = 32'd1; b = 32'd31; op = 4'b0110;
        #10;
        $display("SLL by 31: %b (expect 10000000000000000000000000000000)", result);

        $display("");
        /////////////////////////////////////////////
        // test SRL
        a = 32'h80000000; b = 32'd1; op = 4'b0111;
        #10;
        $display("SRL: %b >> %0d = %b (expect 01000000000000000000000000000000)", a, b[4:0], result);

        // SRL by 0 — result should equal a unchanged
        a = 32'hF0F0F0F0; b = 32'd0; op = 4'b0111;
        #10;
        $display("SRL by 0: %b (expect 11110000111100001111000011110000)", result);

        // SRL by 4
        a = 32'hF0; b = 32'd4; op = 4'b0111;
        #10;
        $display("SRL by 4: %b (expect 00000000000000000000000000001111)", result);

        // SRL by 31 — only top bit survives
        a = 32'h80000000; b = 32'd31; op = 4'b0111;
        #10;
        $display("SRL by 31: %b (expect 00000000000000000000000000000001)", result);

        $display("");
        /////////////////////////////////////////////
        // test SRA
        a = 32'h80000000; b = 32'd1; op = 4'b1000;
        #10;
        $display("SRA neg: %b >> %0d = %b (expect 11000000000000000000000000000000)", a, b[4:0], result);

        // SRA — positive number, behaves same as SRL
        a = 32'h40000000; b = 32'd1; op = 4'b1000;
        #10;
        $display("SRA pos: %b >> %0d = %b (expect 00100000000000000000000000000000)", a, b[4:0], result);

        // SRA by 4 — negative number, top 4 bits should all become 1
        a = 32'hF0000000; b = 32'd4; op = 4'b1000;
        #10;
        $display("SRA by 4: %b (expect 11111111000000000000000000000000)", result);

        // SRA by 31 — all bits become copies of sign bit
        a = 32'h80000000; b = 32'd31; op = 4'b1000;
        #10;
        $display("SRA by 31: %b (expect 11111111111111111111111111111111)", result);

        // SRA by 31 — positive number all bits become 0
        a = 32'h40000000; b = 32'd31; op = 4'b1000;
        #10;
        $display("SRA by 31 pos: %b (expect 00000000000000000000000000000000)", result);

        $display("");
        /////////////////////////////////////////////
        // SLT basic — a clearly less than b
        a = 32'd5; b = 32'd10; op = 4'b1001;
        #10;
        $display("SLT 5<10: %0d (expect 1)", result);

        // SLT basic — a greater than b
        a = 32'd10; b = 32'd5; op = 4'b1001;
        #10;
        $display("SLT 10<5: %0d (expect 0)", result);

        // SLT equal — should output 0
        a = 32'd7; b = 32'd7; op = 4'b1001;
        #10;
        $display("SLT 7<7: %0d (expect 0)", result);

        // SLT negative vs positive — critical signed test
        a = 32'hFFFFFFFF; b = 32'd1; op = 4'b1001;
        #10;
        $display("SLT -1<1: %0d (expect 1)", result);

        // SLT positive vs negative — should be 0
        a = 32'd1; b = 32'hFFFFFFFF; op = 4'b1001;
        #10;
        $display("SLT 1<-1: %0d (expect 0)", result);

        // SLT most negative vs most positive
        a = 32'h80000000; b = 32'h7FFFFFFF; op = 4'b1001;
        #10;
        $display("SLT MIN<MAX: %0d (expect 1)", result);

        // SLT most positive vs most negative
        a = 32'h7FFFFFFF; b = 32'h80000000; op = 4'b1001;
        #10;
        $display("SLT MAX<MIN: %0d (expect 0)", result);


        $display("");
        /////////////////////////////////////////////
        // SLTU basic — a clearly less than b
        a = 32'd5; b = 32'd10; op = 4'b1010;
        #10;
        $display("SLTU 5<10: %0d (expect 1)", result);

        // SLTU basic — a greater than b
        a = 32'd10; b = 32'd5; op = 4'b1010;
        #10;
        $display("SLTU 10<5: %0d (expect 0)", result);

        // SLTU equal — should output 0
        a = 32'd7; b = 32'd7; op = 4'b1010;
        #10;
        $display("SLTU 7<7: %0d (expect 0)", result);

        // SLTU critical — same bits as SLT -1<1 test but now unsigned
        // 0xFFFFFFFF unsigned = 4294967295, NOT less than 1
        a = 32'hFFFFFFFF; b = 32'd1; op = 4'b1010;
        #10;
        $display("SLTU 0xFFFFFFFF<1: %0d (expect 0)", result);

        // SLTU — 1 vs 0xFFFFFFFF, 1 IS less than 4294967295 unsigned
        a = 32'd1; b = 32'hFFFFFFFF; op = 4'b1010;
        #10;
        $display("SLTU 1<0xFFFFFFFF: %0d (expect 1)", result);

        // SLTU — 0x80000000 unsigned is a large number, NOT less than 0x7FFFFFFF
        a = 32'h80000000; b = 32'h7FFFFFFF; op = 4'b1010;
        #10;
        $display("SLTU 0x80000000<0x7FFFFFFF: %0d (expect 0)", result);

        // SLTU — 0x7FFFFFFF IS less than 0x80000000 unsigned
        a = 32'h7FFFFFFF; b = 32'h80000000; op = 4'b1010;
        #10;
        $display("SLTU 0x7FFFFFFF<0x80000000: %0d (expect 1)", result);


        $display("");
        //////////////////////////////////////////////////////////////////////
        // AUIPC basic — ALU masks bottom 12 bits of b internally
        a = 32'h00001000; b = 32'h00005FFF; op = 4'b1011;
        #10;
        $display("AUIPC: %h + upper(%h) = %h (expect 00006000)", a, b, result);

        // AUIPC — PC at zero
        a = 32'h00000000; b = 32'h00005FFF; op = 4'b1011;
        #10;
        $display("AUIPC PC=0: %h (expect 00005000)", result);

        // AUIPC — bottom 12 bits of b should be ignored
        a = 32'h00000000; b = 32'h00001FFF; op = 4'b1011;
        #10;
        $display("AUIPC mask test: %h (expect 00001000)", result);

        // AUIPC — PC at realistic mid-program address
        a = 32'h00000400; b = 32'h000FF000; op = 4'b1011;
        #10;
        $display("AUIPC mid: %h (expect 000FF400)", result);

        // AUIPC — upper immediate zero, result should equal PC
        a = 32'h00001000; b = 32'h00000FFF; op = 4'b1011;
        #10;
        $display("AUIPC imm=0: %h (expect 00001000)", result);

        $display("");
        ////////////////////////////////////////////////////////////////////////
        // test LUI
        a = 32'h00000000; b = 32'hABCDE000; op = 4'b1100;
        #10;
        $display("LUI: %h (expect ABCDE000)", result);

        a = 32'h00000000; b = 32'hABCDEFFF; op = 4'b1100;
        #10;
        $display("LUI mask: %h (expect ABCDE000)", result);

        a = 32'h00000000; b = 32'h00000FFF; op = 4'b1100;
        #10;
        $display("LUI zero upper: %h (expect 00000000)", result);

        $display("");
        ////////////////////////////////////////////////////////////////////////
        // test PASSA
        a = 32'hDEADBEEF; b = 32'h00000000; op = 4'b1101;
        #10;
        $display("PASSA: %h (expect DEADBEEF)", result);

        a = 32'h00000000; b = 32'hDEADBEEF; op = 4'b1101;
        #10;
        $display("PASSA ignores b: %h (expect 00000000)", result);


        $display("");
        ////////////////////////////////////////////////////////////////////////
        // test PASSB
        a = 32'h00000000; b = 32'hCAFEBABE; op = 4'b1110;
        #10;
        $display("PASSB: %h (expect CAFEBABE)", result);

        a = 32'hDEADBEEF; b = 32'h00000000; op = 4'b1110;
        #10;
        $display("PASSB ignores a: %h (expect 00000000)", result);

        $display("");
        ////////////////////////////////////////////////////////////////////////
        // test ZERO
        a = 32'hDEADBEEF; b = 32'hCAFEBABE; op = 4'b1111;
        #10;
        $display("ZERO: %h (expect 00000000)", result);
        assert(result == 32'd0) else $fatal(1, "ZERO failed!");
        assert(zero == 1'b1)    else $fatal(1, "ZERO zero flag failed!");

        $display("");
        ////////////////////////////////////////////////////////////////////////
        // test DEFAULT
        a = 32'hDEADBEEF; b = 32'hCAFEBABE; op = 4'bXXXX;
        #10;
        $display("DEFAULT: %h (expect 00000000)", result);

        $finish;
    end
endmodule