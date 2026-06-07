// ----------------------------------------------------------------------------
// Module:      SRLatch
// Description: Gated SR latch with async active-high reset. Transparent
//              (responds to S/R per truth table) when En is high.
//              SR truth table: 00 hold, 01 reset, 10 set, 11 forbidden (1'bx).
// Ports:       S     - set input
//              R     - reset input (gated by enable)
//              En    - enable, active high (transparent when high)
//              reset - asynchronous reset, active high
//              Q     - data output
//              Qn    - inverted data output
// Author:      Amr Said
// Date:        2026-06-07
// ----------------------------------------------------------------------------
module SRLatch(
    input  S,
    input  R,
    input  En,
    input  reset,
    output reg Q,
    output Qn
);
    always @(*) begin
        if (reset)
            Q = 1'b0;
        else if (En)
            case ({S, R})
                2'b00: Q = Q;        // hold
                2'b01: Q = 1'b0;     // R clears
                2'b10: Q = 1'b1;     // S sets
                2'b11: Q = 1'bx;     // forbidden
            endcase
        // else (En low): hold
    end

    assign Qn = ~Q;
endmodule
