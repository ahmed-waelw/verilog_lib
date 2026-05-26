// ----------------------------------------------------------------------------
// Module:      Adder_tb
// Description: Self-checking testbench for the parameterized Adder
//              (instantiated at 32 bits). Tests directed corner cases (carry
//              chain, boundaries, walking-one patterns) and 100K random
//              vectors, each with both cin=0 and cin=1. Compares {cout, s}
//              against a 33-bit reference sum.
// DUT:         Adder.v
// Author:      Amr Said
// Date:        2026-05-26
// ----------------------------------------------------------------------------
`timescale 1ns/1ps

module Adder_tb();
    reg  [31:0] a, b;
    reg         cin;
    wire [31:0] s;
    wire        cout;

    Adder #(.WIDTH(32)) DUT (.a(a), .b(b), .cin(cin), .s(s), .cout(cout));
    
    integer errors = 0;
    integer passed = 0;
    integer checks = 0;
    integer i;

    task check;
        reg [32:0] expected;          // 33 bits: {carry-out, sum}
        begin
            checks = checks + 1;
            expected = a + b + cin;
            if ({cout, s} !== expected) begin
                errors = errors + 1;
                $display("FAIL: a=%h b=%h cin=%b | got cout=%b s=%h | exp cout=%b s=%h",
                         a, b, cin, cout, s, expected[32], expected[31:0]);
            end else begin
                passed = passed + 1;
            end
        end
    endtask

    // apply one (a,b) pair for both values of cin
    task apply;
        input [31:0] av;
        input [31:0] bv;
        begin
            a = av; b = bv;
            cin = 1'b0; #5 check;
            cin = 1'b1; #5 check;
        end
    endtask

    initial begin
        $display("=== Adder testbench ===");

        // ---- directed corner cases (carry propagation & boundaries) ----
        apply(32'h00000000, 32'h00000000);
        apply(32'hFFFFFFFF, 32'h00000001);   // full carry chain -> 0, carry-out=1
        apply(32'hFFFFFFFF, 32'hFFFFFFFF);   // max + max
        apply(32'h7FFFFFFF, 32'h00000001);   // signed-overflow boundary
        apply(32'h80000000, 32'h80000000);
        apply(32'hAAAAAAAA, 32'h55555555);   // alternating bit patterns
        apply(32'h0000FFFF, 32'h00000001);   // carry across the 16-bit boundary
        apply(32'hFFFF0000, 32'h00010000);

        // walking-one: exercises a carry at every bit position
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