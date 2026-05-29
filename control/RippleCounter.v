// ----------------------------------------------------------------------------
// Module:      RippleCounter
// Description: Parameterized N-bit asynchronous (ripple) up counter. Each
//              flip-flop stage is clocked by the previous stage's inverted
//              output, NOT by a shared clock. Educational/historical — has
//              gate-delay skew between bits and is not recommended for real
//              designs. Use UpCounter for a synchronous alternative.
// Parameters:  WIDTH - counter width in bits (default 4)
// Ports:       clk   - input clock (rising edge, drives only the LSB stage)
//              reset - asynchronous reset, active high (forces Q to 0)
//              Q     - WIDTH-bit count output
// Author:      Amr Said
// Date:        2026-05-14
// ----------------------------------------------------------------------------
module RippleCounter #(
    parameter WIDTH = 4
)(
    input              clk,
    input              reset,
    output [WIDTH-1:0] Q
);

    wire [WIDTH-1:0] Qn_internal;

    // Stage 0: clocked directly by the external clock
    TFlipFlopPosEdgeActHigh TFF0 (
        .T(1'b1), .clk(clk),              .reset(reset),
        .Q(Q[0]), .Qn(Qn_internal[0])
    );

    // Stages 1..WIDTH-1: each clocked by the previous stage's Qn
    genvar i;
    generate
        for (i = 1; i < WIDTH; i = i + 1) begin : ripple_stage
            TFlipFlopPosEdgeActHigh TFF (
                .T(1'b1), .clk(Qn_internal[i-1]), .reset(reset),
                .Q(Q[i]), .Qn(Qn_internal[i])
            );
        end
    endgenerate
    // Qn_internal[WIDTH-1] is intentionally unused (top stage's complement).

endmodule

module TFlipFlopPosEdgeActHigh(
    input  T,
    input  clk,
    input  reset,
    output reg Q,
    output Qn
);
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            Q <= 1'b0;
        end else if (T) begin
            Q <= ~Q;
        end
    end

    assign Qn = ~Q;
endmodule