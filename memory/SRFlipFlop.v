// ----------------------------------------------------------------------------
// Module:      SRFlipFlop
// Description: SR flip-flop with positive-edge clock and async active-high
//              reset. SR truth table: 00 hold, 01 reset, 10 set, 11 forbidden
//              (modelled as 1'bx).
// Ports:       S     - set input
//              R     - reset input (synchronous, via SR truth table)
//              clk   - input clock (rising edge)
//              reset - asynchronous reset, active high
//              Q     - data output
//              Qn    - inverted data output
// Author:      Amr Said
// Date:        2026-05-13
// ----------------------------------------------------------------------------
module SRFlipFlop(
    input  S,
    input  R,
    input  clk,
    input  reset,
    output reg Q,
    output Qn
);
    always @(posedge clk or posedge reset) begin
        if (reset)
            Q <= 1'b0;
        else
            case ({S, R})
                2'b00: Q <= Q;        // Hold      (S=0, R=0)
                2'b01: Q <= 1'b0;     // Reset     (S=0, R=1)
                2'b10: Q <= 1'b1;     // Set       (S=1, R=0)
                2'b11: Q <= 1'bx;     // Forbidden (S=1, R=1)
            endcase
    end

    assign Qn = ~Q;
endmodule
