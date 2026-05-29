// ----------------------------------------------------------------------------
// Module:      Multiplexer_df_tb
// Description: Self-checking testbench for 2-to-1 dataflow multiplexer.
// DUT:         Multiplexer_df
//              Ports: I [0:1], S -> O
//              S=0 selects I[0], S=1 selects I[1]
// Author:      Amr Said
// Date:        2026-05-29
// ----------------------------------------------------------------------------
`timescale 1ns/1ps

module Multiplexer_tb();
parameter  WIDTH     = 4;                 // number of input lines
localparam SEL_WIDTH = $clog2(WIDTH);

reg  [WIDTH-1:0]     I;
reg  [SEL_WIDTH-1:0] S;
wire                 O;
integer errors = 0;
integer s, d;
reg     expected;

// DUT instantiation
Multiplexer #(.WIDTH(WIDTH)) DUT (.I(I), .S(S), .O(O));

// reference model: bit S of I, written as shift+mask — a different expression
// than the DUT's bit-select, so an indexing bug won't hide identically in both
function ref_mux(input [WIDTH-1:0] in, input [SEL_WIDTH-1:0] sel);
    ref_mux = (in >> sel) & 1'b1;
endfunction

initial begin
    $dumpfile("Multiplexer_tb.vcd");
    $dumpvars(0, Multiplexer_tb);
    $display("=== Multiplexer testbench ===");
    // exhaustive: every select value x every input combination
    for (s = 0; s < WIDTH; s = s + 1) begin
        for (d = 0; d < (1 << WIDTH); d = d + 1) begin
            S = s[SEL_WIDTH-1:0];
            I = d[WIDTH-1:0];
            #5;
            expected = ref_mux(I, S);
            if (O !== expected) begin
                $display("FAIL: S=%0d I=%b -> O=%b (exp %b) @ %0t",
                         S, I, O, expected, $time);
                errors = errors + 1;
            end
            #5;
        end
    end
    if (errors == 0) $display("PASS: all %0d cases correct", WIDTH * (1 << WIDTH));
    else             $display("DONE: %0d error(s)", errors);
    $finish;
end

endmodule
