// ----------------------------------------------------------------------------
// Module:      ModNCounter
// Description: Parameterized modulo-N synchronous up counter. Counts 0 to
//              MOD-1 and wraps to 0. WIDTH should be large enough to hold
//              MOD-1 (i.e. WIDTH >= $clog2(MOD)).
// Parameters:  MOD   - modulus / wrap value (default 10)
//              WIDTH - output width in bits (default 4)
// Ports:       clk   - input clock (rising edge)
//              reset - asynchronous reset, active high (forces Q to 0)
//              Q     - count output, WIDTH bits wide
// Author:      Amr Said
// Date:        2026-05-14
// ----------------------------------------------------------------------------
module ModNCounter #(
    parameter MOD   = 10,
    parameter WIDTH = 4
)(
    input  clk,
    input  reset,
    output reg [WIDTH-1:0] Q
);

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            Q <= 0;
        end else if (Q == MOD - 1) begin
            Q <= 0;
        end else begin
            Q <= Q + 1;
        end
    end

endmodule
