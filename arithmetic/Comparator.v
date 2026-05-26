// ----------------------------------------------------------------------------
// Module:      Comparator
// Description: Parameterized N-bit unsigned magnitude comparator. Produces
//              three one-hot outputs: A == B, A < B, A > B.
// Parameters:  WIDTH - operand width in bits (default 4)
// Ports:       A   - operand A (WIDTH bits)
//              B   - operand B (WIDTH bits)
//              eq  - asserted when A == B
//              lt  - asserted when A <  B
//              gt  - asserted when A >  B
// Author:      Amr Said
// Date:        2026-05-14
// ----------------------------------------------------------------------------
module Comparator #(
    parameter WIDTH = 4
)(
    input  [WIDTH-1:0] A,
    input  [WIDTH-1:0] B,
    output             eq,
    output             lt,
    output             gt
);

    assign eq = (A == B);
    assign lt = (A <  B);
    assign gt = (A >  B);


endmodule
