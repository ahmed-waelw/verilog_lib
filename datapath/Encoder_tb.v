// ----------------------------------------------------------------------------
// Module:      Encoder_tb
// Description: Self-checking testbench for parameterized 2^N-to-N encoder.
// DUT:         Encoder #(.N(3))
//              Ports: D [(1<<N)-1:0] -> Y [N-1:0]
// Author:      Amr Said
// Date:        2026-05-29
// ----------------------------------------------------------------------------
`timescale 1ns/1ps

module Encoder_tb();
parameter WIDTH = 3;  // output width in bits (N)
reg  [(1<<WIDTH)-1:0] D;
wire [WIDTH-1:0] Y;
integer    errors = 0;
integer    i;
reg  [WIDTH-1:0] expected;

// DUT instantiation
Encoder #(.N(WIDTH)) DUT (.D(D), .Y(Y));

// reference model for checking
localparam W = 1 << WIDTH;   // input width = 2^N, output width = N

function [WIDTH-1:0] ref_encode(input [W-1:0] onehot);
    integer k;
    begin
        ref_encode = {WIDTH{1'b0}};
        for (k = 0; k < W; k = k + 1)
            if (onehot[k]) ref_encode = k[WIDTH-1:0];  // index of the set bit
    end
endfunction

localparam max = W - 1;  // highest input-bit index

initial begin
    $dumpfile("Encoder_tb.vcd");
    $dumpvars(0, Encoder_tb);
    $display("=== Encoder testbench ===");
    // drive each legal one-hot pattern: bit i high -> expect Y = i
    for (i = 0; i <= max; i = i + 1) begin
        D = {{(W-1){1'b0}}, 1'b1} << i;  // one-hot; sized so it works for W > 32
        #5;  // wait for outputs to settle
        expected = ref_encode(D);
        if (Y !== expected) begin              // !== catches X/Z too
            $display("FAIL: D=%b -> Y=%b (exp %b) @ %0t",
                     D, Y, expected, $time);
            errors = errors + 1;
        end
        #5;
    end
    // report + finish AFTER the loop completes
    if (errors == 0) $display("PASS: all %0d cases correct", W);
    else             $display("DONE: %0d error(s)", errors);
    $finish;
end

endmodule
