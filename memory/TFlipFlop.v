// ----------------------------------------------------------------------------
// Module:      TFlipFlop
// Description: T flip-flop with positive-edge clock and async active-high
//              reset. Toggles Q when T=1, holds when T=0.
// Ports:       T     - toggle input
//              clk   - input clock (rising edge)
//              reset - asynchronous reset, active high
//              Q     - data output
//              Qn    - inverted data output
// Author:      Amr Said
// Date:        2026-06-07
// ----------------------------------------------------------------------------
module TFlipFlop(
    input  T,
    input  clk,
    input  reset,
    output reg Q,
    output Qn
);
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            Q <= 1'b0;
        end else if (T) begin
            Q <= ~Q;
        end
    end

    assign Qn = ~Q;
endmodule
