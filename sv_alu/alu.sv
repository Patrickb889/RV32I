module alu (
    input logic [31:0] a, // Operadnd a
    input logic [31:0] b, // Operand b
    input logic [3:0] op, // Operation code
    output logic [31:0] result, // Result of the operation
    output logic zero, // Zero flag
    output logic negative, // Negative flag
    output logic overflow, // Overflow flag
    output logic carry // Carry flag
);

    logic [4:0]  shamt;
    logic [32:0] carry_result;

    assign shamt = b[4:0];
    assign carry_result = {1'b0, a} + {1'b0, b};

    always_comb begin
        case (op)
            4'b0000: result = a + b; // ADD
            4'b0001: result = a - b; // SUB
            4'b0010: result = a & b; // AND
            4'b0011: result = a | b; // OR
            4'b0100: result = ~(a | b); // NOR
            4'b0101: result = a ^ b; // XOR
            4'b0110: result = a << shamt; // SLL
            4'b0111: result = a >> shamt; // SRL
            4'b1000: result = $signed(a) >>> shamt; // SRA
            4'b1001: result = ($signed(a) < $signed(b)) ? 32'd1 : 32'd0; // SLT
            4'b1010: result = ($unsigned(a) < $unsigned(b)) ? 32'd1 : 32'd0; // SLTU
            4'b1011: result = a + {b[31:12], 12'b0}; // AUIPC — add upper immediate to PC
            4'b1100: result = {b[31:12], 12'b0}; // LUI
            4'b1101: result = a; // PASSA
            4'b1110: result = b; // PASSB
            4'b1111: result = 32'd0; // ZERO
            default: result = 32'd0; // Default case
        endcase 
    end

    assign zero = (result == 32'd0); // Set zero flag
    assign negative = result[31]; // Set negative flag
    assign overflow = ~(a[31] ^ b[31]) & (a[31] ^ result[31]); // Set overflow flag for addition
    assign carry = carry_result[32]; // Set carry flag
    
endmodule