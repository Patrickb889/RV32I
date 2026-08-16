`timescale 1ns / 1ps

module memwbReg (
    input  logic        clk,
    input  logic        reset,
 
    input  logic [31:0] aluResultIn,
    input  logic [31:0] readDataIn,
    input  logic [31:0] pcPlus4In,
    input  logic [4:0]  rdAddrIn,
 
    input  logic        regWriteIn,
    input  logic [1:0]  resultSrcIn,
 
    output logic [31:0] aluResultOut,
    output logic [31:0] readDataOut,
    output logic [31:0] pcPlus4Out,
    output logic [4:0]  rdAddrOut,
 
    output logic        regWriteOut,
    output logic [1:0]  resultSrcOut
);
 
    always_ff @(posedge clk) begin
        if (reset) begin
            aluResultOut <= 32'h0000_0000;
            readDataOut  <= 32'h0000_0000;
            pcPlus4Out   <= 32'h0000_0000;
            rdAddrOut    <= 5'b0;
 
            regWriteOut  <= 1'b0;
            resultSrcOut <= 2'b00;
        end else begin
            aluResultOut <= aluResultIn;
            readDataOut  <= readDataIn;
            pcPlus4Out   <= pcPlus4In;
            rdAddrOut    <= rdAddrIn;
 
            regWriteOut  <= regWriteIn;
            resultSrcOut <= resultSrcIn;
        end
    end
 
endmodule