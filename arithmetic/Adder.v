// ----------------------------------------------------------------------------
// Module:      Adders
// Description: Multi-bit combinational adder.
// Ports:       a    - operand bits
//              b    - operand bits
//              cin  - carry input
//              s    - sum output
//              cout - carry output
// Author:      Amr Said
// Date:        2026-05-18
// ----------------------------------------------------------------------------
module Adder #(
    parameter WIDTH = 4
)(
    input  [WIDTH-1:0] a,
    input  [WIDTH-1:0] b,
    input              cin,
    output [WIDTH-1:0] s,
    output             cout
);

    assign {cout, s} = a + b + cin;
endmodule