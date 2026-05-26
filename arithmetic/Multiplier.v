// ----------------------------------------------------------------------------
// Module:      Multiplier
// Description: Parameterized N-bit unsigned multiplier. Produces a 2*WIDTH
//              product. Combinational by default — synthesis will infer DSP
//              blocks on FPGAs that have them.
// Parameters:  WIDTH - operand width in bits (default 8)
// Ports:       A - operand A (WIDTH bits)
//              B - operand B (WIDTH bits)
//              P - product output (2*WIDTH bits)
// Author:      Amr Said
// Date:        2026-05-14
// ----------------------------------------------------------------------------
module Multiplier #(
    parameter WIDTH = 8
)(
    input  [WIDTH-1:0]   A,
    input  [WIDTH-1:0]   B,
    output [2*WIDTH-1:0] P
);

    assign P = A * B;
   

   
endmodule
