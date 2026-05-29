// ----------------------------------------------------------------------------
// Module:      DownCounter_tb
// Description: Self-checking testbench for parameterized down counter. Verifies
//              count-down from MAX, wrap-around, and asynchronous reset.
// DUT:         DownCounter
// Author:      Amr Said
// Date:        2026-05-26
// ----------------------------------------------------------------------------
`timescale 1ns/1ps
module DownCounter_tb;

    parameter WIDTH = 4;
    localparam [WIDTH-1:0] MAX = {WIDTH{1'b1}};

    reg clk, reset;
    wire [WIDTH-1:0] Q;

    DownCounter #(.WIDTH(WIDTH)) DUT (.clk(clk), .reset(reset), .Q(Q));
    initial clk = 0;
    always #5 clk = ~clk;  // 10ns clock period

    // reference model (initialized explicitly so the checker never depends on
    // the X->1 reset transition at time 0 to seed it)
    reg [WIDTH-1:0] exp = MAX;          // expected value

    always @(posedge clk or posedge reset) begin
        if (reset) exp <= MAX;
        else       exp <= exp - 1'b1;
    end

    // Checker: compares the DUT output Q against the expected value exp,
    // counts errors, and prints a message on a mismatch.
    integer errors = 0;
    task automatic check;
        begin
            if (Q !== exp) begin
                $display("ERROR: Q=%b, expected=%b, reset=%b", Q, exp, reset);
                errors = errors + 1;
            end
        end
    endtask

    // Check on every clock edge. While reset is held this confirms Q stays at
    // MAX; while counting it confirms Q tracks the reference. The directed
    // block below is what proves the reset is *asynchronous*, so the redundant
    // (and pre-edge-only) posedge-reset checker has been removed.
    always @(posedge clk) #1 check;

    initial begin
        $dumpfile("DownCounter_tb.vcd");
        $dumpvars(0, DownCounter_tb);

        // hold in reset, then release away from a posedge
        reset = 1;
        repeat (2) @(posedge clk);              // Q stays MAX while held
        @(negedge clk) reset = 0;

        // free-run through several full wraps (ends on a non-MAX value for WIDTH=4)
        repeat (50) @(posedge clk);

        // DIRECTED: prove reset is ASYNCHRONOUS, from a non-MAX state
        @(negedge clk);                         // mid-cycle; next posedge is 5 ns away
        reset = 1; #1;                          // NO clock edge occurs in this #1
        if (Q !== MAX) begin
            $display("FAIL: reset not async (Q=%0d with no edge)", Q);
            errors = errors + 1;                // feed directed failure into the tally
        end
        else
            $display("OK: async reset took effect with no clock edge, Q=%0d", Q);
        @(negedge clk) reset = 0;

        repeat (4) @(posedge clk);
        if (errors == 0) $display("PASS: self-check clean");
        else             $display("FAIL: %0d errors", errors);
        $finish;
    end
endmodule