// ----------------------------------------------------------------------------
// Module:      DownCounter
// Description: Parameterized N-bit synchronous down counter with asynchronous
//              active-high reset. Resets to all-ones, counts down to 0, then
//              wraps back to all-ones.
// Parameters:  WIDTH - counter width in bits (default 4)
// Ports:       clk   - input clock (rising edge)
//              reset - asynchronous reset, active high (forces Q to all-ones)
//              Q     - WIDTH-bit count output
// Author:      Amr Said
// Date:        2026-05-14
// ----------------------------------------------------------------------------
module DownCounter #(
    parameter WIDTH = 4
)(
    input                  clk,
    input                  reset,
    output reg [WIDTH-1:0] Q
);

    always @(posedge clk or posedge reset) begin
        if (reset)
            Q <= {WIDTH{1'b1}};
        else
            Q <= Q - 1'b1;
    end

endmodule
