// ----------------------------------------------------------------------------
// Module:      JKFlipFlop_tb
// Description: Self-checking testbench for JK flip-flop.
// DUT:         JKFlipFlop
//              Ports: J, K, clk, reset -> Q, Qn
//              JK: 00=hold, 01=reset, 10=set, 11=toggle
// Author:      Amr Said
// Date:        2026-05-30
// ----------------------------------------------------------------------------
`timescale 1ns/1ps

module JKFlipFlop_tb();
reg J;
reg K;
reg clk;
reg reset;
wire Q;
wire Qn;
integer errors = 0;

// DUT instantiation
JKFlipFlop DUT (.J(J), .K(K), .clk(clk), .reset(reset), .Q(Q), .Qn(Qn));
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
    $dumpfile("jkff_tb.vcd");
    $dumpvars(0, JKFlipFlop_tb);
// 1. Initialize and apply reset
    J = 1'b0;
    K = 1'b0;
    reset = 1'b1;
    #12;
    check(1'b0, "reset_high");
//2. Release reset, J=0 K=0 should hold
    reset = 1'b0;
    J = 1'b0;
    K = 1'b0;
    #10; // Wait for one clock cycle
    check(1'b0, "hold_00");
//3. J=0 K=1 should reset
    J = 1'b0;
    K = 1'b1;
    #10;
    check(1'b0, "reset_01");
//4. J=1 K=0 should set
    J = 1'b1;
    K = 1'b0;
    #10;
    check(1'b1, "set_10");
//5. J=1 K=1 should toggle
    J = 1'b1;
    K = 1'b1;
    #10;
    check(1'b0, "toggle_11");
//6. J=1 K=1 again should toggle back
    #10;
    check(1'b1, "toggle_back_11");
//7. J=0 K=0 should hold
    J = 1'b0;
    K = 1'b0;
    #10;
    check(1'b1, "hold_again_00");

    #10;
    if (errors == 0) $display("=== ALL TESTS PASSED ===");
    else             $display("=== %0d FAILURE(S) ===", errors);
    $finish;
end



endmodule
