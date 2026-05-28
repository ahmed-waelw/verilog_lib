// ----------------------------------------------------------------------------
// Module:      PWMCounter
// Description: Pulse-width modulator. Free-running counter compared against a
//              `duty` threshold to produce a PWM output. Output is high while
//              cnt < duty, low otherwise.
// Parameters:  PERIOD - PWM period in clock cycles (default 256)
//              WIDTH  - duty / counter width in bits (must hold PERIOD-1)
// Ports:       clk   - input clock (rising edge)
//              reset - asynchronous reset, active high (forces count to 0)
//              duty  - (WIDTH+1)-bit duty-cycle threshold (0 = always low,
//                      PERIOD = always high)
//              pwm   - PWM output
// Author:      Amr Said
// Date:        2026-05-14
// ----------------------------------------------------------------------------
module PWMCounter #(
    parameter PERIOD = 256,
    parameter WIDTH  = 8
)(
    input              clk,
    input              reset,
    input  [WIDTH:0]   duty,
    output             pwm
);

    reg [WIDTH-1:0] cnt;

    always @(posedge clk or posedge reset) begin
        if (reset)
            cnt <= 0;
        else if (cnt == PERIOD-1)
            cnt <= 0;
        else
            cnt <= cnt + 1;
    end

    assign pwm = (cnt < duty);

endmodule