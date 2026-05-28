// ----------------------------------------------------------------------------
// Module:      LFSR
// Description: Linear-Feedback Shift Register — pseudo-random count sequence
//              produced by XOR feedback taps. Used for noise generation, CRC,
//              scramblers, and BIST patterns. Default configuration is a
//              maximal-length 4-bit LFSR (taps at bits 3 and 2).
// Parameters:  WIDTH - shift register width in bits (default 4)
//              TAPS  - tap mask, one bit per stage (default 4'b1100 for max-len)
//              SEED  - non-zero initial state on reset (default 4'b0001)
// Ports:       clk   - input clock (rising edge)
//              reset - asynchronous reset, active high (loads SEED)
//              Q     - WIDTH-bit pseudo-random output
// Author:      Amr Said
// Date:        2026-05-14
// ----------------------------------------------------------------------------
module LFSR #(
    parameter WIDTH = 4,
    parameter [WIDTH-1:0] TAPS = 4'b1100,
    parameter [WIDTH-1:0] SEED = 4'b0001
)(
    input  clk,
    input  reset,
    output reg [WIDTH-1:0] Q
);
    always @(posedge clk or posedge reset) begin
        if (reset)
            Q <= SEED;
        else
            Q <= {Q[WIDTH-2:0], ^(Q & TAPS)};    // shift, XOR-tap feedback into LSB
    end

endmodule
