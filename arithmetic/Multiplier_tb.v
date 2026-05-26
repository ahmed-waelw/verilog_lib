// ----------------------------------------------------------------------------
// Module:      Multiplier_tb
// Description: Self-checking testbench for the parameterized Multiplier
//              (instantiated at 32 bits). Tests directed corner cases (zero,
//              identity, max x max, powers of two, alternating patterns) and
//              100K random vectors. Compares 64-bit product against
//              behavioral a*b reference.
// DUT:         Multiplier.v
// Author:      Amr Said
// Date:        2026-05-26
// ----------------------------------------------------------------------------
`timescale 1ns/1ps

module Multiplier_tb();
    reg  [31:0] a, b;
    wire [63:0] p;

    Multiplier #(.WIDTH(32)) DUT (.A(a), .B(b), .P(p));

    integer errors = 0;
    integer passed = 0;
    integer checks = 0;
    integer i;

    task check;
        reg [63:0] expected;          // 64-bit: full 32x32 product
        begin
            checks = checks + 1;
            expected = a * b;
            if (p !== expected) begin
                errors = errors + 1;
                $display("FAIL: a=%h b=%h | got p=%h | exp p=%h", a, b, p, expected);
            end else begin
                passed = passed + 1;
            end
        end
    endtask

    task apply;
        input [31:0] av;
        input [31:0] bv;
        begin
            a = av; b = bv; #5 check;
        end
    endtask

    initial begin
        $display("=== Multiplier testbench ===");

        // ---- directed corner cases ----
        apply(32'h00000000, 32'h00000000);   // 0 * 0
        apply(32'h00000000, 32'hFFFFFFFF);   // 0 * max = 0
        apply(32'h00000001, 32'hFFFFFFFF);   // 1 * x = x
        apply(32'hFFFFFFFF, 32'h00000001);   // x * 1
        apply(32'hFFFFFFFF, 32'hFFFFFFFF);   // max * max (largest product)
        apply(32'h80000000, 32'h00000002);   // MSB * 2
        apply(32'h0000FFFF, 32'h0000FFFF);   // 16-bit * 16-bit
        apply(32'hAAAAAAAA, 32'h55555555);   // alternating patterns
        apply(32'h00010000, 32'h00010000);   // 2^16 * 2^16 = 2^32

        // powers of two: exercises the high-order product bits
        for (i = 0; i < 32; i = i + 1)
            apply(32'h1 << i, 32'h1 << i);

        // ---- randomized wide vectors ----
        for (i = 0; i < 100000; i = i + 1)
            apply($random, $random);

        $display("=== done: %0d checks, %0d passed, %0d errors ===", checks, passed, errors);
        
        if (errors == 0) 
        
        $display(">>> ALL TESTS PASSED <<<");
        
        else             
        
        $display(">>> %0d FAILURE(S) <<<", errors);
        $finish;
    end
endmodule