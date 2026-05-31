// ----------------------------------------------------------------------------
// Module:      TFlipFlop_tb
// Description: Self-checking testbench for T flip-flop.
// DUT:         TFlipFlop
//              Ports: T, clk, reset -> Q, Qn
//              T=1 toggles, T=0 holds
// Author:      Amr Said
// Date:        2026-05-30
// ----------------------------------------------------------------------------
`timescale 1ns/1ps

module TFlipFlop_tb();

    reg T;
    reg clk;
    reg reset;
    wire Q;
    wire Qn;
    integer errors = 0;

    // DUT instantiation
    TFlipFlop DUT (.T(T), .clk(clk), .reset(reset), .Q(Q), .Qn(Qn));    
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
    //stimulus
    initial begin
        // Optional waveform dump for GTKWave
        $dumpfile("tff_tb.vcd");
        $dumpvars(0, TFlipFlop_tb);

        // 1. Initialize and apply reset
        T = 1'b0;
        reset = 1'b1; // Assert reset
        #12;           // hold reset across at least one posedge
        check(1'b0, "reset_high");

        // 2. Release reset, T=0 should hold
        reset = 1'b0;
        T = 1'b0;
        #10;           // Wait for one clock cycle
        check(1'b0, "T0_hold");
        // 3. T=1 should toggle Q
        T = 1'b1;
        #10;           // Wait for one clock cycle
        check(1'b1, "T1_toggle");
        // 4. T=1 again should toggle back
        #10;           // Wait for one clock cycle
        check(1'b0, "T1_toggle_back");
        // 5. T=0 should hold again
        T = 1'b0;
        #10;           // Wait for one clock cycle
        check(1'b0, "T0_hold_again");   
        // 6. T=1 should toggle again
        T = 1'b1;
        #10;           // Wait for one clock cycle
        check(1'b1, "T1_toggle_again");
        // Final report
        if (errors == 0)
            $display("All tests passed!");
        else
            $display("%d tests failed.", errors);   
        $finish;
    end
endmodule
