// ----------------------------------------------------------------------------
// Module:      Encoder
// Description: Parameterized 2^N-to-N binary encoder. Assumes exactly one
//              input bit is high; produces its position as a binary output.
//              Behaviour is undefined if more than one bit of D is high — use
//              PriorityEncoder for the multi-hot case.
// Parameters:  N - output width in bits (default 3, giving 8-to-3 encoder)
// Ports:       D - 2^N-bit one-hot input
//              Y - N-bit binary output
// Author:      Amr Said
// Date:        2026-05-14
// ----------------------------------------------------------------------------
module Encoder #(
    parameter N = 3
)(
    input  [(1<<N)-1:0] D,
    output reg [N-1:0]  Y
);
    integer i;

    always @(*) begin
        Y = 0;
        for (i = 0; i < (1<<N); i = i + 1)
            if (D[i]) Y = i;
    end

endmodule
