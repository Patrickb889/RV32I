`timescale 1ns / 1ps

module cpuTop #(
    parameter int IMEM_DEPTH = 1024, // instruction memory depth, in words
    parameter int DMEM_DEPTH = 4096  // data memory depth, in words
) (
    input logic clk,
    input logic reset
);
 
    // Needed locally to tell JALR apart from JAL/branch when picking the next pc
    localparam logic [6:0] OP_JALR = 7'b1100111;
 
    //-------------------------------------------------------------------
    // Program counter
    //-------------------------------------------------------------------
    logic [31:0] pc, pcNext, pcPlus4, pcTarget;
 
    always_ff @(posedge clk) begin
        if (reset) pc <= 32'h0000_0000;
        else       pc <= pcNext;
    end
 
    assign pcPlus4  = pc + 32'd4;
    assign pcTarget = pc + immExt; // JAL / branch target (PC-relative)
 
    //-------------------------------------------------------------------
    // Fetch
    //-------------------------------------------------------------------
    logic [31:0] instr;
 
    iMem #(
        .DEPTH(IMEM_DEPTH)
    ) u_iMem (
        .addr (pc),
        .instr(instr)
    );
 
    //-------------------------------------------------------------------
    // Decode
    //-------------------------------------------------------------------
    logic [6:0]  opcode;
    logic [4:0]  rdAddr, rs1Addr, rs2Addr;
    logic [2:0]  funct3;
    logic [6:0]  funct7;
    logic [31:0] immExt;
    logic        regWrite, aluSrc, opASel, memRead, memWrite;
    logic [1:0]  resultSrc;
    logic        branch, jump;
    logic [3:0]  aluCtrl;
 
    decoder u_decoder (
        .instr    (instr),
        .opcode   (opcode),
        .rdAddr   (rdAddr),
        .rs1Addr  (rs1Addr),
        .rs2Addr  (rs2Addr),
        .funct3   (funct3),
        .funct7   (funct7),
        .immExt   (immExt),
        .regWrite (regWrite),
        .aluSrc   (aluSrc),
        .opASel   (opASel),
        .memRead  (memRead),
        .memWrite (memWrite),
        .resultSrc(resultSrc),
        .branch   (branch),
        .jump     (jump),
        .aluCtrl  (aluCtrl)
    );
 
    //-------------------------------------------------------------------
    // Register file
    //-------------------------------------------------------------------
    logic [31:0] rs1Data, rs2Data, resultW;
 
    register u_register (
        .clk     (clk),
        .we      (regWrite),
        .rd_addr (rdAddr),
        .rd_data (resultW),
        .rs1_addr(rs1Addr),
        .rs1_data(rs1Data),
        .rs2_addr(rs2Addr),
        .rs2_data(rs2Data)
    );
 
    //-------------------------------------------------------------------
    // Execute: ALU operand muxes + ALU
    //-------------------------------------------------------------------
    logic [31:0] srcA, srcB, aluResult;
    logic        aluZero, aluNegative, aluOverflow, aluCarry;
 
    assign srcA = opASel ? pc     : rs1Data; // AUIPC uses PC as operand A
    assign srcB = aluSrc ? immExt : rs2Data; // I/S/U/J-type use the immediate
 
    alu u_alu (
        .a       (srcA),
        .b       (srcB),
        .op      (aluCtrl),
        .result  (aluResult),
        .zero    (aluZero),
        .negative(aluNegative),
        .overflow(aluOverflow),
        .carry   (aluCarry)
    );
 
    //-------------------------------------------------------------------
    // Branch comparator
    //-------------------------------------------------------------------
    logic signed [31:0] rs1Signed, rs2Signed;
    logic                branchTaken;
 
    assign rs1Signed = rs1Data;
    assign rs2Signed = rs2Data;
 
    always_comb begin
        unique case (funct3)
            3'b000:  branchTaken = (rs1Data   == rs2Data);   // BEQ
            3'b001:  branchTaken = (rs1Data   != rs2Data);   // BNE
            3'b100:  branchTaken = (rs1Signed <  rs2Signed); // BLT
            3'b101:  branchTaken = (rs1Signed >= rs2Signed); // BGE
            3'b110:  branchTaken = (rs1Data   <  rs2Data);   // BLTU
            3'b111:  branchTaken = (rs1Data   >= rs2Data);   // BGEU
            default: branchTaken = 1'b0;
        endcase
    end
 
    //-------------------------------------------------------------------
    // Memory
    //-------------------------------------------------------------------
    logic [31:0] dMemReadData;
 
    dMem #(
        .DEPTH(DMEM_DEPTH)
    ) u_dMem (
        .clk       (clk),
        .mem_write (memWrite),
        .addr      (aluResult),
        .write_data(rs2Data),
        .funct3    (funct3),
        .read_data (dMemReadData)
    );
 
    //-------------------------------------------------------------------
    // Writeback mux
    //-------------------------------------------------------------------
    always_comb begin
        unique case (resultSrc)
            2'b00:   resultW = aluResult;    // R-type / I-type / LUI / AUIPC
            2'b01:   resultW = dMemReadData; // loads
            2'b10:   resultW = pcPlus4;      // JAL / JALR link value
            default: resultW = 32'b0;        // reserved
        endcase
    end
 
    //-------------------------------------------------------------------
    // Next-PC mux
    //-------------------------------------------------------------------
    always_comb begin
        if (jump && (opcode == OP_JALR))
            pcNext = {aluResult[31:1], 1'b0};
        else if (jump || (branch && branchTaken))
            pcNext = pcTarget;
        else
            pcNext = pcPlus4;
    end
 
endmodule