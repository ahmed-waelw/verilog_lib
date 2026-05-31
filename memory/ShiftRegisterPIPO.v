// ----------------------------------------------------------------------------
// Module:      ShiftRegisterPIPO
// Description: Parallel-In Parallel-Out register. Functionally identical to
//              a basic Register — included here for completeness of the
//              SISO / SIPO / PISO / PIPO family.
// Parameters:  WIDTH - data width in bits (default 8)
// Ports:       clk     - input clock (rising edge)
//              reset   - asynchronous reset, active high (clears register)
//              load_en - synchronous load enable
//              D       - WIDTH-bit parallel data input
//              Q       - WIDTH-bit parallel data output
// Author:      Amr Said
// Date:        2026-05-14
// ----------------------------------------------------------------------------
module ShiftRegisterPIPO #(
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
