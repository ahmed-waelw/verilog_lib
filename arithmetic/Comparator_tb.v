// ----------------------------------------------------------------------------
// Module:      Comparator_tb
// Description: Self-checking testbench for the parameterized Comparator
//              (instantiated at 32 bits). Tests directed corner cases (equal,
//              less-than, greater-than at boundaries), forced-equality pairs,
//              near-boundary +/-1 stress, and 100K random vector pairs.
//              Verifies all three outputs (eq, lt, gt) against behavioral
//              reference.
// DUT:         Comparator.v
// Author:      Amr Said
// Date:        2026-05-26
// ----------------------------------------------------------------------------
`timescale 1ns/1ps

module Comparator_tb();
    reg  [31:0] a, b;
    wire        eq, lt, gt;

    Comparator #(.WIDTH(32)) DUT (
        .A(a),
        .B(b),
        .eq(eq),
        .lt(lt),
        .gt(gt)
    );

    integer errors = 0;
    integer passed = 0;
    integer checks = 0;
    integer i;
    reg [31:0] ra;

    task check;
        reg expected_eq, expected_lt, expected_gt;
        begin
            checks = checks + 1;
            expected_eq = (a == b);
            expected_lt = (a <  b);
            expected_gt = (a >  b);
            if (eq !== expected_eq || lt !== expected_lt || gt !== expected_gt) begin
                errors = errors + 1;
                $display("FAIL: a=%h b=%h | got eq=%b lt=%b gt=%b | exp eq=%b lt=%b gt=%b",
                         a, b, eq, lt, gt, expected_eq, expected_lt, expected_gt);
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
        $display("=== Comparator testbench ===");

        // ---- directed corner cases ----
        apply(32'h00000000, 32'h00000000);   // equal (zero)
        apply(32'hFFFFFFFF, 32'hFFFFFFFF);   // equal (max)
        apply(32'h00000000, 32'h00000001);   // a < b
        apply(32'h00000001, 32'h00000000);   // a > b
        apply(32'h00000000, 32'hFFFFFFFF);   // min vs max -> a < b
        apply(32'hFFFFFFFF, 32'h00000000);   // max vs min -> a > b
        apply(32'h7FFFFFFF, 32'h80000000);   // unsigned: a < b  (signed would differ!)
        apply(32'h80000000, 32'h7FFFFFFF);   // unsigned: a > b

        // ---- equality coverage: random a == b (forces eq=1) ----
        for (i = 0; i < 1000; i = i + 1) begin
            ra = $random;
            apply(ra, ra);
        end

        // ---- near-boundary: differ by exactly 1 (stresses eq/lt/gt edge) ----
        for (i = 0; i < 1000; i = i + 1) begin
            ra = $random;
            if (ra != 32'hFFFFFFFF) apply(ra, ra + 1);   // a < b
            if (ra != 32'h00000000) apply(ra, ra - 1);   // a > b
        end

        // ---- broad randomized vectors ----
        for (i = 0; i < 100000; i = i + 1)
            apply($random, $random);

        $display("=== done: %0d checks, %0d passed, %0d errors ===", checks, passed, errors);
        if (errors == 0) $display(">>> ALL TESTS PASSED <<<");
        else             $display(">>> %0d FAILURE(S) <<<", errors);
        $finish;
    end
endmodule