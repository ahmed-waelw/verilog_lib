// ----------------------------------------------------------------------------
// Module:      PriorityEncoder
// Description: Parameterized 2^N-to-N priority encoder. Outputs the index
//              of the highest-numbered asserted input bit, plus a `valid`
//              flag indicating that at least one input was high.
// Parameters:  N - output width in bits (default 3, giving 8-to-3 priority)
// Ports:       D     - 2^N-bit input (may have multiple bits high)
//              Y     - N-bit binary output (index of highest-priority bit)
//              valid - high when any input bit is asserted
// Author:      Amr Said
// Date:        2026-05-14
// ----------------------------------------------------------------------------
module PriorityEncoder #(
    parameter N = 3
)(
    input  [(1<<N)-1:0] D,
    output reg [N-1:0]  Y,
    output              valid
);
    assign valid = |D;

    integer i;

    always @(*) begin
        Y = 0;
        for (i = 0; i < (1<<N); i = i + 1)
            if (D[i]) Y = i;        // scan low->high, last write wins -> highest set bit
    end

endmodule
