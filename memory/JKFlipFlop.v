// ----------------------------------------------------------------------------
// Module:      JKFlipFlop
// Description: JK flip-flop with positive-edge clock and async active-high
//              reset. JK truth table: 00 hold, 01 reset, 10 set, 11 toggle.
// Ports:       J     - J input
//              K     - K input
//              clk   - input clock (rising edge)
//              reset - asynchronous reset, active high
//              Q     - data output
//              Qn    - inverted data output
// Author:      Amr Said
// Date:        2026-05-13
// ----------------------------------------------------------------------------
module JKFlipFlop(
    input  J,
    input  K,
    input  clk,
    input  reset,
    output reg Q,
    output Qn
);
    always @(posedge clk or posedge reset) begin
        if (reset)
            Q <= 1'b0;
        else
            case ({J, K})
                2'b00: Q <= Q;        // Hold   (J=0, K=0)
                2'b01: Q <= 1'b0;     // Reset  (J=0, K=1)
                2'b10: Q <= 1'b1;     // Set    (J=1, K=0)
                2'b11: Q <= ~Q;       // Toggle (J=1, K=1)
            endcase
    end

    assign Qn = ~Q;
endmodule
