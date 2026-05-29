// ----------------------------------------------------------------------------
// Module:      ModNCounter_tb
// Description: Self-checking testbench for modulo-N counter. Tests three
//              concurrent MOD values (10, 6, 13) against independent reference
//              models, verifies Q < MOD invariant and asynchronous reset.
// DUT:         ModNCounter
// Author:      Amr Said
// Date:        2026-05-26
// ----------------------------------------------------------------------------
`timescale 1ns/1ps

module ModNCounter_tb();
    parameter WIDTH = 4;

    // Three MODs covering the interesting space:
    //   M1 = 10  : BCD, the conventional case
    //   M2 = 6   : small non-power-of-two
    //   M3 = 13  : prime, won't divide any 2^k boundary
    localparam M1 = 10, M2 = 6, M3 = 13;

    reg              clk, reset;
    wire [WIDTH-1:0] Q1, Q2, Q3;
    integer          errors = 0;

    ModNCounter #(.MOD(M1), .WIDTH(WIDTH)) DUT_M10 (.clk(clk), .reset(reset), .Q(Q1));
    ModNCounter #(.MOD(M2), .WIDTH(WIDTH)) DUT_M6  (.clk(clk), .reset(reset), .Q(Q2));
    ModNCounter #(.MOD(M3), .WIDTH(WIDTH)) DUT_M13 (.clk(clk), .reset(reset), .Q(Q3));

    initial clk = 0;
    always #5 clk = ~clk;

    // ---- Three reference models, each with explicit MOD wrap ----
    reg [WIDTH-1:0] exp1, exp2, exp3;
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            exp1 <= 0; exp2 <= 0; exp3 <= 0;
        end
        else begin
            exp1 <= (exp1 == M1-1) ? {WIDTH{1'b0}} : exp1 + 1'b1;
            exp2 <= (exp2 == M2-1) ? {WIDTH{1'b0}} : exp2 + 1'b1;
            exp3 <= (exp3 == M3-1) ? {WIDTH{1'b0}} : exp3 + 1'b1;
        end
    end

    // ---- Checker: match the model AND invariant Q < MOD ----
    task automatic check_one;
        input [127:0]     name;       // string passed as reg vector
        input [WIDTH-1:0] q;
        input [WIDTH-1:0] e;
        input integer     mod_val;
        begin
            if (q !== e) begin
                $display("ERROR (%0s match) @%0t: Q=%0d exp=%0d",
                         name, $time, q, e);
                errors = errors + 1;
            end
            if (q >= mod_val) begin
                $display("ERROR (%0s invariant) @%0t: Q=%0d >= MOD=%0d",
                         name, $time, q, mod_val);
                errors = errors + 1;
            end
        end
    endtask

    always @(posedge clk) #1 begin
        check_one("MOD=10", Q1, exp1, M1);
        check_one("MOD=6",  Q2, exp2, M2);
        check_one("MOD=13", Q3, exp3, M3);
    end

    initial begin
        $dumpfile("ModNCounter_tb.vcd");
        $dumpvars(0, ModNCounter_tb);

        // ---- Test 1+2: reset, then run > 3 full cycles of the largest MOD ----
        // 3 * 13 = 39 posedges covers 3+ cycles of M=10 and 6+ of M=6 too,
        // and the invariant check fires every cycle.
        reset = 1;
        repeat (2) @(posedge clk);
        @(negedge clk) reset = 0;
        repeat (3 * M3) @(posedge clk);

        // ---- Test 3: async reset from mid-count ----
        wait (Q3 == 5);                       // a clearly non-zero state in all three
        @(negedge clk);
        reset = 1; #1;
        if (Q1 !== 0 || Q2 !== 0 || Q3 !== 0) begin
            $display("FAIL: async reset (Q1=%0d Q2=%0d Q3=%0d)", Q1, Q2, Q3);
            errors = errors + 1;
        end
        else
            $display("OK: async reset cleared all three counters");

        // ---- Verify all three resume from 0 ----
        @(negedge clk) reset = 0;
        repeat (3 * M3) @(posedge clk);

        if (errors == 0) $display("PASS: all three MOD values self-check clean");
        else             $display("FAIL: %0d errors", errors);
        $finish;
    end

endmodule