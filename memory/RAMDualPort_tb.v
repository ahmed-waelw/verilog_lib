// ----------------------------------------------------------------------------
// Module:      RAMDualPort_tb
// Description: Self-checking testbench for true dual-port synchronous RAM.
// DUT:         RAMDualPort #(.WIDTH(8), .DEPTH(16))
//              Ports: clk_a, we_a, addr_a, din_a -> dout_a
//                     clk_b, we_b, addr_b, din_b -> dout_b
// Author:      Amr Said
// Date:        2026-06-07
// ----------------------------------------------------------------------------
`timescale 1ns/1ps

module RAMDualPort_tb();
    parameter WIDTH = 8;
    parameter DEPTH = 16;
    localparam AW = $clog2(DEPTH);

    reg              clk_a, we_a, clk_b, we_b;
    reg  [AW-1:0]    addr_a, addr_b;
    reg  [WIDTH-1:0] din_a, din_b;
    wire [WIDTH-1:0] dout_a, dout_b;
    integer          errors = 0;
    integer          i;

    // DUT instantiation (DEPTH=16)
    RAMDualPort #(.WIDTH(WIDTH), .DEPTH(DEPTH)) DUT (
        .clk_a(clk_a), .we_a(we_a), .addr_a(addr_a), .din_a(din_a), .dout_a(dout_a),
        .clk_b(clk_b), .we_b(we_b), .addr_b(addr_b), .din_b(din_b), .dout_b(dout_b)
    );

    // Independent clocks: port A = 10ns, port B = 14ns
    initial clk_a = 1'b0;
    always #5 clk_a = ~clk_a;
    initial clk_b = 1'b0;
    always #7 clk_b = ~clk_b;

    // Independent reference model: one shared shadow memory, two registered
    // outputs each modelled on its own port clock with read-first semantics.
    reg [WIDTH-1:0] ref_mem [0:DEPTH-1];
    reg [WIDTH-1:0] ref_dout_a, ref_dout_b;
    always @(posedge clk_a) begin
        if (we_a) ref_mem[addr_a] <= din_a;
        ref_dout_a <= ref_mem[addr_a];
    end
    always @(posedge clk_b) begin
        if (we_b) ref_mem[addr_b] <= din_b;
        ref_dout_b <= ref_mem[addr_b];
    end

    // Continuous auto-checkers: verify each port's output every cycle.
    always @(posedge clk_a) #1 begin
        if (dout_a !== ref_dout_a) begin
            $display("[%0t] FAIL port A: expected dout_a=%h, got %h", $time, ref_dout_a, dout_a);
            errors = errors + 1;
        end
    end
    always @(posedge clk_b) #1 begin
        if (dout_b !== ref_dout_b) begin
            $display("[%0t] FAIL port B: expected dout_b=%h, got %h", $time, ref_dout_b, dout_b);
            errors = errors + 1;
        end
    end

    // milestone check helper (cross-port visibility, explicit value)
    task expect_val;
        input [WIDTH-1:0] got;
        input [WIDTH-1:0] exp;
        input [255:0]     label;
        begin
            if (got !== exp) begin
                $display("[%0t] FAIL %0s: expected %h, got %h", $time, label, exp, got);
                errors = errors + 1;
            end else begin
                $display("[%0t] PASS %0s: %h", $time, label, got);
            end
        end
    endtask

    initial begin
        $dumpfile("RAMDualPort_tb.vcd");
        $dumpvars(0, RAMDualPort_tb);

        we_a = 1'b0; addr_a = 0; din_a = 0;
        we_b = 1'b0; addr_b = 0; din_b = 0;

        // ---- Phase 1: Port A write, Port A read ----
        @(negedge clk_a); we_a = 1'b1; addr_a = 4'd3; din_a = 8'hC3;
        @(negedge clk_a); we_a = 1'b0; addr_a = 4'd3;
        @(negedge clk_a); #1; expect_val(dout_a, 8'hC3, "P1_A_write_read_addr3");

        // ---- Phase 2: Port B write, Port B read ----
        @(negedge clk_b); we_b = 1'b1; addr_b = 4'd10; din_b = 8'h5A;
        @(negedge clk_b); we_b = 1'b0; addr_b = 4'd10;
        @(negedge clk_b); #1; expect_val(dout_b, 8'h5A, "P2_B_write_read_addr10");

        // ---- Phase 3: cross-port — write via A, read via B ----
        @(negedge clk_a); we_a = 1'b1; addr_a = 4'd6; din_a = 8'h7E;
        @(negedge clk_a); we_a = 1'b0;
        // give port B a couple of its own cycles, then read addr 6
        @(negedge clk_b); we_b = 1'b0; addr_b = 4'd6;
        @(negedge clk_b);
        @(negedge clk_b); #1; expect_val(dout_b, 8'h7E, "P3_crossAtoB_addr6");

        // ---- Phase 4: cross-port reverse — write via B, read via A ----
        @(negedge clk_b); we_b = 1'b1; addr_b = 4'd12; din_b = 8'h3F;
        @(negedge clk_b); we_b = 1'b0;
        @(negedge clk_a); we_a = 1'b0; addr_a = 4'd12;
        @(negedge clk_a);
        @(negedge clk_a); #1; expect_val(dout_a, 8'h3F, "P4_crossBtoA_addr12");

        // ---- Phase 5/6: all addresses written from A, read back from B ----
        for (i = 0; i < DEPTH; i = i + 1) begin
            @(negedge clk_a); we_a = 1'b1; addr_a = i[AW-1:0]; din_a = (8'hA0 + i[7:0]);
        end
        @(negedge clk_a); we_a = 1'b0;
        for (i = 0; i < DEPTH; i = i + 1) begin
            @(negedge clk_b); we_b = 1'b0; addr_b = i[AW-1:0];
            @(negedge clk_b); #1;
            expect_val(dout_b, (8'hA0 + i[7:0]), "P6_B_readback");
        end

        #20;
        if (errors == 0) $display("=== ALL TESTS PASSED ===");
        else             $display("=== %0d FAILURE(S) ===", errors);
        $finish;
    end

endmodule
