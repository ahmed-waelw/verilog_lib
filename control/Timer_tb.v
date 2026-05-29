// ----------------------------------------------------------------------------
// Module:      Timer_tb
// Description: Self-checking testbench for periodic timer. Verifies tick width
//              (single-cycle), tick spacing (PERIOD clocks), first-tick timing,
//              reset invariant, and asynchronous reset mid-period.
// DUT:         Timer
// Author:      Amr Said
// Date:        2026-05-26
// ----------------------------------------------------------------------------
`timescale 1ns/1ps

module Timer_tb();
    parameter PERIOD = 16;
    parameter WIDTH  = 4;

    reg  clk, reset;
    wire tick;

    Timer #(.PERIOD(PERIOD), .WIDTH(WIDTH)) DUT (
        .clk(clk), .reset(reset), .tick(tick)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    integer errors;
    integer cycles_since_tick;          // gap from last tick
    integer cycles_since_reset;         // gap from reset release
    integer tick_count;
    reg     first_tick_seen;
    reg     tick_prev;

    initial begin
        errors = 0;
        cycles_since_tick  = 0;
        cycles_since_reset = 0;
        tick_count         = 0;
        first_tick_seen    = 0;
        tick_prev          = 0;
    end

    // ---- Per-cycle monitor: width + interval invariants ----
    always @(posedge clk) #1 begin
        // (1) Width invariant — tick must never be high two cycles in a row
        if (!reset && tick && tick_prev) begin
            $display("ERROR @%0t: tick stayed high for >1 cycle", $time);
            errors = errors + 1;
        end
        // (2) Reset invariant — tick must be low while reset is asserted
        if (reset && tick) begin
            $display("ERROR @%0t: tick high during reset", $time);
            errors = errors + 1;
        end

        if (reset) begin
            cycles_since_tick  = 0;
            cycles_since_reset = 0;
            first_tick_seen    = 0;
        end
        else begin
            cycles_since_reset = cycles_since_reset + 1;
            if (tick) begin
                tick_count = tick_count + 1;
                if (!first_tick_seen) begin
                    // (3) First tick after reset: tick asserts when cnt == PERIOD-1,
                    //     which is reached PERIOD-1 edges after reset release
                    if (cycles_since_reset != PERIOD - 1) begin
                        $display("ERROR: first tick at cycle %0d after reset (want %0d)",
                                 cycles_since_reset, PERIOD - 1);
                        errors = errors + 1;
                    end
                    first_tick_seen = 1;
                end
                else begin
                    // (4) Inter-tick spacing: must also be PERIOD
                    if (cycles_since_tick != PERIOD) begin
                        $display("ERROR: tick #%0d spacing %0d (want %0d)",
                                 tick_count, cycles_since_tick, PERIOD);
                        errors = errors + 1;
                    end
                end
                cycles_since_tick = 1;
            end
            else if (first_tick_seen) begin
                cycles_since_tick = cycles_since_tick + 1;
            end
        end

        tick_prev = tick;
    end

    initial begin
        $dumpfile("Timer_tb.vcd");
        $dumpvars(0, Timer_tb);

        // ---- Tests 1-3: free-run for 5+ periods; monitor catches everything ----
        reset = 1;
        repeat (2) @(posedge clk);
        @(negedge clk) reset = 0;
        repeat (5 * PERIOD + 2) @(posedge clk);

        if (tick_count < 5) begin
            $display("ERROR: only %0d ticks in 5+ periods (want >=5)", tick_count);
            errors = errors + 1;
        end
        else $display("OK: %0d ticks observed across 5+ periods", tick_count);

        // ---- Test 4: async reset mid-period, clean restart ----
        @(negedge clk) reset = 1; #1;
        if (tick) begin
            $display("FAIL: tick still high right after async reset");
            errors = errors + 1;
        end
        else $display("OK: tick deasserted by async reset");

        @(negedge clk) reset = 0;
        // Monitor re-checks "first tick at cycle PERIOD-1" automatically
        // because first_tick_seen was cleared by the reset branch.
        repeat (PERIOD + 2) @(posedge clk);

        if (errors == 0) $display("PASS: self-check clean");
        else             $display("FAIL: %0d errors", errors);
        $finish;
    end

endmodule