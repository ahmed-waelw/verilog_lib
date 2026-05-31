// ----------------------------------------------------------------------------
// Module:      ShiftRegisterPISO
// Description: Parallel-In Serial-Out shift register. Loads a parallel value
//              when load_en is high; otherwise shifts the value out one bit
//              per clock on serial_out.
// Parameters:  WIDTH - register width in bits (default 8)
// Ports:       clk         - input clock (rising edge)
//              reset       - asynchronous reset, active high (clears register)
//              load_en     - synchronous parallel-load enable (priority over shift)
//              D           - WIDTH-bit parallel data input
//              serial_out  - bit shifted out at MSB end
// Author:      Amr Said
// Date:        2026-05-14
// ----------------------------------------------------------------------------
module ShiftRegisterPISO #(
    parameter WIDTH = 8
)(
    input              clk,
    input              reset,
    input              load_en,
    input  [WIDTH-1:0] D,
    output             serial_out
);
    reg [WIDTH-1:0] shift_reg;

    always @(posedge clk or posedge reset) begin
        if (reset)
            shift_reg <= 0;
        else if (load_en)
            shift_reg <= D;
        else
            shift_reg <= {shift_reg[WIDTH-2:0], 1'b0};
    end

    assign serial_out = shift_reg[WIDTH-1];

endmodule
