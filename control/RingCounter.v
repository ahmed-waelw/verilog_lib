// ----------------------------------------------------------------------------
// Module:      RingCounter
// Description: Synchronous one-hot ring counter. A single '1' rotates around
//              N flip-flops. Useful for FSM state vectors and round-robin
//              schedulers.
// Parameters:  N - number of flip-flops (default 4)
// Ports:       clk   - input clock (rising edge)
//              reset - asynchronous reset, active high (loads 1 into Q[0])
//              Q     - N-bit one-hot output
// Author:      Amr Said
// Date:        2026-05-14
// ----------------------------------------------------------------------------
module RingCounter #(
    parameter N = 4
)(
    input  clk,
    input  reset,
    output reg [N-1:0] Q
);
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            Q <= { {N-1{1'b0}}, 1'b1 };
        end else begin
            Q <= {Q[N-2:0], Q[N-1]};
        end
    end

endmodule
