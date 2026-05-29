// ----------------------------------------------------------------------------
// Module:      JohnsonCounter_tb
// Description: Self-checking testbench for Johnson counter. Verifies sequence
//              against independent reference model, 2N cycle length, and
//              asynchronous reset.
// DUT:         JohnsonCounter
// Author:      Amr Said
// Date:        2026-05-26
// ----------------------------------------------------------------------------
`timescale 1ns/1ps

module JohnsonCounter_tb();
    parameter  N = 8;
    localparam CYCLE = 2*N;

    reg              clk, reset;
    wire [N-1:0]     Q;
    integer          errors = 0;

    JohnsonCounter #(.N(N)) DUT (.clk(clk), .reset(reset), .Q(Q));

    initial clk = 0;
    always #5 clk = ~clk;

    // Reference: same Johnson rule, written differently from the DUT.
    //   DUT  : Q   <= {Q[N-2:0], ~Q[N-1]};
    //   Model: exp <= (exp << 1) | {{N-1{1'b0}}, ~exp[N-1]};
    // The inverted MSB is zero-extended to N bits so only the LSB is set.
    reg [N-1:0] exp;
    always @(posedge clk or posedge reset) begin
        if (reset) exp <= {N{1'b0}};
        else       exp <= (exp << 1) | {{N-1{1'b0}}, ~exp[N-1]};
    end

    task automatic check;
        begin
            if (Q !== exp) begin
                $display("ERROR @%0t: Q=%b exp=%b reset=%b",
                         $time, Q, exp, reset);
                errors = errors + 1;
            end
        end
    endtask
    always @(posedge clk) #1 check;

    initial begin
        $dumpfile("JohnsonCounter_tb.vcd");
        $dumpvars(0, JohnsonCounter_tb);

        // ---- reset, then run 3 full cycles ----
        reset = 1;
        repeat (2) @(posedge clk);
        @(negedge clk) reset = 0;
        repeat (3 * CYCLE) @(posedge clk);

        // ---- explicit cycle-length assertion ----
        begin : cycle_length_test
            reg [N-1:0] q_start;
            #1; q_start = Q;
            repeat (CYCLE) @(posedge clk);
            #1;
            if (Q !== q_start) begin
                $display("FAIL: period != %0d (Q=%b, expected %b)",
                         CYCLE, Q, q_start);
                errors = errors + 1;
            end
            else $display("OK: cycle length = 2*N = %0d", CYCLE);
        end

        // ---- async reset from a clearly non-reset state ----
        wait (Q == {N{1'b1}});                   // all-ones, parametric
        @(negedge clk);
        reset = 1; #1;
        if (Q !== {N{1'b0}}) begin
            $display("FAIL: async reset did not clear (Q=%b)", Q);
            errors = errors + 1;
        end
        else $display("OK: async reset confirmed from all-ones, now Q=%b", Q);

        // ---- release reset, verify sequence restarts ----
        @(negedge clk) reset = 0;
        repeat (CYCLE) @(posedge clk);

        if (errors == 0) $display("PASS: self-check clean");
        else             $display("FAIL: %0d errors", errors);
        $finish;
    end

endmodule