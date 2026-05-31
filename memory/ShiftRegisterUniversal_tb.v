// ----------------------------------------------------------------------------
// Module:      ShiftRegisterUniversal_tb
// Description: Self-checking testbench for universal shift register.
// DUT:         ShiftRegisterUniversal #(.WIDTH(8))
//              Ports: clk, reset, mode [1:0], serial_left, serial_right,
//                     D [WIDTH-1:0] -> Q [WIDTH-1:0]
//              mode: 00=hold, 01=shift-right, 10=shift-left, 11=load
// Author:      Amr Said
// Date:        2026-05-31
// ----------------------------------------------------------------------------
`timescale 1ns/1ps

module ShiftRegisterUniversal_tb();
    parameter WIDTH = 8;

    reg              clk, reset, serial_left, serial_right;
    reg  [1:0]       mode;
    reg  [WIDTH-1:0] D;
    wire [WIDTH-1:0] Q;
    integer          errors = 0;

    // DUT instantiation
    ShiftRegisterUniversal #(.WIDTH(WIDTH)) DUT (
        .clk(clk), .reset(reset), .mode(mode),
        .serial_left(serial_left), .serial_right(serial_right),
        .D(D), .Q(Q)
    );

    // Clock generation: 10ns period
    initial clk = 1'b0;
    always #5 clk = ~clk;

    // Independent reference model: case on mode
    reg [WIDTH-1:0] ref_q;
    always @(posedge clk or posedge reset) begin
        if (reset) ref_q <= {WIDTH{1'b0}};
        else case (mode)
            2'b01: ref_q <= {serial_right, ref_q[WIDTH-1:1]};  // shift right
            2'b10: ref_q <= {ref_q[WIDTH-2:0], serial_left};   // shift left
            2'b11: ref_q <= D;                                 // parallel load
            default: ref_q <= ref_q;                           // 2'b00 hold
        endcase
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

    integer k;
    initial begin
        $dumpfile("ShiftRegisterUniversal_tb.vcd");
        $dumpvars(0, ShiftRegisterUniversal_tb);

        mode = 2'b00; D = 8'h00; serial_left = 1'b0; serial_right = 1'b0; reset = 1'b1;

        // T1: reset -> Q == 0
        repeat (2) @(posedge clk); #1;
        check("T1_reset");
        @(negedge clk) reset = 1'b0;

        // T2: parallel load (mode=11)
        mode = 2'b11; D = 8'hA5;
        @(posedge clk); #1; check("T2_load_A5");

        // T3: hold (mode=00) -> Q must not change even as D/serials change
        mode = 2'b00; D = 8'hFF; serial_left = 1'b1; serial_right = 1'b1;
        @(posedge clk); #1; check("T3_hold_1");
        @(posedge clk); #1; check("T3_hold_2");

        // T4: shift left (mode=10) with varying serial_left
        mode = 2'b10;
        serial_left = 1'b1; @(posedge clk); #1; check("T4_shl_in1");
        serial_left = 1'b0; @(posedge clk); #1; check("T4_shl_in0");
        serial_left = 1'b1; @(posedge clk); #1; check("T4_shl_in1b");

        // T5: shift right (mode=01) with varying serial_right
        mode = 2'b01;
        serial_right = 1'b1; @(posedge clk); #1; check("T5_shr_in1");
        serial_right = 1'b0; @(posedge clk); #1; check("T5_shr_in0");
        serial_right = 1'b1; @(posedge clk); #1; check("T5_shr_in1b");

        // T6: mode transitions: load -> shift left -> hold -> shift right
        mode = 2'b11; D = 8'h81; @(posedge clk); #1; check("T6_load_81");
        mode = 2'b10; serial_left = 1'b0; @(posedge clk); #1; check("T6_then_shl");
        mode = 2'b00; @(posedge clk); #1; check("T6_then_hold");
        mode = 2'b01; serial_right = 1'b1; @(posedge clk); #1; check("T6_then_shr");

        // T7: async reset from a non-zero state
        mode = 2'b11; D = 8'hFF; @(posedge clk); #1; check("T7_preload_FF");
        #2 reset = 1'b1;
        #1 check("T7_async_reset");
        @(negedge clk) reset = 1'b0;

        #10;
        if (errors == 0) $display("=== ALL TESTS PASSED ===");
        else             $display("=== %0d FAILURE(S) ===", errors);
        $finish;
    end

endmodule
