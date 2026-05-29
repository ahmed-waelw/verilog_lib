// ----------------------------------------------------------------------------
// Module:      RingCounter_tb
// Description: Self-checking testbench for ring counter. Verifies one-hot
//              invariant, position formula, N-cycle period, and asynchronous
//              reset from non-SEED state.
// DUT:         RingCounter
// Author:      Amr Said
// Date:        2026-05-26
// ----------------------------------------------------------------------------
`timescale 1ns/1ps

module RingCounter_tb();
    parameter N = 4;
    localparam [N-1:0] SEED = {{N-1{1'b0}}, 1'b1};  // 1 in the LSB

    reg            clk, reset;
    wire [N-1:0]   Q;
    integer        errors = 0;

    RingCounter #(.N(N)) DUT (.clk(clk), .reset(reset), .Q(Q));

    initial clk = 0;
    always #5 clk = ~clk;

    // Cycle index since reset — async-reset to match the DUT
    integer idx;
    always @(posedge clk or posedge reset) begin
        if (reset) idx <= 0;
        else       idx <= (idx + 1) % N;
    end

    // ---- Checkers ----
    // (1) One-hot invariant: exactly one bit set, every non-reset cycle.
    task automatic check_one_hot;
        begin
            if (!reset && (Q == 0 || (Q & (Q - 1)) != 0)) begin
                $display("ERROR (one-hot) @%0t: Q=%b", $time, Q);
                errors = errors + 1;
            end
        end
    endtask

    // (2) Position formula: Q must equal SEED << idx at every cycle.
    //     This is the closed-form spec, structurally unlike the DUT's shift.
    task automatic check_position;
        begin
            if (!reset && Q !== (SEED << idx)) begin
                $display("ERROR (position) @%0t: idx=%0d Q=%b expected=%b",
                         $time, idx, Q, SEED << idx);
                errors = errors + 1;
            end
        end
    endtask

    always @(posedge clk) #1 begin
        check_one_hot;
        check_position;
    end

    initial begin
        $dumpfile("RingCounter_tb.vcd");
        $dumpvars(0, RingCounter_tb);

        // ---- Test 1: reset loads SEED ----
        reset = 1;
        repeat (2) @(posedge clk);
        #1;
        if (Q !== SEED) begin
            $display("FAIL: reset did not load SEED (Q=%b)", Q);
            errors = errors + 1;
        end
        else $display("OK: reset loaded SEED = %b", SEED);

        // ---- Tests 2/5: run 3+ full cycles, checkers fire every tick ----
        @(negedge clk) reset = 0;
        repeat (3 * N) @(posedge clk);

        // ---- Test 3: cycle length = N (Q returns to itself after N cycles) ----
        begin : cycle_length_test
            reg [N-1:0] q_start;
            #1; q_start = Q;
            repeat (N) @(posedge clk);
            #1;
            if (Q !== q_start) begin
                $display("FAIL: cycle length != %0d (Q=%b, expected %b)",
                         N, Q, q_start);
                errors = errors + 1;
            end
            else $display("OK: cycle length = N = %0d", N);
        end

        // ---- Test 4: async reset from a clearly non-SEED state ----
        wait (Q == (SEED << (N - 1)));         // MSB position, the "farthest" from SEED
        @(negedge clk);
        reset = 1; #1;
        if (Q !== SEED) begin
            $display("FAIL: async reset did not reload SEED (Q=%b)", Q);
            errors = errors + 1;
        end
        else $display("OK: async reset reloaded SEED");

        // ---- release, verify clean restart over one more full cycle ----
        @(negedge clk) reset = 0;
        repeat (N) @(posedge clk);

        if (errors == 0) $display("PASS: self-check clean");
        else             $display("FAIL: %0d errors", errors);
        $finish;
    end

endmodule