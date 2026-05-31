// ----------------------------------------------------------------------------
// Module:      DLatch_tb
// Description: Self-checking testbench for D latch.
// DUT:         DLatch
//              Ports: D, En, reset -> Q, Qn
//              Transparent when En=1, latches when En=0
// Author:      Amr Said
// Date:        2026-05-30
// ----------------------------------------------------------------------------
`timescale 1ns/1ps

module DLatch_tb();
reg D;
reg En;
reg reset;
wire Q;
wire Qn;
integer errors = 0;
// DUT instantiation
DLatch DUT (.D(D), .En(En), .reset(reset), .Q(Q), .Qn(Qn)); 

//check
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
    $dumpfile("dlatch_tb.vcd");
    $dumpvars(0, DLatch_tb);
    // 1. Initialize and apply reset
    D = 1'b0;
    En = 1'b0;
    reset = 1'b1; // Assert reset
    #12;           // hold reset across at least one posedge    
    check(1'b0, "reset_high");
    // 2. Release reset, En=0 should hold
    reset = 1'b0;
    En = 1'b0;
    #10;           // Wait for some time
    check(1'b0, "hold_en0");    
    // 3. En=1, D=1 should set
    En = 1'b1;
    D = 1'b1;
    #10;           // Wait for some time
    check(1'b1, "en1_d1");  
    // 4. En=1, D=0 should reset
    D = 1'b0;
    #10;           // Wait for some time
    check(1'b0, "en1_d0");
    // 5. En=0 should hold the last state (Q=0)
    En = 1'b0;
    D = 1'b1; // Change D, but should not affect Q
    #10;           // Wait for some time
    check(1'b0, "hold_en0_after_change");
    if (errors == 0)
        $display("=== ALL TESTS PASSED ===");
    else
        $display("=== %0d FAILURE(S) ===", errors);
    $finish;
end

endmodule
