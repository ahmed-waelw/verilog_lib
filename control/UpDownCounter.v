// ----------------------------------------------------------------------------
// Module:      UpDownCounter
// Description: Parameterized N-bit synchronous up/down counter with
//              asynchronous active-low reset. Counts up when up_down is high,
//              down when low. Wraps in both directions.
// Parameters:  WIDTH - counter width in bits (default 4)
// Ports:       clk     - input clock (rising edge)
//              rst_n   - asynchronous reset, active low
//              up_down - direction control (1 = up, 0 = down)
//              Q       - WIDTH-bit count output
// Author:      Amr Said
// Date:        2026-05-12
// ----------------------------------------------------------------------------
module UpDownCounter #(
    parameter WIDTH = 4
)(
    input                  clk,
    input                  rst_n,
    input                  up_down,
    output reg [WIDTH-1:0] Q
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            Q <= {WIDTH{1'b0}};
        else if (up_down)
            Q <= Q + 1'b1;
        else
            Q <= Q - 1'b1;
    end

endmodule
