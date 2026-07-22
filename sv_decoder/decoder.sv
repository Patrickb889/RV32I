`timescale 1ns / 1ps
 
module decoder (
    input  logic [31:0] instr,      // instruction word from IF/ID register
 
    // Raw fields
    output logic [6:0]  opcode,
    output logic [4:0]  rdAddr,     // destination register address
    output logic [4:0]  rs1Addr,    // source register 1 address -> regFile port A
    output logic [4:0]  rs2Addr,    // source register 2 address -> regFile port B
    output logic [2:0]  funct3,     // sub-op select; also identifies branch/load/store width
    output logic [6:0]  funct7,     // sub-op select (bit 5 = ADD/SUB, SRL/SRA discriminator)
 
    // Sign-extended immediate
    output logic [31:0] immExt,
 
    // Main control signals
    output logic        regWrite,   // 1 = write result back to rdAddr
    output logic        aluSrc,     // 0 = ALU operand B is rs2, 1 = immediate.
    output logic        opASel,     // 0 = ALU operand A is rs1, 1 = PC (AUIPC only)
    output logic        memRead,    // 1 = dMem read enable
    output logic        memWrite,   // 1 = dMem write enable
    output logic [1:0]  resultSrc,  // writeback mux: 00=ALU 01=MemData 10=PC+4 11=reserved
    output logic        branch,     // 1 = branch instruction
    output logic        jump,       // 1 = unconditional jump
 
    // ALU control
    output logic [3:0]  aluCtrl
);
 
    assign opcode   = instr[6:0];
    assign rdAddr   = instr[11:7];
    assign funct3   = instr[14:12];
    assign rs1Addr  = instr[19:15];
    assign rs2Addr  = instr[24:20];
    assign funct7   = instr[31:25];
 
    localparam logic [2:0] IMM_I = 3'b000;
    localparam logic [2:0] IMM_S = 3'b001;
    localparam logic [2:0] IMM_B = 3'b010;
    localparam logic [2:0] IMM_U = 3'b011;
    localparam logic [2:0] IMM_J = 3'b100;
 
    logic [2:0] immSrc;
    logic [2:0] aluOp;
 
    localparam logic [2:0] ALUOP_ADD   = 3'b000;
    localparam logic [2:0] ALUOP_SUB   = 3'b001;
    localparam logic [2:0] ALUOP_FUNCT = 3'b010;
    localparam logic [2:0] ALUOP_LUI   = 3'b011;
    localparam logic [2:0] ALUOP_AUIPC = 3'b100;
 
    // RV32I base opcode map (bits [6:0])
    localparam logic [6:0] OP_LOAD   = 7'b0000011;
    localparam logic [6:0] OP_STORE  = 7'b0100011;
    localparam logic [6:0] OP_RTYPE  = 7'b0110011;
    localparam logic [6:0] OP_ITYPE  = 7'b0010011;
    localparam logic [6:0] OP_BRANCH = 7'b1100011;
    localparam logic [6:0] OP_JAL    = 7'b1101111;
    localparam logic [6:0] OP_JALR   = 7'b1100111;
    localparam logic [6:0] OP_LUI    = 7'b0110111;
    localparam logic [6:0] OP_AUIPC  = 7'b0010111;
 
    // Main decoder
    always_comb begin
        regWrite  = 1'b0;
        immSrc    = IMM_I;
        aluSrc    = 1'b0;
        opASel    = 1'b0;
        memRead   = 1'b0;
        memWrite  = 1'b0;
        resultSrc = 2'b00;
        branch    = 1'b0;
        jump      = 1'b0;
        aluOp     = ALUOP_ADD;
 
        unique case (opcode)
            OP_LOAD: begin
                regWrite  = 1'b1;
                immSrc    = IMM_I;
                aluSrc    = 1'b1;
                memRead   = 1'b1;
                resultSrc = 2'b01;
                aluOp     = ALUOP_ADD;
            end
 
            OP_STORE: begin
                immSrc    = IMM_S;
                aluSrc    = 1'b1;
                memWrite  = 1'b1;
                aluOp     = ALUOP_ADD;
            end
 
            OP_RTYPE: begin
                regWrite  = 1'b1;
                aluOp     = ALUOP_FUNCT;
            end
 
            OP_ITYPE: begin
                regWrite  = 1'b1;
                immSrc    = IMM_I;
                aluSrc    = 1'b1;
                aluOp     = ALUOP_FUNCT;
            end
 
            OP_BRANCH: begin
                immSrc    = IMM_B;
                branch    = 1'b1;
                aluOp     = ALUOP_SUB;
            end
 
            OP_JAL: begin
                regWrite  = 1'b1;
                immSrc    = IMM_J;
                jump      = 1'b1;
                resultSrc = 2'b10;
            end
 
            OP_JALR: begin
                regWrite  = 1'b1;
                immSrc    = IMM_I;
                aluSrc    = 1'b1;
                jump      = 1'b1;
                resultSrc = 2'b10;
                aluOp     = ALUOP_ADD;
            end
 
            OP_LUI: begin
                regWrite  = 1'b1;
                immSrc    = IMM_U;
                aluSrc    = 1'b1;
                resultSrc = 2'b00;
                aluOp     = ALUOP_LUI;
            end
 
            OP_AUIPC: begin
                regWrite  = 1'b1;
                immSrc    = IMM_U;
                aluSrc    = 1'b1;
                opASel    = 1'b1;
                aluOp     = ALUOP_AUIPC;
            end
 
            default: ; // unimplemented opcode -> defaults above stand
        endcase
    end
 
    always_comb begin
        unique case (immSrc)
            IMM_I:   immExt = {{20{instr[31]}}, instr[31:20]};
            IMM_S:   immExt = {{20{instr[31]}}, instr[31:25], instr[11:7]};
            IMM_B:   immExt = {{19{instr[31]}}, instr[31], instr[7], instr[30:25], instr[11:8], 1'b0};
            IMM_U:   immExt = {instr[31:12], 12'b0};
            IMM_J:   immExt = {{11{instr[31]}}, instr[31], instr[19:12], instr[20], instr[30:21], 1'b0};
            default: immExt = 32'b0;
        endcase
    end
 

    // ALU control
    localparam logic [3:0] ALU_ADD   = 4'b0000;
    localparam logic [3:0] ALU_SUB   = 4'b0001;
    localparam logic [3:0] ALU_AND   = 4'b0010;
    localparam logic [3:0] ALU_OR    = 4'b0011;
    localparam logic [3:0] ALU_NOR   = 4'b0100;
    localparam logic [3:0] ALU_XOR   = 4'b0101;
    localparam logic [3:0] ALU_SLL   = 4'b0110;
    localparam logic [3:0] ALU_SRL   = 4'b0111;
    localparam logic [3:0] ALU_SRA   = 4'b1000;
    localparam logic [3:0] ALU_SLT   = 4'b1001;
    localparam logic [3:0] ALU_SLTU  = 4'b1010;
    localparam logic [3:0] ALU_AUIPC = 4'b1011;
    localparam logic [3:0] ALU_LUI   = 4'b1100;
    localparam logic [3:0] ALU_PASSA = 4'b1101;
    localparam logic [3:0] ALU_PASSB = 4'b1110;
    localparam logic [3:0] ALU_ZERO  = 4'b1111;
 
    always_comb begin
        unique case (aluOp)
            ALUOP_ADD:   aluCtrl = ALU_ADD;
            ALUOP_SUB:   aluCtrl = ALU_SUB;
            ALUOP_LUI:   aluCtrl = ALU_LUI;
            ALUOP_AUIPC: aluCtrl = ALU_AUIPC;
            ALUOP_FUNCT: begin // R-type / I-type ALU ops
                unique case (funct3)
                    3'b000:  aluCtrl = (funct7[5] && opcode == OP_RTYPE) ? ALU_SUB : ALU_ADD;
                    3'b001:  aluCtrl = ALU_SLL;
                    3'b010:  aluCtrl = ALU_SLT;
                    3'b011:  aluCtrl = ALU_SLTU;
                    3'b100:  aluCtrl = ALU_XOR;
                    3'b101:  aluCtrl = funct7[5] ? ALU_SRA : ALU_SRL;
                    3'b110:  aluCtrl = ALU_OR;
                    3'b111:  aluCtrl = ALU_AND;
                    default: aluCtrl = ALU_ADD;
                endcase
            end
            default: aluCtrl = ALU_ADD;
        endcase
    end
 
endmodule