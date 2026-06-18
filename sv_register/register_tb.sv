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

        // Test 2: x0 always reads zero, even if a write to it is attempted
        $display("Test 2: x0 hardwired to zero");
        we = 1;
        rd_addr = 5'd0;
        rd_data = 32'hFFFFFFFF; // try to corrupt x0
        @(negedge clk);
        we = 0;
 
        rs1_addr = 5'd0;
        #1;
        $display("Attempted write of 0x%h to x0. Read back rs1_data = 0x%h", 32'hFFFFFFFF, rs1_data);
        $display("Expected: 0x00000000");

        // Test 3: Write does not forward to a same-cycle read
        $display("\nTest 3: No write-to-read forwarding within the same cycle");
        rs1_addr = 5'd5; // point read port at the register we're about to overwrite
        #1;
        $display("Before write: rs1_data (x5) = 0x%h", rs1_data);
 
        we = 1;
        rd_addr = 5'd5;
        rd_data = 32'h12345678; // new value, not yet written
        #1; // sample combinational read WHILE we/rd_data are asserted, but BEFORE the clock edge
        $display("During write (pre-edge): rs1_data (x5) = 0x%h", rs1_data);
 
        @(negedge clk); // now the posedge has passed, write is committed
        we = 0;
        #1;
        $display("After write (post-edge): rs1_data (x5) = 0x%h", rs1_data);
        $display("Expected: 0x12345678");

        // Test 4: Dual-port simultaneous read from two different registers
        $display("\nTest 4: Simultaneous dual-port read");
        we = 1;
        rd_addr = 5'd10;
        rd_data = 32'hAAAA0000;
        @(negedge clk);
        rd_addr = 5'd20;
        rd_data = 32'h0000BBBB;
        @(negedge clk);
        we = 0;
 
        rs1_addr = 5'd10;
        rs2_addr = 5'd20;
        #1;
        $display("rs1_data (x10) = 0x%h, rs2_data (x20) = 0x%h", rs1_data, rs2_data);
        $display("Expected: rs1_data = 0xaaaa0000, rs2_data = 0x0000bbbb");

        // Test 5: Writing to one register does not disturb others
        $display("\nTest 5: Write isolation");
        we = 1;
        rd_addr = 5'd10;
        rd_data = 32'hCAFECAFE;
        @(negedge clk);
        we = 0;
 
        rs1_addr = 5'd10;
        rs2_addr = 5'd20;
        #1;
        $display("rs1_data (x10) = 0x%h (expected 0xcafecafe)", rs1_data);
        $display("rs2_data (x20) = 0x%h (expected 0x0000bbbb)", rs2_data);
 


        $display("");
        $display("Testbench complete.");

        $finish;
    end
 
endmodule