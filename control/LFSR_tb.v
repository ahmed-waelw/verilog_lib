// ----------------------------------------------------------------------------
// Module:      LFSR_tb
// Description: Self-checking testbench for linear-feedback shift register.
//              Verifies SEED loading, maximal-length sequence (uniqueness,
//              never-zero, period), deterministic replay, and async reset.
// DUT:         LFSR
// Author:      Amr Said
// Date:        2026-05-26
// ----------------------------------------------------------------------------
`timescale 1ns/1ps

module LFSR_tb();
    parameter WIDTH = 4;
    parameter [WIDTH-1:0] TAPS = 4'b1100;
    parameter [WIDTH-1:0] SEED = 4'b0001;
    localparam integer PERIOD = (1 << WIDTH) - 1;   // 15 for WIDTH=4

    reg              clk, reset;
    wire [WIDTH-1:0] Q;
    integer          errors = 0;

    LFSR #(.WIDTH(WIDTH), .TAPS(TAPS), .SEED(SEED)) DUT (
        .clk(clk), .reset(reset), .Q(Q)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    // ---- Recording + comparison state ----
    reg [WIDTH-1:0] trace [0:PERIOD-1];             // first-period golden sequence
    integer         seen  [0:(1<<WIDTH)-1];         // visit count per state
    integer         idx       = 0;
    reg             recording = 1'b0;
    reg             comparing = 1'b0;
    integer         i;
    initial for (i = 0; i < (1<<WIDTH); i = i + 1) seen[i] = 0;

    // ---- Per-cycle harness: invariant + recording + comparison ----
    always @(posedge clk) #1 begin
        // Invariant: an XOR LFSR must never enter the all-zeros lockup
        if (!reset && Q == 0) begin
            $display("ERROR @%0t: LFSR locked at all-zeros", $time);
            errors = errors + 1;
        end
        if (recording) begin
            trace[idx] = Q;
            seen[Q]    = seen[Q] + 1;
            idx        = idx + 1;
        end
        if (comparing) begin
            if (Q !== trace[idx]) begin
                $display("ERROR (determinism) @%0t: idx=%0d Q=%b trace=%b",
                         $time, idx, Q, trace[idx]);
                errors = errors + 1;
            end
            idx = idx + 1;
        end
    end

    initial begin
        $dumpfile("LFSR_tb.vcd");
        $dumpvars(0, LFSR_tb);

        // ---- Test 1: reset loads SEED ----
        reset = 1;
        repeat (2) @(posedge clk);
        #1;
        if (Q !== SEED) begin
            $display("FAIL: reset did not load SEED (Q=%b, want %b)", Q, SEED);
            errors = errors + 1;
        end
        else $display("OK: reset loaded SEED = %b", SEED);

        // ---- Test 2+3: record one full period; never-zero + uniqueness + period ----
        @(negedge clk) reset = 0;
        idx       = 0;
        recording = 1'b1;
        repeat (PERIOD) @(posedge clk);
        #2;                                          // let the final iteration settle
        recording = 1'b0;

        // Uniqueness: every non-zero state seen exactly once
        for (i = 1; i < (1<<WIDTH); i = i + 1) begin
            if (seen[i] != 1) begin
                $display("ERROR (uniqueness): state %0d seen %0d times", i, seen[i]);
                errors = errors + 1;
            end
        end
        if (seen[0] != 0) begin
            $display("ERROR: all-zeros state visited %0d times", seen[0]);
            errors = errors + 1;
        end

        // Period: Q must be back at SEED after PERIOD cycles
        if (Q !== SEED) begin
            $display("FAIL: period != %0d (Q=%b, want SEED=%b)", PERIOD, Q, SEED);
            errors = errors + 1;
        end
        else $display("OK: period = %0d, Q returned to SEED", PERIOD);

        // ---- Test 4: determinism — replay and compare to trace ----
        @(negedge clk) reset = 1;
        repeat (2) @(posedge clk);
        @(negedge clk) reset = 0;
        idx       = 0;
        comparing = 1'b1;
        repeat (PERIOD) @(posedge clk);
        #2;
        comparing = 1'b0;
        $display("OK: determinism replay complete");

        // ---- Test 5: async reset from a non-SEED state ----
        repeat (3) @(posedge clk);          // advance past SEED
        @(negedge clk);
        reset = 1; #1;
        if (Q !== SEED) begin
            $display("FAIL: async reset did not reload SEED (Q=%b)", Q);
            errors = errors + 1;
        end
        else $display("OK: async reset reloaded SEED");

        @(negedge clk) reset = 0;
        repeat (4) @(posedge clk);

        if (errors == 0) $display("PASS: self-check clean");
        else             $display("FAIL: %0d errors", errors);
        $finish;
    end

endmodule