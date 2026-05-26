// ----------------------------------------------------------------------------
// Module:      Divider_tb
// Description: Self-checking testbench for the sequential Divider (default
//              8-bit). Tests directed corner cases (zero dividend, equal
//              operands, small/large, non-trivial remainders), exhaustive
//              sweep of all 8-bit dividend x divisor combinations (65K+
//              vectors, skipping divisor=0), reset-mid-operation recovery,
//              and back-to-back operation handoff. Uses start/done handshake
//              protocol with cycle-count timeout.
// DUT:         Divider.v
// Author:      Amr Said
// Date:        2026-05-26
// ----------------------------------------------------------------------------
`timescale 1ns/1ps

module Divider_tb();
    parameter WIDTH      = 8;
    parameter CLK_PERIOD = 10;

    reg                  clk;
    reg                  reset;
    reg                  start;
    reg  [WIDTH-1:0]     dividend;
    reg  [WIDTH-1:0]     divisor;
    wire [WIDTH-1:0]     quotient;
    wire [WIDTH-1:0]     remainder;
    wire                 done;

    Divider #(.WIDTH(WIDTH)) DUT (
        .clk(clk), .reset(reset), .start(start),
        .dividend(dividend), .divisor(divisor),
        .quotient(quotient), .remainder(remainder), .done(done)
    );

    // Clock generation
    initial clk = 1'b0;
    always #(CLK_PERIOD/2) clk = ~clk;

    integer errors = 0;
    integer passed = 0;
    integer checks = 0;
    integer i, j;

    // Issue a division and wait for done, then self-check the result.
    task do_divide;
        input [WIDTH-1:0] dvd;
        input [WIDTH-1:0] dvs;
        reg   [WIDTH-1:0] exp_q;
        reg   [WIDTH-1:0] exp_r;
        integer           timeout;
        reg               completed;
        begin
            checks = checks + 1;

            // Drive operands and pulse start synchronously on negedge so the
            // DUT samples a stable value at the next posedge.
            @(negedge clk);
            dividend = dvd;
            divisor  = dvs;
            start    = 1'b1;
            @(negedge clk);
            start    = 1'b0;

            // Wait for done with a cycle-count timeout
            // (WIDTH iterations + a few cycles of slack).
            timeout   = 0;
            completed = 1'b0;
            while (!completed && timeout < WIDTH + 10) begin
                @(posedge clk);
                #1;
                if (done) completed = 1'b1;
                timeout = timeout + 1;
            end

            if (!completed) begin
                errors = errors + 1;
                $display("FAIL (timeout): dividend=%0d divisor=%0d - done never asserted",
                         dvd, dvs);
            end else begin
                exp_q = dvd / dvs;
                exp_r = dvd % dvs;
                if (quotient !== exp_q || remainder !== exp_r) begin
                    errors = errors + 1;
                    $display("FAIL: %0d / %0d | got q=%0d r=%0d | exp q=%0d r=%0d",
                             dvd, dvs, quotient, remainder, exp_q, exp_r);
                end else begin
                    passed = passed + 1;
                end
            end
        end
    endtask

    initial begin
        $display("=== Divider testbench (WIDTH=%0d) ===", WIDTH);

        // ---- Initialize and release reset ----
        reset    = 1'b1;
        start    = 1'b0;
        dividend = 0;
        divisor  = 0;
        repeat (3) @(posedge clk);
        @(negedge clk);
        reset = 1'b0;

        // ---- Directed corner cases ----
        $display("--- directed corner cases ---");
        do_divide(8'd0,   8'd1);     // zero dividend
        do_divide(8'd1,   8'd1);     // identity
        do_divide(8'd255, 8'd1);     // max / 1
        do_divide(8'd255, 8'd255);   // equal operands
        do_divide(8'd1,   8'd255);   // small / large
        do_divide(8'd100, 8'd7);     // non-trivial remainder
        do_divide(8'd255, 8'd2);     // power-of-two divisor
        do_divide(8'd128, 8'd128);   // MSB-only values

        // ---- Reset mid-operation ----
        $display("--- reset-mid-operation recovery ---");
        @(negedge clk);
        dividend = 8'd200;
        divisor  = 8'd3;
        start    = 1'b1;
        @(negedge clk);
        start    = 1'b0;
        // Run a few cycles into BUSY, then assert reset.
        repeat (3) @(posedge clk);
        @(negedge clk);
        reset = 1'b1;
        repeat (2) @(posedge clk);
        @(negedge clk);
        reset = 1'b0;
        // After recovery a fresh division must complete correctly.
        do_divide(8'd200, 8'd3);     // expect q=66, r=2

        // ---- Back-to-back operations ----
        $display("--- back-to-back operations ---");
        do_divide(8'd150, 8'd11);
        do_divide(8'd97,  8'd5);
        do_divide(8'd33,  8'd17);

        // ---- Exhaustive 8-bit sweep (skip divisor=0) ----
        $display("--- exhaustive sweep: 256 x 255 = 65280 vectors ---");
        for (i = 0; i < 256; i = i + 1) begin
            for (j = 1; j < 256; j = j + 1) begin
                do_divide(i[WIDTH-1:0], j[WIDTH-1:0]);
            end
            if ((i % 32) == 0)
                $display("  dividend=%0d swept  (checks=%0d, errors=%0d)",
                         i, checks, errors);
        end

        $display("=== done: %0d checks, %0d passed, %0d errors ===",
                 checks, passed, errors);
        if (errors == 0) $display(">>> ALL TESTS PASSED <<<");
        else             $display(">>> %0d FAILURE(S) <<<", errors);
        $finish;
    end
endmodule
