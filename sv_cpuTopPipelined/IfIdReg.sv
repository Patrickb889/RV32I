`timescale 1ns / 1ps

module ifidReg (
    input  logic        clk,
    input  logic        reset,
    input  logic        stall,
    input  logic        flush,
 
    input  logic [31:0] pcIn,
    input  logic [31:0] pcPlus4In,
    input  logic [31:0] instrIn,
 
    output logic [31:0] pcOut,
    output logic [31:0] pcPlus4Out,
    output logic [31:0] instrOut
);
 
    localparam logic [31:0] NOP = 32'h0000_0013; // addi x0, x0, 0
 
    always_ff @(posedge clk) begin
        if (reset) begin
            pcOut      <= 32'h0000_0000;
            pcPlus4Out <= 32'h0000_0000;
            instrOut   <= NOP;
        end else if (stall) begin
            // hold: intentionally do nothing
        end else if (flush) begin
            pcOut      <= 32'h0000_0000;
            pcPlus4Out <= 32'h0000_0000;
            instrOut   <= NOP;
        end else begin
            pcOut      <= pcIn;
            pcPlus4Out <= pcPlus4In;
            instrOut   <= instrIn;
        end
    end
 
endmodule