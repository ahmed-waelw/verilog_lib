// ----------------------------------------------------------------------------
// Module:      SRFlipFlop_tb
// Description: Self-checking testbench for SR flip-flop.
// DUT:         SRFlipFlop
//              Ports: S, R, clk, reset -> Q, Qn
//              SR: 00=hold, 01=reset, 10=set, 11=forbidden (x)
// Author:      Amr Said
// Date:        2026-06-07
// ----------------------------------------------------------------------------
`timescale 1ns/1ps

module SRFlipFlop_tb();

reg S;
reg R;
reg clk;
reg reset;
wire Q;
wire Qn;
integer errors = 0;
//DUT instantiation
SRFlipFlop DUT (.S(S), .R(R), .clk(clk), .reset(reset), .Q(Q), .Qn(Qn));
//Clock generation: 10ns period
initial
clk = 1'b0;
always #5 clk = ~clk;

task check;
    input expected_Q;
    input [127:0] label;
    begin
        if (Q !== expected_Q || Qn !== ~expected_Q)
        begin
            $display("[%0t] FAIL %0s: expected Q=%b, got Q=%b Qn=%b", $time, label, expected_Q, Q, Qn);
            errors = errors + 1;
        end
        else
        begin
            $display("[%0t] PASS %0s: Q=%b Qn=%b", $time, label, Q, Qn);
        end
    end
endtask
//stimulus generation
initial begin
    // Optional waveform dump for GTKWave
    $dumpfile("srff_tb.vcd");
    $dumpvars(0, SRFlipFlop_tb);
    // 1. Initialize and apply reset
    S = 1'b0;
    R = 1'b0;
    reset = 1'b1; // Assert reset
    #12;           // hold reset across at least one posedge
    check(1'b0, "reset_high");
    // 2. Release reset, S=0 R=0 should hold
    reset = 1'b0;
    S = 1'b0;
    R = 1'b0;
    #10;           // Wait for one clock cycle
    check(1'b0, "hold_00");
    // 3. S=1 R=0 should set
    S = 1'b1;
    R = 1'b0;
    #10;           // Wait for one clock cycle
    check(1'b1, "set_10");
    // 4. S=0 R=1 should reset
    S = 1'b0;
    R = 1'b1;
    #10;           // Wait for one clock cycle
    check(1'b0, "reset_01");
    // 5. S=1 R=1 should be forbidden (x)
    S = 1'b1;
    R = 1'b1;
    #10;           // Wait for one clock cycle2 => Check for forbidden state
    if (Q !== 1'bx || Qn !== 1'bx)
    begin
        $display("[%0t] FAIL forbidden_state: expected Q=x, got Q=%b Qn=%b", $time, Q, Qn);
        errors = errors + 1;
    end
    else
    begin
        $display("[%0t] PASS forbidden_state: Q=x Qn=x", $time);
    end

    #10;
    if (errors == 0) $display("=== ALL TESTS PASSED ===");
    else             $display("=== %0d FAILURE(S) ===", errors);
    $finish;
end
endmodule
