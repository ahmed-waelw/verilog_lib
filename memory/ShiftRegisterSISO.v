// ----------------------------------------------------------------------------
// Module:      ShiftRegisterSISO
// Description: Serial-In Serial-Out shift register. Shifts in a bit per clock
//              when shift_en is high; the bit that falls off the MSB end
//              appears on serial_out.
// Parameters:  WIDTH - internal register depth in bits (default 8)
// Ports:       clk         - input clock (rising edge)
//              reset       - asynchronous reset, active high (clears register)
//              shift_en    - synchronous shift enable
//              serial_in   - bit shifted in at LSB end
//              serial_out  - bit shifted out at MSB end
// Author:      Amr Said
// Date:        2026-05-14
// ----------------------------------------------------------------------------
module ShiftRegisterSISO #(
    parameter WIDTH = 8
)(
    input  clk,
    input  reset,
    input  shift_en,
    input  serial_in,
    output serial_out
);

    reg [WIDTH-1:0] shift_reg;

    always @(posedge clk or posedge reset) begin
        if (reset)
            shift_reg <= 0;
        else if (shift_en)
            shift_reg <= {shift_reg[WIDTH-2:0], serial_in};
    end

    assign serial_out = shift_reg[WIDTH-1];

endmodule
