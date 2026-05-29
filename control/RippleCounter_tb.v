// ----------------------------------------------------------------------------
// Module:      RippleCounter_tb
// Description: Self-checking testbench for asynchronous ripple counter. Uses
//              synchronous reference model with negedge sampling for settling
//              time. Tests full-count wraps, MAX to 0 cascade, and async reset.
// DUT:         RippleCounter
// Author:      Amr Said
// Date:        2026-05-26
// ----------------------------------------------------------------------------
`timescale 1ns/1ps

module RippleCounter_tb();
    parameter WIDTH = 4;
    localparam integer DEPTH = (1 << WIDTH);

    reg                clk, reset;
    wire [WIDTH-1:0]   Q;
    integer            errors = 0;

    RippleCounter #(.WIDTH(WIDTH)) DUT (.clk(clk), .reset(reset), .Q(Q));

    initial clk = 0;
    always #5 clk = ~clk;

    // Synchronous reference — reaches the same value the DUT does each cycle,
    // but in a single delta rather than via the ripple cascade.
    reg [WIDTH-1:0] exp;
    always @(posedge clk or posedge reset) begin
        if (reset) exp <= 0;
        else       exp <= exp + 1'b1;
    end

    // Sample on NEGedge: a full half-period of settling time for the chain.
    // The #1 also keeps the checker clear of any negedge-driven stimulus.
    task automatic check;
        begin
            if (Q !== exp) begin
                $display("ERROR @%0t: Q=%b exp=%b reset=%b",
                         $time, Q, exp, reset);
                errors = errors + 1;
            end
        end
    endtask
    always @(negedge clk) #1 check;

    initial begin
        $dumpfile("RippleCounter_tb.vcd");
        $dumpvars(0, RippleCounter_tb);

        // ---- Test 1: reset, then free-run through 2+ full wraps ----
        reset = 1;
        repeat (2) @(posedge clk);
        @(negedge clk) reset = 0;                    // <-- this line was lost
        repeat (2 * DEPTH) @(posedge clk);           // 32 cycles, > 2 wraps
        @(negedge clk);                              // settle past the last posedge's NBA

        // ---- Test 3: explicit wrap MAX -> 0 ----
        wait (Q == {WIDTH{1'b1}});
        @(posedge clk);                              // next edge: full-width cascade
        @(negedge clk) #1;                           // sample after settling                        // sample after settling
        if (Q !== {WIDTH{1'b0}}) begin
            $display("FAIL: wrap MAX->0 (Q=%b after settling)", Q);
            errors = errors + 1;
        end
        else $display("OK: wrap MAX -> 0 confirmed after ripple settled");

        // ---- Test 2: async reset from mid-count, all stages must clear ----
        repeat (5) @(posedge clk);                  // advance partway through
        @(negedge clk);
        reset = 1; #1;                              // async reset is parallel
        if (Q !== {WIDTH{1'b0}}) begin
            $display("FAIL: async reset did not clear all stages (Q=%b)", Q);
            errors = errors + 1;
        end
        else $display("OK: async reset cleared all %0d stages in parallel", WIDTH);

        @(negedge clk) reset = 0;
        repeat (4) @(posedge clk);                  // verify clean restart

        if (errors == 0) $display("PASS: self-check clean");
        else             $display("FAIL: %0d errors", errors);
        $finish;
    end

endmodule