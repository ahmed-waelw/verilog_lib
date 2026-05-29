// ----------------------------------------------------------------------------
// Module:      UpDownCounter_tb
// Description: Self-checking testbench for parameterized up/down counter. Uses
//              UpCounter and DownCounter as reference models. Tests both
//              directions and asynchronous active-low reset.
// DUT:         UpDownCounter
// Author:      Amr Said
// Date:        2026-05-26
// ----------------------------------------------------------------------------
`timescale 1ns / 1ps
module UpDownCounter_tb();
    parameter WIDTH = 4;
    localparam [WIDTH-1:0] MAX = {WIDTH{1'b1}};

    reg clk, rst_n, dir;
    wire [WIDTH-1:0] Q_dut, Q_up, Q_down;

    // DUT uses active-low reset (rst_n) and direction control (up_down).
    UpDownCounter #(.WIDTH(WIDTH)) DUT (
        .clk(clk), .rst_n(rst_n), .up_down(dir), .Q(Q_dut)
    );

    // Reference counters use active-high reset; derive it from rst_n so all
    // three devices enter/leave reset on the same edges.
    wire ref_reset = ~rst_n;

    // Golden references (already verified)
    UpCounter   #(.WIDTH(WIDTH)) ref_up   (.clk(clk), .reset(ref_reset), .Q(Q_up));
    DownCounter #(.WIDTH(WIDTH)) ref_down (.clk(clk), .reset(ref_reset), .Q(Q_down));

    initial clk = 0;
    always #5 clk = ~clk;                            // 10 ns period

    // phase flags select which reference is the oracle this cycle
    reg use_up   = 1'b0;
    reg use_down = 1'b0;
    integer errors = 0;

    // checker: sample after the NBA region settles
    always @(posedge clk) #1 begin
        if (use_up   && Q_dut !== Q_up) begin
            $display("ERROR (up): Q_dut=%0d Q_up=%0d at t=%0t",
                     Q_dut, Q_up, $time);
            errors = errors + 1;
        end
        if (use_down && Q_dut !== (Q_down + 1'b1)) begin
            $display("ERROR (down): Q_dut=%0d Q_down=%0d (exp %0d)",
                     Q_dut, Q_down, Q_down + 1'b1);
            errors = errors + 1;
        end
    end

    initial begin
        $dumpfile("UpDownCounter_tb.vcd");
        $dumpvars(0, UpDownCounter_tb);

        // ---- Phase 1: pure UP, compare to UpCounter directly ----
        rst_n = 0; dir = 1;                          // assert reset (active low)
        repeat (2) @(posedge clk);
        @(negedge clk) rst_n = 1;                    // release reset
        use_up = 1;
        repeat (50) @(posedge clk);                  // > 3 full wraps
        use_up = 0;

        // ---- Phase 2: pure DOWN, compare to DownCounter + 1 ----
        @(negedge clk) rst_n = 0;                    // re-reset for alignment
        repeat (2) @(posedge clk);
        @(negedge clk); rst_n = 1; dir = 0;          // release, count down
        use_down = 1;
        repeat (50) @(posedge clk);
        use_down = 0;

        // ---- Directed: async reset proof ----
        @(negedge clk); rst_n = 0; #1;               // assert reset off-edge
        if (Q_dut !== 0) begin
            $display("FAIL: DUT reset not async (Q_dut=%0d)", Q_dut);
            errors = errors + 1;
        end
        else
            $display("OK: async reset confirmed, Q_dut=%0d", Q_dut);
        @(negedge clk) rst_n = 1; dir = 1;           // release
        repeat (4) @(posedge clk);

        if (errors == 0) $display("PASS: self-check clean");
        else             $display("FAIL: %0d errors", errors);
        $finish;
    end

endmodule
