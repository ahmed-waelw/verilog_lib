// ----------------------------------------------------------------------------
// Module:      ShiftRegisterSIPO_tb
// Description: Self-checking testbench for serial-in parallel-out shift register.
// DUT:         ShiftRegisterSIPO #(.WIDTH(8))
//              Ports: clk, reset, shift_en, serial_in -> Q [WIDTH-1:0]
// Author:      Amr Said
// Date:        2026-06-07
// ----------------------------------------------------------------------------
`timescale 1ns/1ps

module ShiftRegisterSIPO_tb();
    parameter WIDTH = 8;

    reg              clk, reset, shift_en, serial_in;
    wire [WIDTH-1:0] Q;
    integer          errors = 0;
    integer          k;
    reg [WIDTH-1:0]  pattern;

    // DUT instantiation
    ShiftRegisterSIPO #(.WIDTH(WIDTH)) DUT (
        .clk(clk), .reset(reset), .shift_en(shift_en),
        .serial_in(serial_in), .Q(Q)
    );

    // Clock generation: 10ns period
    initial clk = 1'b0;
    always #5 clk = ~clk;

    // Independent reference model: ref = {ref[WIDTH-2:0], serial_in} on shift_en
    reg [WIDTH-1:0] ref_q;
    always @(posedge clk or posedge reset) begin
        if (reset)         ref_q <= {WIDTH{1'b0}};
        else if (shift_en) ref_q <= {ref_q[WIDTH-2:0], serial_in};
    end

    task check;
        input [255:0] label;
        begin
            if (Q !== ref_q) begin
                $display("[%0t] FAIL %0s: expected Q=%b, got Q=%b", $time, label, ref_q, Q);
                errors = errors + 1;
            end else begin
                $display("[%0t] PASS %0s: Q=%b", $time, label, Q);
            end
        end
    endtask

    initial begin
        $dumpfile("ShiftRegisterSIPO_tb.vcd");
        $dumpvars(0, ShiftRegisterSIPO_tb);

        pattern  = 8'b1100_1011;     // known byte to shift in MSB-first
        shift_en = 1'b0; serial_in = 1'b0; reset = 1'b1;

        // T1: reset -> Q == 0
        repeat (2) @(posedge clk); #1;
        check("T1_reset");
        @(negedge clk) reset = 1'b0;

        // T2: shift in a known byte (8 clocks) -> Q should equal the byte
        shift_en = 1'b1;
        for (k = WIDTH-1; k >= 0; k = k - 1) begin
            serial_in = pattern[k];
            @(posedge clk); #1;
            check("T2_shift_in");
        end
        // after 8 shifts Q must equal the pushed pattern
        if (Q !== pattern) begin
            $display("[%0t] FAIL T2_byte_assembled: expected Q=%b, got Q=%b", $time, pattern, Q);
            errors = errors + 1;
        end else
            $display("[%0t] PASS T2_byte_assembled: Q=%b", $time, Q);

        // T3: hold (shift_en=0) for several clocks -> Q unchanged
        shift_en = 1'b0;
        serial_in = 1'b1;
        @(posedge clk); #1; check("T3_hold_1");
        @(posedge clk); #1; check("T3_hold_2");
        @(posedge clk); #1; check("T3_hold_3");

        // T4: async reset from a non-zero state
        shift_en = 1'b1; serial_in = 1'b1;
        @(posedge clk); #1; check("T4_preload");
        #2 reset = 1'b1;
        #1 check("T4_async_reset");
        @(negedge clk) reset = 1'b0;

        #10;
        if (errors == 0) $display("=== ALL TESTS PASSED ===");
        else             $display("=== %0d FAILURE(S) ===", errors);
        $finish;
    end

endmodule
