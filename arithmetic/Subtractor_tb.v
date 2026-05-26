// ----------------------------------------------------------------------------
// Module:      Subtractor_tb
// Description: Self-checking testbench for the parameterized Subtractor
//              (instantiated at 32 bits). Tests directed corner cases
//              (borrow chain, boundaries, walking-one patterns) and 100K
//              random vectors, each with both b_in=0 and b_in=1. Compares
//              {b_out, D} against a 33-bit reference difference.
// DUT:         Subtractor.v
// Author:      Amr Said
// Date:        2026-05-26
// ----------------------------------------------------------------------------
`timescale 1ns/1ps

module Subtractor_tb();
    reg  [31:0] a, b;
    reg         b_in;
    wire [31:0] d;
    wire        b_out;

    Subtractor #(.WIDTH(32)) DUT (.A(a), .B(b), .b_in(b_in), .D(d), .b_out(b_out));

    integer errors = 0;
    integer passed = 0;
    integer checks = 0;
    integer i;

    task check;
        reg [32:0] expected;          // 33 bits: {borrow-out, difference}
        begin
            checks = checks + 1;
            expected = a - b - b_in;
            if ({b_out, d} !== expected) begin
                errors = errors + 1;
                $display("FAIL: a=%h b=%h b_in=%b | got b_out=%b d=%h | exp b_out=%b d=%h",
                         a, b, b_in, b_out, d, expected[32], expected[31:0]);
            end else begin
                passed = passed + 1;
            end
        end
    endtask

    // apply one (a,b) pair for both values of b_in
    task apply;
        input [31:0] av;
        input [31:0] bv;
        begin
            a = av; b = bv;
            b_in = 1'b0; #5 check;
            b_in = 1'b1; #5 check;
        end
    endtask

    initial begin
        $display("=== Subtractor testbench ===");

        // ---- directed corner cases (borrow propagation & boundaries) ----
        apply(32'h00000000, 32'h00000000);
        apply(32'hFFFFFFFF, 32'h00000001);   // borrow chain stress
        apply(32'hFFFFFFFF, 32'hFFFFFFFF);   // max - max
        apply(32'h7FFFFFFF, 32'h00000001);   // signed-overflow boundary
        apply(32'h80000000, 32'h80000000);
        apply(32'hAAAAAAAA, 32'h55555555);   // alternating bit patterns
        apply(32'h0000FFFF, 32'h00000001);   // borrow across the 16-bit boundary
        apply(32'hFFFF0000, 32'h00010000);

        // walking-one: exercises a borrow at every bit position
        for (i = 0; i < 32; i = i + 1)
            apply(32'h1 << i, 32'h1 << i);

        // ---- randomized wide vectors for breadth ----
        for (i = 0; i < 100000; i = i + 1)
            apply($random, $random);

        $display("=== done: %0d checks, %0d passed, %0d errors ===", checks, passed, errors);
        if (errors == 0) $display(">>> ALL TESTS PASSED <<<");
        else             $display(">>> %0d FAILURE(S) <<<", errors);
        $finish;
    end
endmodule
