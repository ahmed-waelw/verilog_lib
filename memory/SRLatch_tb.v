// ----------------------------------------------------------------------------
// Module:      SRLatch_tb
// Description: Self-checking testbench for gated SR latch.
// DUT:         SRLatch.v
//              Ports: S, R, En, reset -> Q, Qn
//              SR: 00=hold, 01=reset, 10=set, 11=forbidden (x)
// Author:      Amr Said
// Date:        2026-06-07
// ----------------------------------------------------------------------------
`timescale 1ns/1ps

module SRLatch_tb();
reg S;
reg R;
reg En;
reg reset;
wire Q;
wire Qn;
integer errors = 0;
//DUT instantiation
SRLatch DUT (.S(S), .R(R), .En(En), .reset(reset), .Q(Q), .Qn(Qn));

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
    $dumpfile("srlatch_tb.vcd");
    $dumpvars(0, SRLatch_tb);
    // 1. Initialize and apply reset
    S = 1'b0;
    R = 1'b0;
    En = 1'b0;
    reset = 1'b1; // Assert reset
    #12;           // hold reset across at least one posedge    
    check(1'b0, "reset_high");
    // 2. Release reset, En=0 should hold
    reset = 1'b0;
    En = 1'b0;
    #10;           // Wait for some time
    check(1'b0, "hold_en0");    
    // 3. En=1, S=1 R=0 should set
    En = 1'b1;
    S = 1'b1;
    R = 1'b0;
    #10;           // Wait for some time
    check(1'b1, "set");
    // 4. En=1, S=0 R=1 should reset
    S = 1'b0;
    R = 1'b1;
    #10;           // Wait for some time
    check(1'b0, "reset");   
    // 5. En=1, S=1 R=1 should be forbidden (x)
    S = 1'b1;
    R = 1'b1;
    #10;           // Wait for some time
    check(1'bx, "forbidden");
// Final report
    #5;
    if (errors == 0)
        $display("=== ALL TESTS PASSED ===");
    else
        $display("=== %0d FAILURE(S) ===", errors);
    $finish;
end
endmodule



