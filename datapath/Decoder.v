// ----------------------------------------------------------------------------
// Module:      Decoder
// Description: Parameterized N-to-2^N decoder with active-high outputs and an
//              active-high enable. Asserts exactly one output corresponding
//              to the binary value of `sel` when `en` is high.
// Parameters:  N - input width in bits (default 3, giving 3-to-8 decoder)
// Ports:       en  - enable, active high (when low, all outputs are 0)
//              sel - N-bit selector
//              Y   - 2^N-bit one-hot output
// Author:      Amr Said
// Date:        2026-05-14
// ----------------------------------------------------------------------------
module Decoder #(
    parameter N = 3
)(
    input              en,
    input  [N-1:0]     sel,
    output [(1<<N)-1:0] Y
);
    assign Y = en ? (1'b1 << sel) : 0;
 

endmodule
