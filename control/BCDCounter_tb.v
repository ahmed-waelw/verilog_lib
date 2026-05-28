// ----------------------------------------------------------------------------
// Module:      BCDCounter_tb
// Description: Self-checking testbench for BCD counter. Verifies 0-9 counting
//              sequence, BCD invariant (Q <= 9), wrap 9 to 0, and async reset.
// DUT:         BCDCounter
// Author:      Amr Said
// Date:        2026-05-26
// ----------------------------------------------------------------------------
`timescale 1ns/1ps

module BCDCounter_tb();

    reg        clk, reset;
    wire [3:0] Q;
    integer    errors = 0;

    BCDCounter DUT (.clk(clk), .reset(reset), .Q(Q));

    // clock: 100 MHz
    initial clk = 0;
    always #5 clk = ~clk;

    // reference model — counts 0..9 and wraps
    reg [3:0] exp = 0;
    always @(posedge clk or posedge reset) begin
        if (reset)         exp <= 0;
        else if (exp == 9) exp <= 0;
        else               exp <= exp + 1'b1;
    end

    // checker: two INDEPENDENT assertions per cycle
    //   (1) DUT tracks the model
    //   (2) BCD invariant — Q never exceeds 9, even if it happens to match exp
    task automatic check;
        begin
            if (Q !== exp) begin
                $display("ERROR @%0t: Q=%0d expected=%0d reset=%b",
                         $time, Q, exp, reset);
                errors = errors + 1;
            end
            if (Q > 4'd9) begin
                $display("ERROR @%0t: Q=%0d is invalid BCD", $time, Q);
                errors = errors + 1;
            end
        end
    endtask
    always @(posedge clk) #1 check;            // sample after the NBA region

    initial begin
        $dumpfile("BCDCounter_tb.vcd");
        $dumpvars(0, BCDCounter_tb);

        // -------- Test 1: reset, then free-run > 3 full 0-9 cycles --------
        reset = 1;
        repeat (2) @(posedge clk);
        @(negedge clk) reset = 0;
        repeat (35) @(posedge clk);            // covers 3.5 full cycles, BCD
                                               // invariant checked every cycle

        // -------- Test 3: async reset from a non-zero state (Q == 5) --------
        wait (Q == 4'd5);                      // synchronise to mid-count
        @(negedge clk);                        // park between clock edges
        reset = 1; #1;                         // NO posedge clk in this #1
        if (Q !== 4'd0) begin
            $display("FAIL: async reset did not load 0 (Q=%0d with no edge)", Q);
            errors = errors + 1;
        end
        else
            $display("OK: async reset confirmed from Q=5, now Q=%0d", Q);

        // -------- Test 4: release reset, verify count resumes from 0 --------
        @(negedge clk) reset = 0;
        repeat (15) @(posedge clk);            // 1.5 cycles, exercises one wrap

        // -------- Summary --------
        if (errors == 0) $display("PASS: self-check clean");
        else             $display("FAIL: %0d errors", errors);
        $finish;
    end

endmodule