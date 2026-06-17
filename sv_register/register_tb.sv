`timescale 1ns/1ps
 
module register_tb;
 
    // DUT signals
    logic clk;
    logic we;
    logic [4:0] rd_addr;
    logic [31:0] rd_data;
    logic [4:0] rs1_addr;
    logic [31:0] rs1_data;
    logic [4:0] rs2_addr;
    logic [31:0] rs2_data;
 
    // Instantiate the device under test
    register dut (
        .clk(clk),
        .we(we),
        .rd_addr(rd_addr),
        .rd_data(rd_data),
        .rs1_addr(rs1_addr),
        .rs1_data(rs1_data),
        .rs2_addr(rs2_addr),
        .rs2_data(rs2_data)
    );
 
    // Clock generation: 10ns period (toggle every 5ns)
    initial clk = 0;
    always #5 clk = ~clk;
 
    initial begin
        $display("Register File Testbench");
        $display("");

        // Start with everything empty
        we = 0;
        rd_addr = 5'd0;
        rd_data = 32'd0;
        rs1_addr = 5'd0;
        rs2_addr = 5'd0;

        @(negedge clk); // Wait for the first negative edge of the clock

        //Test 1: Basic write-then-read
        $display("Test 1: Basic write-then-read (x5)");
        we = 1;
        rd_addr = 5'd5;
        rd_data = 32'hDEADBEEF;
        @(negedge clk); // wait for the posedge in between to commit the write
        we = 0;
 
        rs1_addr = 5'd5;
        #1; // small delay so combinational read settles before we print
        $display("Wrote 0x%h to x5. Read back rs1_data = 0x%h", 32'hDEADBEEF, rs1_data);
        $display("Expected: 0xdeadbeef");
        $display("");



        $finish;
    end
 
endmodule