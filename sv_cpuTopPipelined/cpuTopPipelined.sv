`timescale 1ns / 1ps

module cpuTopPipelined #(
    parameter int IMEM_DEPTH = 1024,
    parameter int DMEM_DEPTH = 4096
) (
    input logic clk,
    input logic reset
);
 
    localparam logic [6:0]  OP_JALR = 7'b1100111;
 
    //=================================================================
    // IF stage
    //=================================================================
    logic [31:0] pcF, pcFPlus4, pcNext;
    logic        pcStall;
 
    always_ff @(posedge clk) begin
        if (reset)         pcF <= 32'h0000_0000;
        else if (!pcStall) pcF <= pcNext;
    end
 
    assign pcFPlus4 = pcF + 32'd4;
 
    logic [31:0] instrF;
 
    iMem #(
        .DEPTH(IMEM_DEPTH)
    ) u_iMem (
        .addr (pcF),
        .instr(instrF)
    );
 
    //-----------------------------------------------------------------
    // IF/ID register
    //-----------------------------------------------------------------
    logic        ifidStall, ifidFlush;
    logic [31:0] pcD, pcPlus4D, instrD;
 
    ifidReg u_ifidReg (
        .clk       (clk),
        .reset     (reset),
        .stall     (ifidStall),
        .flush     (ifidFlush),
        .pcIn      (pcF),
        .pcPlus4In (pcFPlus4),
        .instrIn   (instrF),
        .pcOut     (pcD),
        .pcPlus4Out(pcPlus4D),
        .instrOut  (instrD)
    );
 
    //=================================================================
    // ID stage
    //=================================================================
    logic [6:0]  opcodeD;
    logic [4:0]  rdAddrD, rs1AddrD, rs2AddrD;
    logic [2:0]  funct3D;
    logic [6:0]  funct7D;
    logic [31:0] immExtD;
    logic        regWriteD, aluSrcD, opASelD, memReadD, memWriteD;
    logic [1:0]  resultSrcD;
    logic        branchD, jumpD;
    logic [3:0]  aluCtrlD;
 
    decoder u_decoder (
        .instr    (instrD),
        .opcode   (opcodeD),
        .rdAddr   (rdAddrD),
        .rs1Addr  (rs1AddrD),
        .rs2Addr  (rs2AddrD),
        .funct3   (funct3D),
        .funct7   (funct7D),
        .immExt   (immExtD),
        .regWrite (regWriteD),
        .aluSrc   (aluSrcD),
        .opASel   (opASelD),
        .memRead  (memReadD),
        .memWrite (memWriteD),
        .resultSrc(resultSrcD),
        .branch   (branchD),
        .jump     (jumpD),
        .aluCtrl  (aluCtrlD)
    );
 
    // ---- writeback signals, declared here since the register file
    // (read in ID) needs resultW/regWriteW/rdAddrW as its write port,
    // even though they're driven combinationally from WB at the
    // bottom of this module ----
    logic [31:0] resultW;
    logic [4:0]  rdAddrW;
    logic        regWriteW;
 
    logic [31:0] rs1DataD, rs2DataD;
 
    register u_register (
        .clk     (clk),
        .we      (regWriteW),
        .rd_addr (rdAddrW),
        .rd_data (resultW),
        .rs1_addr(rs1AddrD),
        .rs1_data(rs1DataD),
        .rs2_addr(rs2AddrD),
        .rs2_data(rs2DataD)
    );
 
    //-----------------------------------------------------------------
    // ID-stage forwarding (branch/JALR operands only)
    //-----------------------------------------------------------------
    logic [1:0]  forwardAD, forwardBD;
    logic [31:0] aluResultE; // forward source, defined down in EX
 
    logic [31:0] rs1DataDFwd, rs2DataDFwd;
 
    assign rs1DataDFwd = (forwardAD == 2'b01) ? aluResultE :
                          (forwardAD == 2'b10) ? resultW    : rs1DataD;
 
    assign rs2DataDFwd = (forwardBD == 2'b01) ? aluResultE :
                          (forwardBD == 2'b10) ? resultW    : rs2DataD;
 
    //-----------------------------------------------------------------
    // Branch/jump resolution (moved out of EX and into ID)
    //-----------------------------------------------------------------
    logic signed [31:0] rs1SignedD, rs2SignedD;
    logic                branchTakenD;
 
    assign rs1SignedD = rs1DataDFwd;
    assign rs2SignedD = rs2DataDFwd;
 
    always_comb begin
        unique case (funct3D)
            3'b000:  branchTakenD = (rs1DataDFwd == rs2DataDFwd); // BEQ
            3'b001:  branchTakenD = (rs1DataDFwd != rs2DataDFwd); // BNE
            3'b100:  branchTakenD = (rs1SignedD  <  rs2SignedD);  // BLT
            3'b101:  branchTakenD = (rs1SignedD  >= rs2SignedD);  // BGE
            3'b110:  branchTakenD = (rs1DataDFwd <  rs2DataDFwd); // BLTU
            3'b111:  branchTakenD = (rs1DataDFwd >= rs2DataDFwd); // BGEU
            default: branchTakenD = 1'b0;
        endcase
    end
 
    logic [31:0] branchTargetD, jalrTargetD, jalrSum;
 
    assign branchTargetD = pcD + immExtD;              // JAL / branch target
    assign jalrSum       = rs1DataDFwd + immExtD;
    assign jalrTargetD   = {jalrSum[31:1], 1'b0};       // JALR target (LSB cleared)
 
    logic idResolves, pcRedirect;
 
    assign idResolves = branchD || (jumpD && (opcodeD == OP_JALR));
    assign pcRedirect = !loadUseStall && (jumpD || (branchD && branchTakenD));
 
    always_comb begin
        if (jumpD && (opcodeD == OP_JALR))
            pcNext = jalrTargetD;
        else if (jumpD || (branchD && branchTakenD))
            pcNext = branchTargetD;
        else
            pcNext = pcFPlus4;
    end
 
    assign ifidFlush = pcRedirect;
 
    //-----------------------------------------------------------------
    // Hazard detection
    //-----------------------------------------------------------------
    logic loadUseStall;
 
    hazardUnit u_hazardUnit (
        .idResolves  (idResolves),
        .idRs1Addr   (rs1AddrD),
        .idRs2Addr   (rs2AddrD),
        .idExMemRead (memReadE),
        .idExRegWrite(regWriteE),
        .idExRdAddr  (rdAddrE),
        .exMemMemRead(memReadM),
        .exMemRdAddr (rdAddrM),
        .stall       (loadUseStall)
    );
 
    assign pcStall   = loadUseStall;
    assign ifidStall = loadUseStall;
 
    //-----------------------------------------------------------------
    // ID/EX register
    //-----------------------------------------------------------------
    logic [31:0] pcE, pcPlus4E, rs1DataE, rs2DataE, immExtE;
    logic [4:0]  rs1AddrE, rs2AddrE, rdAddrE;
    logic [2:0]  funct3E;
    logic        regWriteE, aluSrcE, opASelE, memReadE, memWriteE;
    logic [1:0]  resultSrcE;
    logic [3:0]  aluCtrlE;
 
    idexReg u_idexReg (
        .clk        (clk),
        .reset      (reset),
        .flush      (loadUseStall),
 
        .pcIn       (pcD),
        .pcPlus4In  (pcPlus4D),
        .rs1DataIn  (rs1DataD),
        .rs2DataIn  (rs2DataD),
        .rs1AddrIn  (rs1AddrD),
        .rs2AddrIn  (rs2AddrD),
        .rdAddrIn   (rdAddrD),
        .immExtIn   (immExtD),
        .funct3In   (funct3D),
 
        .regWriteIn (regWriteD),
        .aluSrcIn   (aluSrcD),
        .opASelIn   (opASelD),
        .memReadIn  (memReadD),
        .memWriteIn (memWriteD),
        .resultSrcIn(resultSrcD),
        .aluCtrlIn  (aluCtrlD),
 
        .pcOut       (pcE),
        .pcPlus4Out  (pcPlus4E),
        .rs1DataOut  (rs1DataE),
        .rs2DataOut  (rs2DataE),
        .rs1AddrOut  (rs1AddrE),
        .rs2AddrOut  (rs2AddrE),
        .rdAddrOut   (rdAddrE),
        .immExtOut   (immExtE),
        .funct3Out   (funct3E),
 
        .regWriteOut (regWriteE),
        .aluSrcOut   (aluSrcE),
        .opASelOut   (opASelE),
        .memReadOut  (memReadE),
        .memWriteOut (memWriteE),
        .resultSrcOut(resultSrcE),
        .aluCtrlOut  (aluCtrlE)
    );
 
    //=================================================================
    // EX stage
    //=================================================================
    logic [1:0]  forwardAE, forwardBE;
    logic [31:0] rs1DataEFwd, rs2DataEFwd;
 
    forwardUnit u_forwardUnit (
        .idExRs1Addr  (rs1AddrE),
        .idExRs2Addr  (rs2AddrE),
        .idRs1Addr    (rs1AddrD),
        .idRs2Addr    (rs2AddrD),
        .exMemRegWrite(regWriteM),
        .exMemMemRead (memReadM),
        .exMemRdAddr  (rdAddrM),
        .memWbRegWrite(regWriteW),
        .memWbRdAddr  (rdAddrW),
        .forwardAE    (forwardAE),
        .forwardBE    (forwardBE),
        .forwardAD    (forwardAD),
        .forwardBD    (forwardBD)
    );
 
    assign rs1DataEFwd = (forwardAE == 2'b10) ? aluResultM :
                          (forwardAE == 2'b01) ? resultW    : rs1DataE;
 
    assign rs2DataEFwd = (forwardBE == 2'b10) ? aluResultM :
                          (forwardBE == 2'b01) ? resultW    : rs2DataE;
 
    logic [31:0] srcA, srcB;
    logic        aluZeroE, aluNegativeE, aluOverflowE, aluCarryE;
 
    assign srcA = opASelE ? pcE     : rs1DataEFwd; // AUIPC uses PC as operand A
    assign srcB = aluSrcE ? immExtE : rs2DataEFwd; // I/S/U/J-type use the immediate
 
    alu u_alu (
        .a       (srcA),
        .b       (srcB),
        .op      (aluCtrlE),
        .result  (aluResultE),
        .zero    (aluZeroE),
        .negative(aluNegativeE),
        .overflow(aluOverflowE),
        .carry   (aluCarryE)
    );
 
    //-----------------------------------------------------------------
    // EX/MEM register
    //-----------------------------------------------------------------
    logic [31:0] aluResultM, writeDataM, pcPlus4M;
    logic [4:0]  rdAddrM;
    logic [2:0]  funct3M;
    logic        regWriteM, memReadM, memWriteM;
    logic [1:0]  resultSrcM;
 
    exmemReg u_exmemReg (
        .clk        (clk),
        .reset      (reset),
 
        .aluResultIn(aluResultE),
        .writeDataIn(rs2DataEFwd),
        .rdAddrIn   (rdAddrE),
        .funct3In   (funct3E),
        .pcPlus4In  (pcPlus4E),
 
        .regWriteIn (regWriteE),
        .memReadIn  (memReadE),
        .memWriteIn (memWriteE),
        .resultSrcIn(resultSrcE),
 
        .aluResultOut(aluResultM),
        .writeDataOut(writeDataM),
        .rdAddrOut   (rdAddrM),
        .funct3Out   (funct3M),
        .pcPlus4Out  (pcPlus4M),
 
        .regWriteOut (regWriteM),
        .memReadOut  (memReadM),
        .memWriteOut (memWriteM),
        .resultSrcOut(resultSrcM)
    );
 
    //=================================================================
    // MEM stage
    //=================================================================
    logic [31:0] dMemReadDataM;
 
    dMem #(
        .DEPTH(DMEM_DEPTH)
    ) u_dMem (
        .clk       (clk),
        .mem_write (memWriteM),
        .addr      (aluResultM),
        .write_data(writeDataM),
        .funct3    (funct3M),
        .read_data (dMemReadDataM)
    );
 
    //-----------------------------------------------------------------
    // MEM/WB register
    //-----------------------------------------------------------------
    logic [31:0] aluResultWReg, readDataW, pcPlus4W;
    logic [1:0]  resultSrcW;
 
    memwbReg u_memwbReg (
        .clk        (clk),
        .reset      (reset),
 
        .aluResultIn(aluResultM),
        .readDataIn (dMemReadDataM),
        .pcPlus4In  (pcPlus4M),
        .rdAddrIn   (rdAddrM),
 
        .regWriteIn (regWriteM),
        .resultSrcIn(resultSrcM),
 
        .aluResultOut(aluResultWReg),
        .readDataOut (readDataW),
        .pcPlus4Out  (pcPlus4W),
        .rdAddrOut   (rdAddrW),
 
        .regWriteOut (regWriteW),
        .resultSrcOut(resultSrcW)
    );
 
    //=================================================================
    // WB stage
    //=================================================================
    always_comb begin
        unique case (resultSrcW)
            2'b00:   resultW = aluResultWReg; // R-type / I-type / LUI / AUIPC
            2'b01:   resultW = readDataW;     // loads
            2'b10:   resultW = pcPlus4W;      // JAL / JALR link value
            default: resultW = 32'b0;         // reserved
        endcase
    end
 
endmodule