// ----------------------------------------------------------------------------
// Module:      ShiftRegisterPISO_tb
// Description: Self-checking testbench for parallel-in serial-out shift register.
// DUT:         ShiftRegisterPISO #(.WIDTH(8))
//              Ports: clk, reset, load_en, D [WIDTH-1:0] -> serial_out
// Author:      Amr Said
// Date:        2026-05-31
// ----------------------------------------------------------------------------
`timescale 1ns/1ps

module ShiftRegisterPISO_tb();
    parameter WIDTH = 8;

    reg              clk, reset, load_en;
    reg  [WIDTH-1:0] D;
    wire             serial_out;
    integer          errors = 0;
    integer          k;

    // DUT instantiation
    ShiftRegisterPISO #(.WIDTH(WIDTH)) DUT (
        .clk(clk), .reset(reset), .load_en(load_en), .D(D), .serial_out(serial_out)
    );

    // Clock generation: 10ns period
    initial clk = 1'b0;
    always #5 clk = ~clk;

    // Independent reference model:
    //   ref = load_en ? D : {ref[WIDTH-2:0], 1'b0};  serial_out = MSB
    reg [WIDTH-1:0] ref_sr;
    always @(posedge clk or posedge reset) begin
        if (reset)        ref_sr <= {WIDTH{1'b0}};
        else if (load_en) ref_sr <= D;
        else              ref_sr <= {ref_sr[WIDTH-2:0], 1'b0};
    end

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
        $dumpfile("ShiftRegisterPISO_tb.vcd");
        $dumpvars(0, ShiftRegisterPISO_tb);

        load_en = 1'b0; D = 8'h00; reset = 1'b1;

        // T1: reset -> serial_out 0
        repeat (2) @(posedge clk); #1;
        check("T1_reset");
        @(negedge clk) reset = 1'b0;

        // T2: load 0xA5 then shift out 8 bits, MSB-first: 1,0,1,0,0,1,0,1
        load_en = 1'b1; D = 8'hA5;
        @(posedge clk); #1; check("T2_load_A5");     // serial_out now = bit7 = 1
        load_en = 1'b0; D = 8'h00;
        for (k = 0; k < WIDTH-1; k = k + 1) begin
            @(posedge clk); #1;
            check("T2_shift_out");
        end

        // T3: load overrides shift mid-stream
        load_en = 1'b1; D = 8'h3C;
        @(posedge clk); #1; check("T3_reload_3C");
        load_en = 1'b0;
        @(posedge clk); #1; check("T3_after_reload_shift");

        // T4: zero-fill -> after all bits shifted out, serial_out stays 0
        for (k = 0; k < WIDTH; k = k + 1) begin
            @(posedge clk); #1;
            check("T4_zero_fill");
        end

        // T5: async reset from a loaded (non-zero) state
        load_en = 1'b1; D = 8'hFF;
        @(posedge clk); #1; check("T5_preload_FF");
        #2 reset = 1'b1;
        #1 check("T5_async_reset");
        @(negedge clk) reset = 1'b0;

        #10;
        if (errors == 0) $display("=== ALL TESTS PASSED ===");
        else             $display("=== %0d FAILURE(S) ===", errors);
        $finish;
    end

endmodule
