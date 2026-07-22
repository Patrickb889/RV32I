`timescale 1ns / 1ps
 
module decoder_tb;
    logic [31:0] instr;
    logic [6:0]  opcode;
    logic [4:0]  rdAddr, rs1Addr, rs2Addr;
    logic [2:0]  funct3;
    logic [6:0]  funct7;
    logic [31:0] immExt;
    logic        regWrite, aluSrc, opASel, memRead, memWrite, branch, jump;
    logic [1:0]  resultSrc;
    logic [3:0]  aluCtrl;
 
    decoder dut (.*);
 
    //counters
    int passCount = 0;
    int failCount = 0;
 
    // constants
    localparam logic [6:0] OP_LOAD   = 7'b0000011;
    localparam logic [6:0] OP_STORE  = 7'b0100011;
    localparam logic [6:0] OP_RTYPE  = 7'b0110011;
    localparam logic [6:0] OP_ITYPE  = 7'b0010011;
    localparam logic [6:0] OP_BRANCH = 7'b1100011;
    localparam logic [6:0] OP_JAL    = 7'b1101111;
    localparam logic [6:0] OP_JALR   = 7'b1100111;
    localparam logic [6:0] OP_LUI    = 7'b0110111;
    localparam logic [6:0] OP_AUIPC  = 7'b0010111;
 
    localparam logic [3:0] ALU_ADD   = 4'b0000;
    localparam logic [3:0] ALU_SUB   = 4'b0001;
    localparam logic [3:0] ALU_AND   = 4'b0010;
    localparam logic [3:0] ALU_OR    = 4'b0011;
    localparam logic [3:0] ALU_XOR   = 4'b0101;
    localparam logic [3:0] ALU_SLL   = 4'b0110;
    localparam logic [3:0] ALU_SRL   = 4'b0111;
    localparam logic [3:0] ALU_SRA   = 4'b1000;
    localparam logic [3:0] ALU_SLT   = 4'b1001;
    localparam logic [3:0] ALU_SLTU  = 4'b1010;
    localparam logic [3:0] ALU_AUIPC = 4'b1011;
    localparam logic [3:0] ALU_LUI   = 4'b1100;

    // Expected-control bundle + constructor
    typedef struct packed {
        logic       regWrite;
        logic       aluSrc;
        logic       opASel;
        logic       memRead;
        logic       memWrite;
        logic [1:0] resultSrc;
        logic       branch;
        logic       jump;
        logic [3:0] aluCtrl;
    } ctrl_t;
 
    function automatic ctrl_t mkCtrl(
        logic rw, logic as, logic oa, logic mr, logic mw,
        logic [1:0] rs, logic br, logic jp, logic [3:0] ac
    );
        ctrl_t c;
        c.regWrite = rw; c.aluSrc = as; c.opASel = oa;
        c.memRead  = mr; c.memWrite = mw; c.resultSrc = rs;
        c.branch   = br; c.jump = jp; c.aluCtrl = ac;
        return c;
    endfunction
 
    // RV32I instruction encoders
    function automatic logic [31:0] rType(logic [6:0] f7, logic [4:0] rs2,
            logic [4:0] rs1, logic [2:0] f3, logic [4:0] rd, logic [6:0] op);
        return {f7, rs2, rs1, f3, rd, op};
    endfunction
 
    function automatic logic [31:0] iType(logic [31:0] imm, logic [4:0] rs1,
            logic [2:0] f3, logic [4:0] rd, logic [6:0] op);
        return {imm[11:0], rs1, f3, rd, op};
    endfunction
 
    function automatic logic [31:0] sType(logic [31:0] imm, logic [4:0] rs2,
            logic [4:0] rs1, logic [2:0] f3, logic [6:0] op);
        return {imm[11:5], rs2, rs1, f3, imm[4:0], op};
    endfunction
 
    function automatic logic [31:0] bType(logic [31:0] imm, logic [4:0] rs2,
            logic [4:0] rs1, logic [2:0] f3, logic [6:0] op);
        return {imm[12], imm[10:5], rs2, rs1, f3, imm[4:1], imm[11], op};
    endfunction
 
    function automatic logic [31:0] uType(logic [31:0] imm, logic [4:0] rd, logic [6:0] op);
        return {imm[31:12], rd, op};
    endfunction
 
    function automatic logic [31:0] jType(logic [31:0] imm, logic [4:0] rd, logic [6:0] op);
        return {imm[20], imm[10:1], imm[11], imm[19:12], rd, op};
    endfunction

    // Checkers
    task automatic checkCtrl(string name, logic [31:0] i, ctrl_t exp);
        bit ok;
        ok = 1'b1;
        instr = i;
        #1;
        if (regWrite  !== exp.regWrite)  begin ok = 0; $display("    regWrite  got=%b exp=%b", regWrite, exp.regWrite); end
        if (aluSrc    !== exp.aluSrc)    begin ok = 0; $display("    aluSrc    got=%b exp=%b", aluSrc, exp.aluSrc); end
        if (opASel    !== exp.opASel)    begin ok = 0; $display("    opASel    got=%b exp=%b", opASel, exp.opASel); end
        if (memRead   !== exp.memRead)   begin ok = 0; $display("    memRead   got=%b exp=%b", memRead, exp.memRead); end
        if (memWrite  !== exp.memWrite)  begin ok = 0; $display("    memWrite  got=%b exp=%b", memWrite, exp.memWrite); end
        if (resultSrc !== exp.resultSrc) begin ok = 0; $display("    resultSrc got=%b exp=%b", resultSrc, exp.resultSrc); end
        if (branch    !== exp.branch)    begin ok = 0; $display("    branch    got=%b exp=%b", branch, exp.branch); end
        if (jump      !== exp.jump)      begin ok = 0; $display("    jump      got=%b exp=%b", jump, exp.jump); end
        if (aluCtrl   !== exp.aluCtrl)   begin ok = 0; $display("    aluCtrl   got=%b exp=%b", aluCtrl, exp.aluCtrl); end
 
        if (ok) passCount++;
        else begin
            failCount++;
            $display("  FAIL [%0s]  instr=%08h", name, i);
        end
    endtask
 
    task automatic checkImm(string name, logic [31:0] i, logic [31:0] expImm);
        instr = i;
        #1;
        if (immExt !== expImm) begin
            failCount++;
            $display("  FAIL [%0s]  instr=%08h  immExt got=%08h exp=%08h", name, i, immExt, expImm);
        end else passCount++;
    endtask
 
    task automatic checkField(string name, logic [6:0] eOp, logic [4:0] eRd,
            logic [2:0] eF3, logic [4:0] eRs1, logic [4:0] eRs2, logic [6:0] eF7);
        bit ok;
        ok = 1'b1;
        if (opcode  !== eOp)  begin ok = 0; $display("    opcode  got=%b exp=%b", opcode, eOp); end
        if (rdAddr  !== eRd)  begin ok = 0; $display("    rdAddr  got=%b exp=%b", rdAddr, eRd); end
        if (funct3  !== eF3)  begin ok = 0; $display("    funct3  got=%b exp=%b", funct3, eF3); end
        if (rs1Addr !== eRs1) begin ok = 0; $display("    rs1Addr got=%b exp=%b", rs1Addr, eRs1); end
        if (rs2Addr !== eRs2) begin ok = 0; $display("    rs2Addr got=%b exp=%b", rs2Addr, eRs2); end
        if (funct7  !== eF7)  begin ok = 0; $display("    funct7  got=%b exp=%b", funct7, eF7); end
        if (ok) passCount++;
        else begin
            failCount++;
            $display("  FAIL [%0s]", name);
        end
    endtask

    //Test
    initial begin
        $display("=====================================================");
        $display(" decoder_tb -- starting");
        $display("=====================================================");
 
        // ---------------- R-type (10) ----------------
        $display("\n-- R-type --");
        checkCtrl("add",  rType(7'b0000000,5'd2,5'd1,3'b000,5'd3,OP_RTYPE), mkCtrl(1,0,0,0,0,2'b00,0,0,ALU_ADD));
        checkCtrl("sub",  rType(7'b0100000,5'd2,5'd1,3'b000,5'd3,OP_RTYPE), mkCtrl(1,0,0,0,0,2'b00,0,0,ALU_SUB));
        checkCtrl("sll",  rType(7'b0000000,5'd2,5'd1,3'b001,5'd3,OP_RTYPE), mkCtrl(1,0,0,0,0,2'b00,0,0,ALU_SLL));
        checkCtrl("slt",  rType(7'b0000000,5'd2,5'd1,3'b010,5'd3,OP_RTYPE), mkCtrl(1,0,0,0,0,2'b00,0,0,ALU_SLT));
        checkCtrl("sltu", rType(7'b0000000,5'd2,5'd1,3'b011,5'd3,OP_RTYPE), mkCtrl(1,0,0,0,0,2'b00,0,0,ALU_SLTU));
        checkCtrl("xor",  rType(7'b0000000,5'd2,5'd1,3'b100,5'd3,OP_RTYPE), mkCtrl(1,0,0,0,0,2'b00,0,0,ALU_XOR));
        checkCtrl("srl",  rType(7'b0000000,5'd2,5'd1,3'b101,5'd3,OP_RTYPE), mkCtrl(1,0,0,0,0,2'b00,0,0,ALU_SRL));
        checkCtrl("sra",  rType(7'b0100000,5'd2,5'd1,3'b101,5'd3,OP_RTYPE), mkCtrl(1,0,0,0,0,2'b00,0,0,ALU_SRA));
        checkCtrl("or",   rType(7'b0000000,5'd2,5'd1,3'b110,5'd3,OP_RTYPE), mkCtrl(1,0,0,0,0,2'b00,0,0,ALU_OR));
        checkCtrl("and",  rType(7'b0000000,5'd2,5'd1,3'b111,5'd3,OP_RTYPE), mkCtrl(1,0,0,0,0,2'b00,0,0,ALU_AND));
 
        // ---------------- I-type ALU (9) ----------------
        $display("\n-- I-type ALU --");
        checkCtrl("addi",  iType(32'd100,5'd1,3'b000,5'd3,OP_ITYPE), mkCtrl(1,1,0,0,0,2'b00,0,0,ALU_ADD));
        checkCtrl("slti",  iType(32'd5,  5'd1,3'b010,5'd3,OP_ITYPE), mkCtrl(1,1,0,0,0,2'b00,0,0,ALU_SLT));
        checkCtrl("sltiu", iType(32'd5,  5'd1,3'b011,5'd3,OP_ITYPE), mkCtrl(1,1,0,0,0,2'b00,0,0,ALU_SLTU));
        checkCtrl("xori",  iType(32'd5,  5'd1,3'b100,5'd3,OP_ITYPE), mkCtrl(1,1,0,0,0,2'b00,0,0,ALU_XOR));
        checkCtrl("ori",   iType(32'd5,  5'd1,3'b110,5'd3,OP_ITYPE), mkCtrl(1,1,0,0,0,2'b00,0,0,ALU_OR));
        checkCtrl("andi",  iType(32'd5,  5'd1,3'b111,5'd3,OP_ITYPE), mkCtrl(1,1,0,0,0,2'b00,0,0,ALU_AND));
        checkCtrl("slli",  iType({20'b0,7'b0000000,5'd3},5'd1,3'b001,5'd3,OP_ITYPE), mkCtrl(1,1,0,0,0,2'b00,0,0,ALU_SLL));
        checkCtrl("srli",  iType({20'b0,7'b0000000,5'd3},5'd1,3'b101,5'd3,OP_ITYPE), mkCtrl(1,1,0,0,0,2'b00,0,0,ALU_SRL));
        checkCtrl("srai",  iType({20'b0,7'b0100000,5'd3},5'd1,3'b101,5'd3,OP_ITYPE), mkCtrl(1,1,0,0,0,2'b00,0,0,ALU_SRA));
 
        // ---------------- Loads (5) ----------------
        $display("\n-- Loads --");
        checkCtrl("lb",  iType(32'd4,5'd1,3'b000,5'd3,OP_LOAD), mkCtrl(1,1,0,1,0,2'b01,0,0,ALU_ADD));
        checkCtrl("lh",  iType(32'd4,5'd1,3'b001,5'd3,OP_LOAD), mkCtrl(1,1,0,1,0,2'b01,0,0,ALU_ADD));
        checkCtrl("lw",  iType(32'd4,5'd1,3'b010,5'd3,OP_LOAD), mkCtrl(1,1,0,1,0,2'b01,0,0,ALU_ADD));
        checkCtrl("lbu", iType(32'd4,5'd1,3'b100,5'd3,OP_LOAD), mkCtrl(1,1,0,1,0,2'b01,0,0,ALU_ADD));
        checkCtrl("lhu", iType(32'd4,5'd1,3'b101,5'd3,OP_LOAD), mkCtrl(1,1,0,1,0,2'b01,0,0,ALU_ADD));
 
        // ---------------- Stores (3) ----------------
        $display("\n-- Stores --");
        checkCtrl("sb", sType(32'd4,5'd2,5'd1,3'b000,OP_STORE), mkCtrl(0,1,0,0,1,2'b00,0,0,ALU_ADD));
        checkCtrl("sh", sType(32'd4,5'd2,5'd1,3'b001,OP_STORE), mkCtrl(0,1,0,0,1,2'b00,0,0,ALU_ADD));
        checkCtrl("sw", sType(32'd4,5'd2,5'd1,3'b010,OP_STORE), mkCtrl(0,1,0,0,1,2'b00,0,0,ALU_ADD));
 
        // ---------------- Branches (6) ----------------
        $display("\n-- Branches --");
        checkCtrl("beq",  bType(32'd8,5'd2,5'd1,3'b000,OP_BRANCH), mkCtrl(0,0,0,0,0,2'b00,1,0,ALU_SUB));
        checkCtrl("bne",  bType(32'd8,5'd2,5'd1,3'b001,OP_BRANCH), mkCtrl(0,0,0,0,0,2'b00,1,0,ALU_SUB));
        checkCtrl("blt",  bType(32'd8,5'd2,5'd1,3'b100,OP_BRANCH), mkCtrl(0,0,0,0,0,2'b00,1,0,ALU_SUB));
        checkCtrl("bge",  bType(32'd8,5'd2,5'd1,3'b101,OP_BRANCH), mkCtrl(0,0,0,0,0,2'b00,1,0,ALU_SUB));
        checkCtrl("bltu", bType(32'd8,5'd2,5'd1,3'b110,OP_BRANCH), mkCtrl(0,0,0,0,0,2'b00,1,0,ALU_SUB));
        checkCtrl("bgeu", bType(32'd8,5'd2,5'd1,3'b111,OP_BRANCH), mkCtrl(0,0,0,0,0,2'b00,1,0,ALU_SUB));
 
        // ---------------- Jumps (2) ----------------
        $display("\n-- Jumps --");
        checkCtrl("jal",  jType(32'd100,5'd1,OP_JAL),           mkCtrl(1,0,0,0,0,2'b10,0,1,ALU_ADD));
        checkCtrl("jalr", iType(32'd4,5'd2,3'b000,5'd1,OP_JALR), mkCtrl(1,1,0,0,0,2'b10,0,1,ALU_ADD));
 
        // ---------------- Upper immediate (2) ----------------
        $display("\n-- Upper immediate --");
        checkCtrl("lui",   uType(32'h12345,5'd5,OP_LUI),   mkCtrl(1,1,0,0,0,2'b00,0,0,ALU_LUI));
        checkCtrl("auipc", uType(32'h12345,5'd5,OP_AUIPC), mkCtrl(1,1,1,0,0,2'b00,0,0,ALU_AUIPC));
 
        // ---------------- ADD/SUB & SRL/SRA disambiguation trap ----------------
        $display("\n-- funct7[5] disambiguation trap --");
        checkCtrl("addi imm=-1 (bit30 set, all-ones imm)",
            iType(32'hFFFFFFFF,5'd1,3'b000,5'd3,OP_ITYPE), mkCtrl(1,1,0,0,0,2'b00,0,0,ALU_ADD));
        checkCtrl("addi imm=1024 (bit30 set, positive imm)",
            iType(32'd1024,5'd1,3'b000,5'd3,OP_ITYPE), mkCtrl(1,1,0,0,0,2'b00,0,0,ALU_ADD));
        checkCtrl("sub sanity (funct7[5]=1, R-type -- must be SUB)",
            rType(7'b0100000,5'd2,5'd1,3'b000,5'd3,OP_RTYPE), mkCtrl(1,0,0,0,0,2'b00,0,0,ALU_SUB));
 
        // ---------------- Illegal / unimplemented opcodes ----------------
        $display("\n-- Illegal/unimplemented opcodes --");
        checkCtrl("FENCE (garbage fields)",    {{25{1'b1}}, 7'b0001111}, mkCtrl(0,0,0,0,0,2'b00,0,0,ALU_ADD));
        checkCtrl("SYSTEM (garbage fields)",   {{25{1'b1}}, 7'b1110011}, mkCtrl(0,0,0,0,0,2'b00,0,0,ALU_ADD));
        checkCtrl("reserved 1111111 (garbage)",{{25{1'b1}}, 7'b1111111}, mkCtrl(0,0,0,0,0,2'b00,0,0,ALU_ADD));
        checkCtrl("all-zero instruction word", 32'h00000000, mkCtrl(0,0,0,0,0,2'b00,0,0,ALU_ADD));
 
        // ---------------- x0 passthrough ----------------
        $display("\n-- x0 passthrough --");
        checkCtrl("add x0,x1,x2 (regWrite still asserted)",
            rType(7'b0000000,5'd2,5'd1,3'b000,5'd0,OP_RTYPE), mkCtrl(1,0,0,0,0,2'b00,0,0,ALU_ADD));
        checkField("rdAddr reads back as literal 0, unaltered",
            OP_RTYPE, 5'd0, 3'b000, 5'd1, 5'd2, 7'b0000000);
 
        // ---------------- Raw field-extraction boundaries ----------------
        $display("\n-- Field extraction at 0x00000000 / 0xFFFFFFFF --");
        instr = 32'hFFFFFFFF; #1;
        checkField("all-ones instruction", 7'h7F, 5'h1F, 3'h7, 5'h1F, 5'h1F, 7'h7F);
        instr = 32'h00000000; #1;
        checkField("all-zero instruction", 7'h00, 5'h00, 3'h0, 5'h00, 5'h00, 7'h00);
 
        // ---------------- Immediate boundaries (independently computed) ----------------
        $display("\n-- Immediate boundaries (I/S/B/U/J) --");
        checkImm("I-imm max +2047", 32'h7ff08193, 32'h000007ff);
        checkImm("I-imm min -2048", 32'h80008193, 32'hfffff800);
        checkImm("I-imm zero",      32'h00008193, 32'h00000000);
        checkImm("S-imm max +2047", 32'h7e20afa3, 32'h000007ff);
        checkImm("S-imm min -2048", 32'h8020a023, 32'hfffff800);
        checkImm("S-imm zero",      32'h0020a023, 32'h00000000);
        checkImm("B-imm max +4094", 32'h7e208fe3, 32'h00000ffe);
        checkImm("B-imm min -4096", 32'h80208063, 32'hfffff000);
        checkImm("B-imm zero",      32'h00208063, 32'h00000000);
        checkImm("U-imm max 0xFFFFF",         32'hfffff2b7, 32'hfffff000);
        checkImm("U-imm zero",                32'h000002b7, 32'h00000000);
        checkImm("U-imm sign-bit-only 0x80000", 32'h800002b7, 32'h80000000);
        checkImm("J-imm max +1048574", 32'h7ffff0ef, 32'h000ffffe);
        checkImm("J-imm min -1048576", 32'h800000ef, 32'hfff00000);
        checkImm("J-imm zero",         32'h000000ef, 32'h00000000);
 
        // ---------------- Randomized independence spot-check ----------------
        // Control signals must depend only on opcode/funct3/funct7[5]
        // never on register addresses or immediate value.
        $display("\n-- Randomized independence spot-check --");
        for (int k = 0; k < 16; k++) begin
            logic [4:0]  rrd, rrs1, rrs2;
            logic [11:0] rimm;
            rrd  = $random;
            rrs1 = $random;
            rrs2 = $random;
            rimm = $random;
 
            instr = rType(7'b0000000, rrs2, rrs1, 3'b000, rrd, OP_RTYPE);
            #1;
            if (aluCtrl !== ALU_ADD || regWrite !== 1'b1 ||
                rdAddr !== rrd || rs1Addr !== rrs1 || rs2Addr !== rrs2) begin
                failCount++;
                $display("  FAIL: random ADD iter %0d  rd=%0d rs1=%0d rs2=%0d  aluCtrl=%b regWrite=%b",
                          k, rrd, rrs1, rrs2, aluCtrl, regWrite);
            end else passCount++;
 
            instr = iType({{20{rimm[11]}}, rimm}, rrs1, 3'b000, rrd, OP_ITYPE);
            #1;
            if (immExt !== {{20{rimm[11]}}, rimm} || aluCtrl !== ALU_ADD) begin
                failCount++;
                $display("  FAIL: random ADDI iter %0d  imm=%03h  immExt=%08h", k, rimm, immExt);
            end else passCount++;
        end
 
        // ---------------- Summary ----------------
        $display("\n=====================================================");
        $display(" %0d PASSED, %0d FAILED", passCount, failCount);
        $display("=====================================================\n");
 
        $finish;
    end
 
endmodule
 