// ----------------------------------------------------------------------------
// Module:      GrayCounter
// Description: Synchronous Gray-code up counter. Only one output bit changes
//              per increment. Used for clock-domain-crossing FIFOs and
//              low-noise applications.
// Parameters:  WIDTH - count width in bits (default 4)
// Ports:       clk   - input clock (rising edge)
//              reset - asynchronous reset, active high (forces Q to 0)
//              Q     - WIDTH-bit Gray-code output
// Author:      Amr Said
// Date:        2026-05-14
// ----------------------------------------------------------------------------
module GrayCounter #(
    parameter WIDTH = 4
)(
    input  clk,
    input  reset,
    output reg [WIDTH-1:0] Q
);
    reg  [WIDTH-1:0] bin;
    wire [WIDTH-1:0] next_bin = bin + 1;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            bin <= 0;
            Q   <= 0;
        end else begin
            bin <= next_bin;
            Q   <= (next_bin >> 1) ^ next_bin;
        end
    end

endmodule
