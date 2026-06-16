module register (
    input logic clk,

    // Write port
    input logic we, //Write enable, active high
    input logic [4:0] rd_addr, // Destination register address (0–31)
    input logic [31:0] rd_data, // Data to write

    // Read port 1 (rs1)
    input logic [4:0] rs1_addr, // Register 1 address
    output logic [31:0] rs1_data, // Register 1 data
 
    // Read port 2 (rs2)
    input logic [4:0] rs2_addr, // Register 2 address
    output logic [31:0] rs2_data // Register 2 data
);

    // Register file: 32 registers of 32 bits each
    logic [31:0] reg_file [31:0];

    // Synchronous write operation
    always_ff @(posedge clk) begin
        if (we && rd_addr != 5'b0) begin
            reg_file[rd_addr] <= rd_data; // Write data to the register file
        end
    end

    // Combinational read operation
    assign rs1_data = (rs1_addr == 5'b0) ? 32'b0 : reg_file[rs1_addr]; // Read from rs1, zero if x0
    assign rs2_data = (rs2_addr == 5'b0) ? 32'b0 : reg_file[rs2_addr]; // Read from rs2, zero if x0

endmodule