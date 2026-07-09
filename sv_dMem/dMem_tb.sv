`timescale 1ns/1ps
 
module dmem_tb;
 
    localparam int DEPTH      = 16;
    localparam int CLK_PERIOD = 10;
 
    logic        clk;
    logic        mem_write;
    logic [31:0] addr;
    logic [31:0] write_data;
    logic [2:0]  funct3;
    logic [31:0] read_data;

    int pass_count = 0;
    int fail_count = 0;
 
    logic [31:0] rand_addr;
    logic [31:0] rand_data;
 
    dmem #(.DEPTH(DEPTH)) dut (
        .clk        (clk),
        .mem_write  (mem_write),
        .addr       (addr),
        .write_data (write_data),
        .funct3     (funct3),
        .read_data  (read_data)
    );

    //Clock setup
    initial clk = 0;
    always #(CLK_PERIOD/2) clk = ~clk;
 
    // funct3 encodings, named for readability in the test sequence
    localparam logic [2:0] F3_B  = 3'b000;  // SB / LB
    localparam logic [2:0] F3_H  = 3'b001;  // SH / LH
    localparam logic [2:0] F3_W  = 3'b010;  // SW / LW
    localparam logic [2:0] F3_BU = 3'b100;  // LBU
    localparam logic [2:0] F3_HU = 3'b101;  // LHU

    // Checker function
    task automatic check(string name, logic [31:0] got, logic [31:0] exp);
        if (got === exp) begin
            pass_count++;
            $display("  PASS %-32s got=%08h", name, got);
        end else begin
            fail_count++;
            $display("  FAIL %-32s got=%08h exp=%08h", name, got, exp);
        end
    endtask

    // Store function
    task automatic do_store(input logic [31:0] a, input logic [31:0] d, input logic [2:0] f3);
        addr = a; write_data = d; funct3 = f3; mem_write = 1;
        @(posedge clk);
        #1;
        mem_write = 0;
    endtask

    // Load function
    task automatic do_load(input logic [31:0] a, input logic [2:0] f3);
        addr = a; funct3 = f3;
        #1;
    endtask

    initial begin
        $dumpfile("dmem_tb.vcd");
        $dumpvars(0, dmem_tb);
 
        mem_write = 0; addr = 0; write_data = 0; funct3 = 0;
        @(posedge clk); #1;









        //-----------------------------------------------------------
        $display("\n=================================================");
        $display(" Results: %0d passed, %0d failed (%0d total)",
                  pass_count, fail_count, pass_count + fail_count);
        $display("=================================================\n");
 
        $finish;
    end
 
endmodule