module dMem #(
    parameter int DEPTH = 4096 // number of 32-bit words (16 KB)
) (
    input  logic clk,
    input  logic mem_write, // asserted for SB/SH/SW in MEM stage
    input  logic [31:0] addr, // byte address (ALU result: rs1 + imm)
    input  logic [31:0] write_data, // store data (rs2 value)
    input  logic [2:0] funct3, // access width/sign control
    output logic [31:0] read_data // load result (sign/zero-extended)
);

    localparam int WORD_BITS = $clog2(DEPTH);
 
    logic [31:0] mem [0:DEPTH-1];

    // Address decompostion 
    logic [WORD_BITS-1:0] word_addr; //which 32-bit word to access
    logic [1:0] byte_offset; //where inside that word the access starts
 
    assign word_addr   = addr[WORD_BITS+1:2];
    assign byte_offset = addr[1:0];

    // Simulation-only zero initalization
    initial begin
        for (int i = 0; i < DEPTH; i++) mem[i] = 32'h0;
    end


    // Store path
    logic [3:0]  byte_enable;
    logic [31:0] shifted_wdata;
 
    always_comb begin
        shifted_wdata = write_data << (byte_offset * 8);
        case (funct3[1:0])
            2'b00:   byte_enable = 4'b0001 << byte_offset;  // SB
            2'b01:   byte_enable = 4'b0011 << byte_offset;  // SH
            2'b10:   byte_enable = 4'b1111;                 // SW
            default: byte_enable = 4'b0000;
        endcase
    end
 
    always_ff @(posedge clk) begin
        if (mem_write) begin
            if (byte_enable[0]) mem[word_addr][7:0]   <= shifted_wdata[7:0];
            if (byte_enable[1]) mem[word_addr][15:8]  <= shifted_wdata[15:8];
            if (byte_enable[2]) mem[word_addr][23:16] <= shifted_wdata[23:16];
            if (byte_enable[3]) mem[word_addr][31:24] <= shifted_wdata[31:24];
        end
    end

    // Load path
    logic [31:0] raw_word;
    logic [31:0] shifted_rdata;
 
    assign raw_word = mem[word_addr];
    assign shifted_rdata = raw_word >> (byte_offset * 8);
 
    always_comb begin
        case (funct3)
            3'b000:  read_data = {{24{shifted_rdata[7]}},  shifted_rdata[7:0]};  // LB
            3'b001:  read_data = {{16{shifted_rdata[15]}}, shifted_rdata[15:0]}; // LH
            3'b010:  read_data = raw_word;                                       // LW
            3'b100:  read_data = {24'b0, shifted_rdata[7:0]};                    // LBU
            3'b101:  read_data = {16'b0, shifted_rdata[15:0]};                   // LHU
            default: read_data = 32'b0;
        endcase
    end
 
endmodule