`timescale 1ns / 1ps

module hazardUnit (
    input  logic       idResolves,
 
    input  logic [4:0] idRs1Addr,
    input  logic [4:0] idRs2Addr,
 
    input  logic       idExMemRead,
    input  logic       idExRegWrite,
    input  logic [4:0] idExRdAddr,
 
    input  logic       exMemMemRead,
    input  logic [4:0] exMemRdAddr,
 
    output logic       stall
);
 
    logic rule1_loadUseEX;     // (1) universal, producer in EX
    logic rule2_aluAdjacentID; // (2) producer in EX, ID-only extra
    logic rule3_loadTwoAwayID; // (3) producer in EX/MEM (load), ID-only extra
 
    assign rule1_loadUseEX = idExMemRead && (idExRdAddr != 5'b0) &&
                              ((idExRdAddr == idRs1Addr) || (idExRdAddr == idRs2Addr));
 
    assign rule2_aluAdjacentID = idResolves && idExRegWrite && !idExMemRead &&
                                  (idExRdAddr != 5'b0) &&
                                  ((idExRdAddr == idRs1Addr) || (idExRdAddr == idRs2Addr));
 
    assign rule3_loadTwoAwayID = idResolves && exMemMemRead && (exMemRdAddr != 5'b0) &&
                                  ((exMemRdAddr == idRs1Addr) || (exMemRdAddr == idRs2Addr));
 
    assign stall = rule1_loadUseEX || rule2_aluAdjacentID || rule3_loadTwoAwayID;
 
endmodule