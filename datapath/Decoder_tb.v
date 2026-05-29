// ----------------------------------------------------------------------------
// Module:      Decoder_tb
// Description: Self-checking testbench for parameterized N-to-2^N decoder.
// DUT:         Decoder #(.N(3))
//              Ports: en, sel [N-1:0] -> Y [(1<<N)-1:0]
// Author:      Amr Said
// Date:        2026-05-29
// ----------------------------------------------------------------------------
`timescale 1ns/1ps

module Decoder_tb();
    parameter WIDTH = 3;  // input width in bits (N)
    reg [WIDTH-1:0] sel;
    reg             en;
    wire [(1<<WIDTH)-1:0] Y;
    integer    errors = 0;
    integer    i, e;
    reg  [(1<<WIDTH)-1:0] expected;

    // DUT instantiation
    Decoder #(.N(WIDTH)) DUT (.en(en), .sel(sel), .Y(Y));

    // reference model for checking
    localparam W = 1 << WIDTH;                 // output width = 2^WIDTH

    function [W-1:0] ref_decode(input [WIDTH-1:0] s, input en);
        begin
            ref_decode = {W{1'b0}};        // default: all lines low
            if (en) ref_decode[s] = 1'b1;  // drive the s-th line high
        end
    endfunction

    localparam max = (1 << WIDTH) - 1;  // max selector value (all bits 1)

    initial begin
        $dumpfile("Decoder_tb.vcd");
        $dumpvars(0, Decoder_tb);
        $display("=== Decoder testbench ===");
        // test all combinations of sel and en
        for (e = 0; e <= 1; e = e + 1) begin
            for (i = 0; i <= max; i = i + 1) begin
                sel = i;
                en  = e;
                #5;  // wait for outputs to settle
                expected = ref_decode(sel, en);
                if (Y !== expected) begin              // !== catches X/Z too
                    $display("FAIL: en=%b sel=%b -> Y=%b (exp %b) @ %0t",
                             en, sel, Y, expected, $time);
                    errors = errors + 1;
                end
                #5;
            end
        end
        // report + finish AFTER both loops complete
        if (errors == 0) $display("PASS: all %0d cases correct", 2*(1<<WIDTH));
        else             $display("DONE: %0d error(s)", errors);
        $finish;
    end
endmodule