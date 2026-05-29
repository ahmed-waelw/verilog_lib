// ----------------------------------------------------------------------------
// Module:      UpCounter
// Description: Parameterized N-bit synchronous up counter with asynchronous
//              active-high reset. Counts from 0 to 2^WIDTH-1, then wraps.
// Parameters:  WIDTH - counter width in bits (default 4)
// Ports:       clk   - input clock (rising edge)
//              reset - asynchronous reset, active high
//              Q     - WIDTH-bit count output
// Author:      Amr Said
// Date:        2026-05-12
// ----------------------------------------------------------------------------
module UpCounter #(
    parameter WIDTH = 4
)(
    input                  clk,
    input                  reset,
    output reg [WIDTH-1:0] Q
);

    always @(posedge clk or posedge reset) begin
        if (reset)
            Q <= {WIDTH{1'b0}};
        else
            Q <= Q + 1'b1;
    end

endmodule
