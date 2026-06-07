// ----------------------------------------------------------------------------
// Module:      ShiftRegisterPIPO_tb
// Description: Self-checking testbench for parallel-in parallel-out register.
// DUT:         ShiftRegisterPIPO #(.WIDTH(8))
//              Ports: clk, reset, load_en, D [WIDTH-1:0] -> Q [WIDTH-1:0]
// Author:      Amr Said
// Date:        2026-06-07
// ----------------------------------------------------------------------------
`timescale 1ns/1ps

module ShiftRegisterPIPO_tb();
    parameter WIDTH = 8;

    reg              clk, reset, load_en;
    reg  [WIDTH-1:0] D;
    wire [WIDTH-1:0] Q;
    integer          errors = 0;

    // DUT instantiation
    ShiftRegisterPIPO #(.WIDTH(WIDTH)) DUT (
        .clk(clk), .reset(reset), .load_en(load_en), .D(D), .Q(Q)
    );

    // Clock generation: 10ns period
    initial clk = 1'b0;
    always #5 clk = ~clk;

    // Independent reference model (async reset, sync load)
    reg [WIDTH-1:0] ref_q;
    always @(posedge clk or posedge reset) begin
        if (reset)        ref_q <= {WIDTH{1'b0}};
        else if (load_en) ref_q <= D;
    end

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
        $dumpfile("ShiftRegisterPIPO_tb.vcd");
        $dumpvars(0, ShiftRegisterPIPO_tb);

        load_en = 1'b0; D = 8'h00; reset = 1'b1;

        // T1: reset -> Q == 0
        repeat (2) @(posedge clk); #1;
        check("T1_reset");
        @(negedge clk) reset = 1'b0;

        // T2: load -> Q captures D
        load_en = 1'b1;
        D = 8'h3C; @(posedge clk); #1; check("T2_load_3C");

        // T3: hold -> Q unchanged when load_en=0
        load_en = 1'b0;
        D = 8'hFF; @(posedge clk); #1; check("T3_hold_1");
        D = 8'h00; @(posedge clk); #1; check("T3_hold_2");

        // T4: multiple loads in succession
        load_en = 1'b1;
        D = 8'h0F; @(posedge clk); #1; check("T4_load_0F");
        D = 8'hF0; @(posedge clk); #1; check("T4_load_F0");
        D = 8'hAA; @(posedge clk); #1; check("T4_load_AA");

        // T5: async reset from a non-zero value
        #2 reset = 1'b1;
        #1 check("T5_async_reset");
        @(negedge clk) reset = 1'b0;
        D = 8'h55; @(posedge clk); #1; check("T5_recover_load_55");
        load_en = 1'b0;

        #10;
        if (errors == 0) $display("=== ALL TESTS PASSED ===");
        else             $display("=== %0d FAILURE(S) ===", errors);
        $finish;
    end

endmodule
