// ----------------------------------------------------------------------------
// Module:      PWMCounter_tb
// Description: Self-checking testbench for PWM counter. Sweeps duty from 0 to
//              PERIOD, measures high-cycle count per period, and tests
//              asynchronous reset mid-period.
// DUT:         PWMCounter
// Author:      Amr Said
// Date:        2026-05-26
// ----------------------------------------------------------------------------
`timescale 1ns/1ps

module PWMCounter_tb();
    parameter PERIOD = 16;
    parameter WIDTH  = 4;

    reg              clk, reset;
    reg  [WIDTH:0]   duty;                       // WIDTH+1 bits: holds 0..PERIOD
    wire             pwm;

    PWMCounter #(.PERIOD(PERIOD), .WIDTH(WIDTH)) DUT (
        .clk(clk), .reset(reset), .duty(duty), .pwm(pwm)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    integer errors;
    integer high_count, low_count;
    integer i;

    // Measure one full PWM period: sample pwm after each of PERIOD posedges,
    // and assert the high-cycle count equals the expected duty.
    task automatic measure_period;
        input integer expected_high;
        integer        k;
        begin
            high_count = 0;
            low_count  = 0;
            for (k = 0; k < PERIOD; k = k + 1) begin
                @(posedge clk); #1;
                if (pwm) high_count = high_count + 1;
                else     low_count  = low_count  + 1;
            end
            if (high_count != expected_high) begin
                $display("ERROR: duty=%0d -> high=%0d low=%0d (expected high=%0d)",
                         expected_high, high_count, low_count, expected_high);
                errors = errors + 1;
            end
        end
    endtask

    // Clean reset assert + release between sweep entries.
    task automatic do_reset;
        begin
            @(negedge clk) reset = 1;
            repeat (2) @(posedge clk);
            @(negedge clk) reset = 0;
        end
    endtask

    initial begin
        $dumpfile("PWMCounter_tb.vcd");
        $dumpvars(0, PWMCounter_tb);
        errors = 0;

        reset = 1;
        duty  = 0;
        repeat (2) @(posedge clk);
        @(negedge clk) reset = 0;

        // ---- Tests 1..5 collapse into one duty sweep 0..PERIOD ----
        //   duty=0           -> high=0           (always low)
        //   duty=1           -> high=1
        //   duty=PERIOD/2    -> high=PERIOD/2    (50%)
        //   duty=PERIOD-1    -> high=PERIOD-1    (one low cycle per period)
        //   duty=PERIOD      -> high=PERIOD      (always high)
        for (i = 0; i <= PERIOD; i = i + 1) begin
            do_reset;
            duty = i;
            measure_period(i);
        end
        $display("OK: duty sweep 0..%0d complete", PERIOD);

        // ---- Test 6: async reset mid-period, then verify a clean fresh period ----
        do_reset;
        duty = PERIOD / 2;
        repeat (PERIOD / 4) @(posedge clk);      // run partway through a period
        @(negedge clk) reset = 1; #1;            // async reset mid-period
        @(negedge clk) reset = 0;                // release
        measure_period(PERIOD / 2);              // a full clean period follows
        $display("OK: async reset mid-period followed by clean cycle");

        if (errors == 0) $display("PASS: self-check clean");
        else             $display("FAIL: %0d errors", errors);
        $finish;
    end

endmodule