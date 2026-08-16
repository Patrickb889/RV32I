`timescale 1ns / 1ps

module idexReg (
    input  logic        clk,
    input  logic        reset,
    input  logic        flush,
 
    // data
    input  logic [31:0] pcIn,
    input  logic [31:0] pcPlus4In,
    input  logic [31:0] rs1DataIn,
    input  logic [31:0] rs2DataIn,
    input  logic [4:0]  rs1AddrIn,
    input  logic [4:0]  rs2AddrIn,
    input  logic [4:0]  rdAddrIn,
    input  logic [31:0] immExtIn,
    input  logic [2:0]  funct3In,
 
    // control
    input  logic        regWriteIn,
    input  logic        aluSrcIn,
    input  logic        opASelIn,
    input  logic        memReadIn,
    input  logic        memWriteIn,
    input  logic [1:0]  resultSrcIn,
    input  logic [3:0]  aluCtrlIn,
 
    // data out
    output logic [31:0] pcOut,
    output logic [31:0] pcPlus4Out,
    output logic [31:0] rs1DataOut,
    output logic [31:0] rs2DataOut,
    output logic [4:0]  rs1AddrOut,
    output logic [4:0]  rs2AddrOut,
    output logic [4:0]  rdAddrOut,
    output logic [31:0] immExtOut,
    output logic [2:0]  funct3Out,
 
    // control out
    output logic        regWriteOut,
    output logic        aluSrcOut,
    output logic        opASelOut,
    output logic        memReadOut,
    output logic        memWriteOut,
    output logic [1:0]  resultSrcOut,
    output logic [3:0]  aluCtrlOut
);
 
    always_ff @(posedge clk) begin
        if (reset || flush) begin
            pcOut        <= 32'h0000_0000;
            pcPlus4Out   <= 32'h0000_0000;
            rs1DataOut   <= 32'h0000_0000;
            rs2DataOut   <= 32'h0000_0000;
            rs1AddrOut   <= 5'b0;
            rs2AddrOut   <= 5'b0;
            rdAddrOut    <= 5'b0;
            immExtOut    <= 32'h0000_0000;
            funct3Out    <= 3'b0;
 
            regWriteOut  <= 1'b0;
            aluSrcOut    <= 1'b0;
            opASelOut    <= 1'b0;
            memReadOut   <= 1'b0;
            memWriteOut  <= 1'b0;
            resultSrcOut <= 2'b00;
            aluCtrlOut   <= 4'b0;
        end else begin
            pcOut        <= pcIn;
            pcPlus4Out   <= pcPlus4In;
            rs1DataOut   <= rs1DataIn;
            rs2DataOut   <= rs2DataIn;
            rs1AddrOut   <= rs1AddrIn;
            rs2AddrOut   <= rs2AddrIn;
            rdAddrOut    <= rdAddrIn;
            immExtOut    <= immExtIn;
            funct3Out    <= funct3In;
 
            regWriteOut  <= regWriteIn;
            aluSrcOut    <= aluSrcIn;
            opASelOut    <= opASelIn;
            memReadOut   <= memReadIn;
            memWriteOut  <= memWriteIn;
            resultSrcOut <= resultSrcIn;
            aluCtrlOut   <= aluCtrlIn;
        end
    end
 
endmodule