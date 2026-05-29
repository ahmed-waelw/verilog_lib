// ----------------------------------------------------------------------------
// Module:      BarrelShifter
// Description: Parameterized WIDTH-bit barrel shifter. Shifts or rotates D by
//              `amount` positions per clock, in the direction set by `dir`.
//              Combinational — operation completes in one cycle for any
//              amount.
// Parameters:  WIDTH - data width in bits (default 8)
//              SHIFT_BITS - $clog2(WIDTH) (default 3)
// Ports:       D      - WIDTH-bit data input
//              amount - shift count (SHIFT_BITS bits)
//              dir    - direction: 0 = shift left, 1 = shift right
//              mode   - 0 = logical shift, 1 = rotate
//              Y      - WIDTH-bit shifted/rotated output
// Author:      Amr Said
// Date:        2026-05-14
// ----------------------------------------------------------------------------
module BarrelShifter #(
    parameter WIDTH      = 8,
    parameter SHIFT_BITS = 3
)(
    input  [WIDTH-1:0]       D,
    input  [SHIFT_BITS-1:0]  amount,
    input                    dir,
    input                    mode,
    output reg [WIDTH-1:0]   Y
);

    always @(*) begin
        case ({dir, mode})
            2'b00: Y = D <<  amount;                              // logical left
            2'b01: Y = (D << amount) | (D >> (WIDTH - amount));   // rotate left
            2'b10: Y = D >>  amount;                              // logical right
            2'b11: Y = (D >> amount) | (D << (WIDTH - amount));   // rotate right
        endcase
    end

endmodule
