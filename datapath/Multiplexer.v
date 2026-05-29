// ----------------------------------------------------------------------------
// Module:      Multiplexer
// Description: Parameterized WIDTH-to-1 multiplexer (dataflow style). Routes
//              the input line indexed by S to the output O.
// Parameters:  WIDTH     - number of input lines (default 2)
//              SEL_WIDTH - select width, $clog2(WIDTH) (derived)
// Ports:       I - WIDTH-bit input bus (one bit per input line)
//              S - SEL_WIDTH-bit select line
//              O - output (the selected input line)
// Author:      Amr Said
// Date:        2026-05-12
// ----------------------------------------------------------------------------
module Multiplexer #(
    parameter WIDTH     = 2,                  // number of input lines
    parameter SEL_WIDTH = $clog2(WIDTH)       // bits needed to select among them
)(
    input  [WIDTH-1:0]     I,
    input  [SEL_WIDTH-1:0] S,
    output                 O
);

    assign O = I[S];

endmodule