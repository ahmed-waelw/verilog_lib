// ----------------------------------------------------------------------------
// Module:      UpCounter_tb
// Description: Self-checking testbench for parameterized up counter. Verifies
//              free-running count, wrap-around, and asynchronous reset.
// DUT:         UpCounter
// Author:      Amr Said
// Date:        2026-05-26
// ----------------------------------------------------------------------------
`timescale 1ns/1ps
module UpCounter_tb();
    parameter WIDTH = 4;
    localparam [WIDTH-1:0] MAX = {WIDTH{1'b1}};

    reg clk, reset;
    wire [WIDTH-1:0] Q;

    UpCounter #(.WIDTH(WIDTH)) DUT (.clk(clk), .reset(reset), .Q(Q));
    initial clk = 0;
    always #5 clk = ~clk;

    // reference model
    reg [WIDTH-1:0] exp = 0;
    always @(posedge clk or posedge reset) begin
        if (reset) exp <= 0;
        else       exp <= exp + 1'b1;
    end

    // checker
    integer errors = 0;
    task automatic check;
        begin
            if (Q !== exp) begin
                $display("ERROR: Q=%b, expected=%b, reset=%b", Q, exp, reset);
                errors = errors + 1;
            end
        end
    endtask
    always @(posedge clk) #1 check;

    initial begin
        $dumpfile("UpCounter_tb.vcd");
        $dumpvars(0, UpCounter_tb);

        // hold in reset, then release away from a posedge
        reset = 1;
        repeat (2) @(posedge clk);
        @(negedge clk) reset = 0;

        // free-run through several full wraps
        repeat (50) @(posedge clk);

        // directed: prove reset is ASYNCHRONOUS, from a non-zero state
        @(negedge clk);
        reset = 1; #1;
        if (Q !== 0) begin
            $display("FAIL: reset not async (Q=%0d with no edge)", Q);
            errors = errors + 1;
        end
        else
            $display("OK: async reset took effect with no clock edge, Q=%0d", Q);

        // release reset and verify normal count-up resumes
        @(negedge clk) reset = 0;
        repeat (4) @(posedge clk);

        if (errors == 0) $display("PASS: self-check clean");
        else             $display("FAIL: %0d errors", errors);
        $finish;
    end

endmodule