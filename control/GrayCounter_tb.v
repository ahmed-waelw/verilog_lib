// ----------------------------------------------------------------------------
// Module:      GrayCounter_tb
// Description: Self-checking testbench for Gray-code counter. Verifies value
//              match to reflected-binary reference, Hamming-1 property, state
//              uniqueness, cycle length, and asynchronous reset.
// DUT:         GrayCounter
// Author:      Amr Said
// Date:        2026-05-26
// ----------------------------------------------------------------------------
`timescale 1ns/1ps

module GrayCounter_tb();
    parameter  WIDTH = 4;
    localparam DEPTH = (1 << WIDTH);

    reg              clk, reset;
    wire [WIDTH-1:0] Q;
    integer          errors = 0;

    GrayCounter #(.WIDTH(WIDTH)) DUT (.clk(clk), .reset(reset), .Q(Q));

    initial clk = 0;
    always #5 clk = ~clk;

    // ---- Behavioural reference: standard reflected-binary Gray code ----
    reg  [WIDTH-1:0] bin;
    wire [WIDTH-1:0] exp = bin ^ (bin >> 1);
    always @(posedge clk or posedge reset) begin
        if (reset) bin <= 0;
        else       bin <= bin + 1'b1;
    end

    // ---- Property-check state ----
    reg [WIDTH-1:0] Q_prev;
    reg             have_prev = 1'b0;
    integer         seen_count [0:DEPTH-1];
    integer         i;
    initial for (i = 0; i < DEPTH; i = i + 1) seen_count[i] = 0;

    // ---- Checkers ----
    // (1) Value match: ties DUT to the specific reflected-Gray encoding.
    task automatic check_value_match;
        begin
            if (Q !== exp) begin
                $display("ERROR (value) @%0t: Q=%b exp=%b bin=%b",
                         $time, Q, exp, bin);
                errors = errors + 1;
            end
        end
    endtask

    // (2) Hamming-1 property: consecutive non-reset values differ in 1 bit.
    task automatic check_hamming_1;
        reg [WIDTH-1:0] d;
        begin
            d = Q ^ Q_prev;
            if (have_prev && !reset && (d == 0 || (d & (d - 1)) != 0)) begin
                $display("ERROR (Hamming) @%0t: Q=%b Q_prev=%b diff=%b",
                         $time, Q, Q_prev, d);
                errors = errors + 1;
            end
        end
    endtask

    always @(posedge clk) #1 begin
        check_value_match;
        check_hamming_1;
        if (!reset) seen_count[Q] = seen_count[Q] + 1;
        Q_prev    = Q;
        have_prev = 1'b1;
    end

    initial begin
        $dumpfile("GrayCounter_tb.vcd");
        $dumpvars(0, GrayCounter_tb);

        // ---- reset + walk exactly one full cycle for uniqueness ----
        reset = 1;
        repeat (2) @(posedge clk);
        @(negedge clk) reset = 0;
        have_prev = 1'b0;                       // fresh Hamming baseline
        repeat (DEPTH) @(posedge clk);
        #1;

        // (3) Uniqueness: every code 0..DEPTH-1 appeared exactly once
        for (i = 0; i < DEPTH; i = i + 1) begin
            if (seen_count[i] != 1) begin
                $display("ERROR (uniqueness): code %0d seen %0d times",
                         i, seen_count[i]);
                errors = errors + 1;
            end
        end

        // (4) Cycle length: Q must be back at 0 after exactly DEPTH cycles
        if (Q !== {WIDTH{1'b0}}) begin
            $display("FAIL: cycle length != %0d (Q=%b)", DEPTH, Q);
            errors = errors + 1;
        end
        else
            $display("OK: cycle length = %0d, Q returned to 0", DEPTH);

        // ---- second cycle for extra Hamming + value coverage ----
        repeat (DEPTH) @(posedge clk);

        // ---- async reset from non-zero state ----
        wait (Q != 0);
        @(negedge clk);
        reset = 1; #1;
        if (Q !== {WIDTH{1'b0}}) begin
            $display("FAIL: async reset did not clear (Q=%b)", Q);
            errors = errors + 1;
        end
        else
            $display("OK: async reset confirmed, Q=%b", Q);

        @(negedge clk) reset = 0;
        repeat (4) @(posedge clk);

        if (errors == 0) $display("PASS: self-check clean");
        else             $display("FAIL: %0d errors", errors);
        $finish;
    end

endmodule