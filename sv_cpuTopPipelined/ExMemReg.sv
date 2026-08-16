`timescale 1ns / 1ps

module exmemReg (
    input  logic        clk,
    input  logic        reset,
 
    input  logic [31:0] aluResultIn,
    input  logic [31:0] writeDataIn,   // forwarded rs2 data, for stores
    input  logic [4:0]  rdAddrIn,
    input  logic [2:0]  funct3In,
    input  logic [31:0] pcPlus4In,
 
    input  logic        regWriteIn,
    input  logic        memReadIn,
    input  logic        memWriteIn,
    input  logic [1:0]  resultSrcIn,
 
    output logic [31:0] aluResultOut,
    output logic [31:0] writeDataOut,
    output logic [4:0]  rdAddrOut,
    output logic [2:0]  funct3Out,
    output logic [31:0] pcPlus4Out,
 
    output logic        regWriteOut,
    output logic        memReadOut,
    output logic        memWriteOut,
    output logic [1:0]  resultSrcOut
);
 
    always_ff @(posedge clk) begin
        if (reset) begin
            aluResultOut <= 32'h0000_0000;
            writeDataOut <= 32'h0000_0000;
            rdAddrOut    <= 5'b0;
            funct3Out    <= 3'b0;
            pcPlus4Out   <= 32'h0000_0000;
 
            regWriteOut  <= 1'b0;
            memReadOut   <= 1'b0;
            memWriteOut  <= 1'b0;
            resultSrcOut <= 2'b00;
        end else begin
            aluResultOut <= aluResultIn;
            writeDataOut <= writeDataIn;
            rdAddrOut    <= rdAddrIn;
            funct3Out    <= funct3In;
            pcPlus4Out   <= pcPlus4In;
 
            regWriteOut  <= regWriteIn;
            memReadOut   <= memReadIn;
            memWriteOut  <= memWriteIn;
            resultSrcOut <= resultSrcIn;
        end
    end
 
endmodule