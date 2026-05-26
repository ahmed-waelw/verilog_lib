// ----------------------------------------------------------------------------
// Module:      Divider
// Description: Parameterized N-bit unsigned integer divider. Produces both
//              quotient and remainder. Sequential (multi-cycle) by nature —
//              use the `start` / `done` handshake.
//
//              Algorithm: restoring shift-and-subtract long division. Processes
//              the dividend one bit at a time, MSB-first, over WIDTH cycles.
//              Each cycle: shift the partial remainder left and pull in the next
//              dividend bit, compare against the divisor, and if it fits,
//              subtract and set the quotient bit to 1 (else 0).
//
// Parameters:  WIDTH - operand width in bits (default 8)
// Ports:       clk       - input clock (rising edge)
//              reset     - asynchronous reset, active high
//              start     - one-cycle pulse to begin a division
//              dividend  - WIDTH-bit dividend
//              divisor   - WIDTH-bit divisor (caller must ensure non-zero)
//              quotient  - WIDTH-bit quotient output (valid when done)
//              remainder - WIDTH-bit remainder output (valid when done)
//              done      - asserted high for one cycle when result is ready
// Author:      Amr Said
// Date:        2026-05-14
// ----------------------------------------------------------------------------
module Divider #(
    parameter WIDTH = 8
)(
    input                  clk,
    input                  reset,
    input                  start,
    input      [WIDTH-1:0] dividend,
    input      [WIDTH-1:0] divisor,
    output reg [WIDTH-1:0] quotient,
    output reg [WIDTH-1:0] remainder,
    output reg             done
);

    // State encoding for the control FSM
    localparam
        IDLE = 2'd0,   // waiting for `start`
        BUSY = 2'd1,   // running WIDTH iterations of shift-and-subtract
        DONE = 2'd2;   // result ready, latch outputs and assert `done`

    reg [1:0] state;

    // Working registers
    reg [WIDTH-1:0] dividend_reg;   // holds dividend; shifts left each step to
                                    //   expose the next bit at its MSB
    reg [WIDTH-1:0] quotient_reg;   // quotient built up one bit at a time (LSB-in)
    reg [WIDTH:0]   rem_reg;        // partial remainder. WIDTH+1 bits wide: the
                                    //   left-shift can push a 1 into bit WIDTH,
                                    //   and that bit must be preserved for the
                                    //   compare/subtract against `divisor` to be
                                    //   correct.
    reg [WIDTH:0]   rem_shifted;    // blocking temp: holds the freshly-shifted
                                    //   remainder so the compare/subtract below
                                    //   sees the NEW value, not last cycle's.

    localparam CNT_W = $clog2(WIDTH + 1);
    reg [CNT_W-1:0] count; // iteration counter, ranges 0 .. WIDTH

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            // Asynchronous reset: clear everything to a known idle state
            state     <= IDLE;
            done      <= 1'b0;
            quotient  <= 0;
            remainder <= 0;
        end
        else begin
            case (state)

                // ------------------------------------------------------------
                // IDLE: wait for a start pulse, then latch operands and begin
                // ------------------------------------------------------------
                IDLE: begin
                    done <= 1'b0;               // deassert done from prior run
                    if (start) begin
                        dividend_reg <= dividend; // load dividend
                        rem_reg      <= 0;        // clear partial remainder
                        quotient_reg <= 0;        // clear quotient accumulator
                        count        <= 0;        // reset iteration counter
                        state        <= BUSY;     // begin division
                    end
                end

                // ------------------------------------------------------------
                // BUSY: one iteration of restoring shift-and-subtract per clock.
                //   Runs WIDTH times, then transitions to DONE.
                // ------------------------------------------------------------
                BUSY: begin
                    // Step 1: shift remainder left, bringing in the current MSB
                    //   of the dividend. Blocking (=) so the value is available
                    //   immediately to the compare below this same cycle.
                    // Blocking (=) — intentional: rem_shifted is a same-cycle
                    // intermediate consumed by the comparison below.
                    rem_shifted = {rem_reg[WIDTH-1:0], dividend_reg[WIDTH-1]};

                    // Step 2: shift the dividend left so the next-most-significant
                    //   bit is exposed at its MSB for the next iteration.
                    dividend_reg <= {dividend_reg[WIDTH-2:0], 1'b0};

                    // Step 3: compare the shifted remainder against the divisor.
                    //   If it fits, subtract and record a 1 in the quotient;
                    //   otherwise leave the remainder and record a 0.
                    if (rem_shifted >= divisor) begin
                        rem_reg      <= rem_shifted - divisor;
                        quotient_reg <= (quotient_reg << 1) | 1'b1;
                    end
                    else begin
                        rem_reg      <= rem_shifted;
                        quotient_reg <= (quotient_reg << 1) | 1'b0;
                    end

                    // Step 4: advance the iteration counter.
                    count <= count + 1;

                    // Step 5: after the WIDTH-th iteration (count counts 0..WIDTH-1),
                    //   the result is complete — move to DONE.
                    if (count == WIDTH-1) begin
                        state <= DONE;
                    end
                end

                // ------------------------------------------------------------
                // DONE: latch the final results and raise `done` for one cycle,
                //   then return to IDLE ready for the next request.
                // ------------------------------------------------------------
                DONE: begin
                    quotient  <= quotient_reg;
                    remainder <= rem_reg[WIDTH-1:0];
                    done      <= 1'b1;
                    state     <= IDLE;
                end

                default: state <= IDLE;   // safety: recover from illegal state
            endcase
        end
    end

endmodule