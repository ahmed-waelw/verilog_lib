// ----------------------------------------------------------------------------
// Module:      ShiftRegisterUniversal
// Description: Universal shift register. The `mode` input selects one of four
//              operations per clock:
//                  mode = 2'b00 : hold
//                  mode = 2'b01 : shift right (serial_right -> MSB, LSB out)
//                  mode = 2'b10 : shift left  (serial_left  -> LSB, MSB out)
//                  mode = 2'b11 : parallel load from D
// Parameters:  WIDTH - register width in bits (default 8)
// Ports:       clk          - input clock (rising edge)
//              reset        - asynchronous reset, active high
//              mode         - 2-bit operation select (see truth table)
//              serial_left  - bit shifted in on shift-left
//              serial_right - bit shifted in on shift-right
//              D            - WIDTH-bit parallel data input
//              Q            - WIDTH-bit register output
// Author:      Amr Said
// Date:        2026-06-07
// ----------------------------------------------------------------------------
module ShiftRegisterUniversal #(
    parameter WIDTH = 8
)(
    input                  clk,
    input                  reset,
    input      [1:0]       mode,
    input                  serial_left,
    input                  serial_right,
    input      [WIDTH-1:0] D,
    output reg [WIDTH-1:0] Q
);
    always @(posedge clk or posedge reset) begin
        if (reset)
            Q <= 0;
        else case (mode)
            2'b01: Q <= {serial_right, Q[WIDTH-1:1]};   // shift right
            2'b10: Q <= {Q[WIDTH-2:0], serial_left};    // shift left
            2'b11: Q <= D;                              // parallel load
            // 2'b00 (hold) handled implicitly by no assignment
        endcase
    end

endmodule
