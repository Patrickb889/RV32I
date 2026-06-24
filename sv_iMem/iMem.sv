module iMem #(
    parameter int DEPTH = 1024, // memory depth in 32-bit WORDS (not bytes)
    parameter string MEM_FILE = "" // path to hex file for $readmemh preload; "" = skip preload
) (
    input  logic [31:0] addr, // byte address
    output logic [31:0] instr // instruction word at addr
);

    // storage array
    logic [31:0] mem [0:DEPTH-1];

    // Byte address -> word index
    wire [31:0] word_index = addr[31:2];

    // Combinational read
    assign instr = mem[word_index];

    // NOP-fill convention
    localparam logic [31:0] NOP = 32'h00000013;
 
    integer i;
    initial begin
        for (i = 0; i < DEPTH; i++) begin
            mem[i] = NOP;
        end

    // Hex file load
    if (MEM_FILE != "") begin
            $readmemh(MEM_FILE, mem);
        end
    end

    // synthesis translate_off
    // "00" ending check
    always_comb begin
        if (addr[1:0] != 2'b00) begin
            $error("iMem: misaligned fetch address 0x%08h (addr[1:0] = %02b)",
                   addr, addr[1:0]);
        end

    // in range check
    if (word_index >= DEPTH) begin
            $error("iMem: address 0x%08h (word index %0d) out of range, DEPTH = %0d",
                   addr, word_index, DEPTH);
        end
    end
    // synthesis translate_on


endmodule