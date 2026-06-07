// ----------------------------------------------------------------------------
// Module:      DFlipFlop
// Description: D flip-flop with positive-edge clock and async active-high reset.
// Ports:       D     - data input
//              clk   - input clock (rising edge)
//              reset - asynchronous reset, active high
//              Q     - data output
//              Qn    - inverted data output
// Author:      Amr Said
// Date:        2026-06-07
// ----------------------------------------------------------------------------
module DFlipFlop(
    input  D,
    input  clk,
    input  reset,
    output reg Q,
    output Qn
);
    always @(posedge clk or posedge reset) begin
        if (reset)
            Q <= 0;
        else
            Q <= D;
    end

    assign Qn = ~Q;
endmodule
