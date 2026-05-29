// ----------------------------------------------------------------------------
// Module:      Demultiplexer
// Description: Parameterized 1-to-2^N demultiplexer. Routes input D to the
//              output bit selected by `sel`; all other outputs are 0.
// Parameters:  N - selector width in bits (default 3, giving 1-to-8)
// Ports:       D   - single-bit data input
//              sel - N-bit selector
//              Y   - 2^N-bit output
// Author:      Amr Said
// Date:        2026-05-14
// ----------------------------------------------------------------------------
module Demultiplexer #(
    parameter N = 3
)(
    input              D,
    input  [N-1:0]     sel,
    output [(1<<N)-1:0] Y
);

    assign Y = D ? (1'b1 << sel) : 0;

endmodule
