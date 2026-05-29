// ----------------------------------------------------------------------------
// Module:      JohnsonCounter
// Description: Synchronous Johnson (twisted-ring) counter. N flip-flops give
//              2*N unique states. Each clock edge shifts Q left and feeds
//              ~Q[N-1] into Q[0].
// Parameters:  N - number of flip-flops (default 4, giving 8 states)
// Ports:       clk   - input clock (rising edge)
//              reset - asynchronous reset, active high (forces Q to 0)
//              Q     - N-bit Johnson sequence output
// Author:      Amr Said
// Date:        2026-05-14
// ----------------------------------------------------------------------------
module JohnsonCounter #(
    parameter N = 4
)(
    input  clk,
    input  reset,
    output reg [N-1:0] Q
);

    always @(posedge clk or posedge reset) begin
        if (reset)
            Q <= 0;
        else
            Q <= {Q[N-2:0], ~Q[N-1]};
    end

endmodule
