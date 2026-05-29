// ----------------------------------------------------------------------------
// Module:      Demultiplexer_tb
// Description: Self-checking testbench for parameterized 1-to-2^N demultiplexer.
// DUT:         Demultiplexer #(.N(3))
//              Ports: D, sel [N-1:0] -> Y [(1<<N)-1:0]
// Author:      Amr Said
// Date:        2026-05-29
// ----------------------------------------------------------------------------
`timescale 1ns/1ps
module Demultiplexer_tb();
parameter  N = 3;
localparam W = 1 << N;

reg          D;
reg  [N-1:0] sel;
wire [W-1:0] Y;
integer errors = 0;
integer s, dbit;
reg  [W-1:0] expected;

Demultiplexer #(.N(N)) DUT (.D(D), .sel(sel), .Y(Y));

// independent reference: index-set form, NOT a shift
function [W-1:0] ref_demux(input d, input [N-1:0] s);
    begin
        ref_demux = {W{1'b0}};
        if (d) ref_demux[s] = 1'b1;
    end
endfunction

initial begin
    $dumpfile("Demultiplexer_tb.vcd");
    $dumpvars(0, Demultiplexer_tb);
    $display("=== Demultiplexer testbench (N=%0d, W=%0d) ===", N, W);
    for (dbit = 0; dbit <= 1; dbit = dbit + 1) begin
        for (s = 0; s < W; s = s + 1) begin
            D   = dbit[0];
            sel = s[N-1:0];
            #5;
            expected = ref_demux(D, sel);
            if (Y !== expected) begin
                $display("FAIL: D=%b sel=%0d -> Y=%b (exp %b) @ %0t",
                         D, sel, Y, expected, $time);
                errors = errors + 1;
            end
            #5;
        end
    end
    if (errors == 0) $display("PASS: all %0d cases correct", 2*W);
    else             $display("DONE: %0d error(s)", errors);
    $finish;
end
endmodule