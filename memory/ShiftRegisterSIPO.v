// ----------------------------------------------------------------------------
// Module:      ShiftRegisterSIPO
// Description: Serial-In Parallel-Out shift register. Shifts in one bit per
//              clock when shift_en is high; the full register contents are
//              visible as parallel output Q.
// Parameters:  WIDTH - register width in bits (default 8)
// Ports:       clk       - input clock (rising edge)
//              reset     - asynchronous reset, active high (clears register)
//              shift_en  - synchronous shift enable
//              serial_in - bit shifted in at LSB end
//              Q         - WIDTH-bit parallel output
// Author:      Amr Said
// Date:        2026-06-07
// ----------------------------------------------------------------------------
module ShiftRegisterSIPO #(
    parameter WIDTH = 8
)(
    input                  clk,
    input                  reset,
    input                  shift_en,
    input                  serial_in,
    output reg [WIDTH-1:0] Q
);

    always @(posedge clk or posedge reset) begin
        if (reset)
            Q <= 0;
        else if (shift_en)
            Q <= {Q[WIDTH-2:0], serial_in};
    end

endmodule
