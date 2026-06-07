// ----------------------------------------------------------------------------
// Module:      Register_tb
// Description: Self-checking testbench for parameterized parallel-load register.
// DUT:         Register #(.WIDTH(8))
//              Ports: clk, reset, load_en, D [WIDTH-1:0] -> Q [WIDTH-1:0]
// Author:      Amr Said
// Date:        2026-06-07
// ----------------------------------------------------------------------------
`timescale 1ns/1ps

module Register_tb();
    parameter WIDTH = 8;

    reg              clk, reset, load_en;
    reg  [WIDTH-1:0] D;
    wire [WIDTH-1:0] Q;
    integer          errors = 0;

    // DUT instantiation
    Register #(.WIDTH(WIDTH)) DUT (
        .clk(clk), .reset(reset), .load_en(load_en), .D(D), .Q(Q)
    );

    // Clock generation: 10ns period
    initial clk = 1'b0;
    always #5 clk = ~clk;

    // Independent reference model (shadow register: async reset, sync load)
    reg [WIDTH-1:0] ref_q;
    always @(posedge clk or posedge reset) begin
        if (reset)        ref_q <= {WIDTH{1'b0}};
        else if (load_en) ref_q <= D;
    end

    // Compare DUT output against the reference model
    task check;
        input [255:0] label;
        begin
            if (Q !== ref_q) begin
                $display("[%0t] FAIL %0s: expected Q=%h, got Q=%h", $time, label, ref_q, Q);
                errors = errors + 1;
            end else begin
                $display("[%0t] PASS %0s: Q=%h", $time, label, Q);
            end
        end
    endtask

    initial begin
        $dumpfile("Register_tb.vcd");
        $dumpvars(0, Register_tb);

        // T1: reset -> Q must be 0
        D = 8'h00; load_en = 1'b0; reset = 1'b1;
        repeat (2) @(posedge clk); #1;
        check("T1_reset");
        @(negedge clk) reset = 1'b0;

        // T2: load several values
        load_en = 1'b1;
        D = 8'hA5; @(posedge clk); #1; check("T2_load_A5");
        D = 8'h3C; @(posedge clk); #1; check("T2_load_3C");
        D = 8'hFF; @(posedge clk); #1; check("T2_load_FF");

        // T3: hold (load_en=0) -> Q must not change when D changes
        load_en = 1'b0;
        D = 8'h00; @(posedge clk); #1; check("T3_hold_after_FF_1");
        D = 8'h5A; @(posedge clk); #1; check("T3_hold_after_FF_2");

        // T4: async reset from a non-zero value, asserted between edges
        load_en = 1'b1; D = 8'h77; @(posedge clk); #1; check("T4_preload_77");
        #2 reset = 1'b1;                 // async assert, no clock edge
        #1 check("T4_async_reset_clears_Q");
        @(negedge clk) reset = 1'b0;

        // T5: recovery -> load resumes after reset release
        D = 8'h81; @(posedge clk); #1; check("T5_recover_load_81");
        load_en = 1'b0;

        #10;
        if (errors == 0) $display("=== ALL TESTS PASSED ===");
        else             $display("=== %0d FAILURE(S) ===", errors);
        $finish;
    end

endmodule
