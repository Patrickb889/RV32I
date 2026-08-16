`timescale 1ns / 1ps

module forwardUnit (
    // EX-stage forwarding destination (instruction currently in EX)
    input  logic [4:0] idExRs1Addr,
    input  logic [4:0] idExRs2Addr,
 
    // ID-stage forwarding destination (instruction currently in ID)
    input  logic [4:0] idRs1Addr,
    input  logic [4:0] idRs2Addr,
 
    // EX/MEM producer info (shared by both forwarding sets)
    input  logic        exMemRegWrite,
    input  logic        exMemMemRead,
    input  logic [4:0]  exMemRdAddr,
 
    // MEM/WB producer info (shared by both forwarding sets)
    input  logic        memWbRegWrite,
    input  logic [4:0]  memWbRdAddr,
 
    output logic [1:0] forwardAE,
    output logic [1:0] forwardBE,
    output logic [1:0] forwardAD,
    output logic [1:0] forwardBD
);
 
    // ---------------- EX-stage forwarding ----------------
    always_comb begin
        if (exMemRegWrite && (exMemRdAddr != 5'b0) && (exMemRdAddr == idExRs1Addr))
            forwardAE = 2'b10;
        else if (memWbRegWrite && (memWbRdAddr != 5'b0) && (memWbRdAddr == idExRs1Addr))
            forwardAE = 2'b01;
        else
            forwardAE = 2'b00;
    end
 
    always_comb begin
        if (exMemRegWrite && (exMemRdAddr != 5'b0) && (exMemRdAddr == idExRs2Addr))
            forwardBE = 2'b10;
        else if (memWbRegWrite && (memWbRdAddr != 5'b0) && (memWbRdAddr == idExRs2Addr))
            forwardBE = 2'b01;
        else
            forwardBE = 2'b00;
    end
 
    // ---------------- ID-stage forwarding ----------------
    always_comb begin
        if (exMemRegWrite && !exMemMemRead && (exMemRdAddr != 5'b0) && (exMemRdAddr == idRs1Addr))
            forwardAD = 2'b01;
        else if (memWbRegWrite && (memWbRdAddr != 5'b0) && (memWbRdAddr == idRs1Addr))
            forwardAD = 2'b10;
        else
            forwardAD = 2'b00;
    end
 
    always_comb begin
        if (exMemRegWrite && !exMemMemRead && (exMemRdAddr != 5'b0) && (exMemRdAddr == idRs2Addr))
            forwardBD = 2'b01;
        else if (memWbRegWrite && (memWbRdAddr != 5'b0) && (memWbRdAddr == idRs2Addr))
            forwardBD = 2'b10;
        else
            forwardBD = 2'b00;
    end
 
endmodule