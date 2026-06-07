// ----------------------------------------------------------------------------
// Module:      DFlipFlop_tb
// Description: Self-checking testbench for D flip-flop.
// DUT:         DFlipFlop.v
//              Ports: D, clk, reset -> Q, Qn
// Author:      Amr Said
// Date:        2026-06-07
// ----------------------------------------------------------------------------
`timescale 1ns/1ps

module DFlipFlop_tb();

reg D;
reg clk;
reg reset;
wire Q;
wire Qn;
integer errors = 0;

// DUT instantiation
DFlipFlop DUT (.D(D), .clk(clk), .reset(reset), .Q(Q), .Qn(Qn));
// Clock generation: 10ns period
initial
clk = 1'b0;
always #5 clk = ~clk;

task check;
    input expected_Q;
    input [127:0] label;
    begin
        if (Q !== expected_Q || Qn !== ~expected_Q) 
        begin
            $display("[%0t] FAIL %0s: expected Q=%b, got Q=%b Qn=%b",
            $time, label, expected_Q, Q, Qn);
            errors = errors + 1;
        end 
        else 
        begin
            $display("[%0t] PASS %0s: Q=%b Qn=%b", $time, label, Q, Qn);
        end
    end
endtask

//stimulus generation

// Stimulus
initial begin
    // Optional waveform dump for GTKWave
    $dumpfile("dff_tb.vcd");
    $dumpvars(0, DFlipFlop_tb);

    // 1. Initialize and apply reset
    D     = 1'b0;
    reset = 1'b1;
    #12;                      // hold reset across at least one posedge
    check(1'b0, "reset_high");

    // 2. Release reset, capture D=1
    reset = 1'b0;
    D     = 1'b1;
    @(posedge clk); #1;       // sample just after the edge
    check(1'b1, "capture_D=1");

    // 3. Capture D=0
    D = 1'b0;
    @(posedge clk); #1;
    check(1'b0, "capture_D=0");

    // 4. Glitch test: D toggles between edges, Q must hold until next posedge
    D = 1'b1;
    @(posedge clk); #1;
    check(1'b1, "capture_D=1_again");
    #1 D = 1'b0;              // change D mid-cycle
    #1 D = 1'b1;
    #1 D = 1'b0;              // settle to 0 before next edge
    // Q should still be 1 here (last captured value)
    check(1'b1, "Q_holds_between_edges");
    @(posedge clk); #1;
    check(1'b0, "capture_after_glitch");

    // 5. Async reset mid-cycle (skip the #1 delay so reset takes effect immediately)
    D = 1'b1;
    @(posedge clk); #1;
    check(1'b1, "set_before_reset");
    #2 reset = 1'b1;
    #1 check(1'b0, "async_reset_clears_Q");
    reset = 1'b0;

    // 6. Recover after reset
    @(posedge clk); #1;
    check(1'b1, "capture_after_reset_release");

    // Final report
    #10;
    if (errors == 0)
        $display("=== ALL TESTS PASSED ===");
    else
        $display("=== %0d FAILURE(S) ===", errors);
    $finish;
end

endmodule