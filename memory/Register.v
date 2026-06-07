// ----------------------------------------------------------------------------
// Module:      Register
// Description: N-bit parallel-load register with synchronous load enable and
//              asynchronous reset. The fundamental "store this value" block.
// Parameters:  WIDTH - data width in bits (default 8)
// Ports:       clk     - input clock (rising edge)
//              reset   - asynchronous reset, active high (forces Q to 0)
//              load_en - synchronous load enable, active high
//              D       - WIDTH-bit data input
//              Q       - WIDTH-bit registered output
// Author:      Amr Said
// Date:        2026-06-07
// ----------------------------------------------------------------------------
module Register #(
    parameter WIDTH = 8
)(
    input                  clk,
    input                  reset,
    input                  load_en,
    input  [WIDTH-1:0]     D,
    output reg [WIDTH-1:0] Q
);

    always @(posedge clk or posedge reset) begin
        if (reset)
            Q <= 0;
        else if (load_en)
            Q <= D;
    end

endmodule
