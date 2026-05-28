// ----------------------------------------------------------------------------
// Module:      Timer
// Description: Periodic timer. Counts from 0 to PERIOD-1, asserts a
//              single-cycle `tick` output on the wrap, and rolls back to 0.
//              Useful for generating events at fixed intervals.
// Parameters:  PERIOD - count modulus (default 1000)
//              WIDTH  - internal counter width in bits (must hold PERIOD-1)
// Ports:       clk   - input clock (rising edge)
//              reset - asynchronous reset, active high (forces count to 0)
//              tick  - one-cycle high pulse when count == PERIOD-1
// Author:      Amr Said
// Date:        2026-05-14
// ----------------------------------------------------------------------------
module Timer #(
    parameter PERIOD = 1000,
    parameter WIDTH  = 10
)(
    input  clk,
    input  reset,
    output tick
);

    reg [WIDTH-1:0] cnt;

    always @(posedge clk or posedge reset) begin
        if (reset)
            cnt <= 0;
        else if (cnt == PERIOD-1)
            cnt <= 0;
        else
            cnt <= cnt + 1;
    end

    assign tick = (cnt == PERIOD-1);

endmodule
