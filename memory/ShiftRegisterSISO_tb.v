// ----------------------------------------------------------------------------
// Module:      ShiftRegisterSISO_tb
// Description: Self-checking testbench for serial-in serial-out shift register.
// DUT:         ShiftRegisterSISO #(.WIDTH(8))
//              Ports: clk, reset, shift_en, serial_in -> serial_out
// Author:      Amr Said
// Date:        2026-05-31
// ----------------------------------------------------------------------------
`timescale 1ns/1ps

module ShiftRegisterSISO_tb();
    parameter WIDTH = 8;

    reg  clk, reset, shift_en, serial_in;
    wire serial_out;
    integer errors = 0;
    integer k;
    reg [WIDTH-1:0] pattern;

    // DUT instantiation
    ShiftRegisterSISO #(.WIDTH(WIDTH)) DUT (
        .clk(clk), .reset(reset), .shift_en(shift_en),
        .serial_in(serial_in), .serial_out(serial_out)
    );

    // Clock generation: 10ns period
    initial clk = 1'b0;
    always #5 clk = ~clk;

    // Independent reference model: WIDTH-bit reg, shift-left on shift_en.
    // serial_out is the MSB of the register.
    reg [WIDTH-1:0] ref_sr;
    always @(posedge clk or posedge reset) begin
        if (reset)         ref_sr <= {WIDTH{1'b0}};
        else if (shift_en) ref_sr <= {ref_sr[WIDTH-2:0], serial_in};
    end

    // Compare DUT serial_out against reference MSB
    task check;
        input [255:0] label;
        begin
            if (serial_out !== ref_sr[WIDTH-1]) begin
                $display("[%0t] FAIL %0s: expected serial_out=%b, got %b (ref_sr=%b)",
                         $time, label, ref_sr[WIDTH-1], serial_out, ref_sr);
                errors = errors + 1;
            end else begin
                $display("[%0t] PASS %0s: serial_out=%b (ref_sr=%b)",
                         $time, label, serial_out, ref_sr);
            end
        end
    endtask

    initial begin
        $dumpfile("ShiftRegisterSISO_tb.vcd");
        $dumpvars(0, ShiftRegisterSISO_tb);

        pattern  = 8'b1011_0010;     // known byte to push in, MSB-first
        shift_en = 1'b0; serial_in = 1'b0; reset = 1'b1;

        // T1: reset -> serial_out 0
        repeat (2) @(posedge clk); #1;
        check("T1_reset");
        @(negedge clk) reset = 1'b0;

        // T2: shift in the known pattern MSB-first
        shift_en = 1'b1;
        for (k = WIDTH-1; k >= 0; k = k - 1) begin
            serial_in = pattern[k];
            @(posedge clk); #1;
            check("T2_shift_in");
        end

        // T3: hold (shift_en=0) -> serial_out must not change
        shift_en = 1'b0;
        serial_in = 1'b1;            // toggling input must be ignored
        @(posedge clk); #1; check("T3_hold_1");
        serial_in = 1'b0;
        @(posedge clk); #1; check("T3_hold_2");

        // T4: full shift-through -> push 8 zeros, original bits exit MSB-first
        shift_en = 1'b1; serial_in = 1'b0;
        for (k = 0; k < WIDTH; k = k + 1) begin
            @(posedge clk); #1;
            check("T4_shift_through");
        end

        // T5: async reset from a non-zero state
        shift_en = 1'b1; serial_in = 1'b1;
        @(posedge clk); #1; check("T5_preload_ones");
        #2 reset = 1'b1;
        #1 check("T5_async_reset");
        @(negedge clk) reset = 1'b0;

        #10;
        if (errors == 0) $display("=== ALL TESTS PASSED ===");
        else             $display("=== %0d FAILURE(S) ===", errors);
        $finish;
    end

endmodule
