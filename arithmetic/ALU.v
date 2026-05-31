// ----------------------------------------------------------------------------
// Module:      ALU
// Description: Parameterized N-bit arithmetic and logic unit. Performs one
//              of 16 operations selected by `op`, producing a WIDTH-bit
//              result plus status flags.
//              Suggested op map (customize as you like):
//                  4'h0 ADD   A + B
//                  4'h1 SUB   A - B
//                  4'h2 AND   A & B
//                  4'h3 OR    A | B
//                  4'h4 XOR   A ^ B
//                  4'h5 NOT   ~A
//                  4'h6 SLL   A << B[clog2(WIDTH)-1:0]
//                  4'h7 SRL   A >> B[clog2(WIDTH)-1:0]
//                  4'h8 SRA   A >>> B   (arithmetic right shift)
//                  4'h9 SLT   signed (A < B) ? 1 : 0
//                  4'hA SLTU  unsigned (A < B) ? 1 : 0
//                  4'hB EQ    (A == B) ? 1 : 0
//                  4'hC NEQ   (A != B) ? 1 : 0
//                  4'hD PASS  A
//                  4'hE INC   A + 1
//                  4'hF DEC   A - 1
// Parameters:  WIDTH - operand width in bits (default 8)
// Ports:       A        - operand A
//              B        - operand B
//              op       - 4-bit operation select
//              result   - WIDTH-bit ALU result
//              zero     - high when result == 0
//              negative - high when result MSB == 1
//              carry    - carry-out of last ADD/SUB
//              overflow - signed overflow on ADD/SUB
// Author:      Amr Said
// Date:        2026-05-14
// ----------------------------------------------------------------------------
`timescale 1ns/1ps
module ALU #(
    parameter WIDTH = 8
)(
    input      [WIDTH-1:0] A,
    input      [WIDTH-1:0] B,
    input      [3:0]       op,
    output reg [WIDTH-1:0] result,
    output                 zero,
    output                 negative,
    output reg             carry,
    output reg             overflow
);
se
    localparam SHAMT_WIDTH = $clog2(WIDTH);
    wire signed [WIDTH-1:0] A_signed = A;

    always @(*) begin
        // Default assignments to avoid latches
        result   = {WIDTH{1'b0}};
        carry    = 1'b0;
        overflow = 1'b0;

        case (op)
            // --- Arithmetic ---
            4'h0: begin // ADD
                {carry, result} = A + B;
                overflow = (A[WIDTH-1] == B[WIDTH-1]) && (result[WIDTH-1] != A[WIDTH-1]);
            end
            4'h1: begin // SUB
                {carry, result} = A - B;
                overflow = (A[WIDTH-1] != B[WIDTH-1]) && (result[WIDTH-1] != A[WIDTH-1]);
            end
            4'hE: begin // INC
                {carry, result} = A + 1'b1;
                overflow = (A[WIDTH-1] == 1'b0) && (result[WIDTH-1] == 1'b1);
            end
            4'hF: begin // DEC
                {carry, result} = A - 1'b1;
                overflow = (A[WIDTH-1] == 1'b1) && (result[WIDTH-1] == 1'b0);
            end

            // --- Logical ---
            4'h2: result = A & B;   // AND
            4'h3: result = A | B;   // OR
            4'h4: result = A ^ B;   // XOR
            4'h5: result = ~A;      // NOT

            // --- Shifts ---
            4'h6: result = A << B[SHAMT_WIDTH-1:0];                // SLL
            4'h7: result = A >> B[SHAMT_WIDTH-1:0];                // SRL
            4'h8: result = A[WIDTH-1] ? ~((~A) >> B[SHAMT_WIDTH-1:0]) : ( A     >> B[SHAMT_WIDTH-1:0]);            // --- Comparisons ---
            4'h9: result = ($signed(A) < $signed(B)) ? 1 : 0;      // SLT
            4'hA: result = (A < B) ? 1 : 0;                        // SLTU
            4'hB: result = (A == B) ? 1 : 0;                       // EQ
            4'hC: result = (A != B) ? 1 : 0;                       // NEQ

            // --- Pass Through ---
            4'hD: result = A;                                      // PASS

            default: result = {WIDTH{1'b0}};
        endcase
    end

    assign zero     = (result == {WIDTH{1'b0}});
    assign negative = result[WIDTH-1];

endmodule
