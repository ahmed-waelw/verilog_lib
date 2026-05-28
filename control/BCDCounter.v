// ----------------------------------------------------------------------------
// Module:      BCDCounter
// Description: 4-bit binary-coded decimal counter. Counts 0 (4'b0000) up to
//              9 (4'b1001), then wraps back to 0. Async active-high reset.
// Ports:       clk   - input clock (rising edge)
//              reset - asynchronous reset, active high (forces Q to 0)
//              Q     - 4-bit BCD count output (valid range 0-9)
// Author:      Amr Said
// Date:        2026-05-14
// ----------------------------------------------------------------------------
module BCDCounter(
    input  clk,
    input  reset,
    output reg [3:0] Q
);
    always @(posedge clk or posedge reset) begin
        if (reset)
            Q <= 0;
        else if (Q == 9)
            Q <= 0;
        else
            Q <= Q + 1;
    end

endmodule
