// ----------------------------------------------------------------------------
// Module:      Subtractor
// Description: Parameterized N-bit subtractor. Computes D = A - B - b_in,
//              produces borrow-out. Implemented via two's-complement add.
// Parameters:  WIDTH - operand width in bits (default 4)
// Ports:       A     - minuend (WIDTH bits)
//              B     - subtrahend (WIDTH bits)
//              b_in  - borrow input
//              D     - difference output (WIDTH bits)
//              b_out - borrow output
// Author:      Amr Said
// Date:        2026-05-14
// ----------------------------------------------------------------------------
module Subtractor #(
    parameter WIDTH = 4
)(
    input  [WIDTH-1:0] A,
    input  [WIDTH-1:0] B,
    input              b_in,
    output [WIDTH-1:0] D,
    output             b_out
);

    assign {b_out, D} = A - B - b_in;

endmodule
