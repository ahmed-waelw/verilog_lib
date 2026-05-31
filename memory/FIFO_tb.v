// ----------------------------------------------------------------------------
// Module:      FIFO_tb
// Description: Self-checking testbench for synchronous FIFO.
// DUT:         FIFO #(.WIDTH(8), .DEPTH(16))
//              Ports: clk, reset, wr_en, rd_en, din [WIDTH-1:0]
//                     -> dout [WIDTH-1:0], full, empty
// Author:      Amr Said
// Date:        2026-05-30
// ----------------------------------------------------------------------------
`timescale 1ns/1ps

module FIFO_tb();

localparam WIDTH = 8;
localparam DEPTH = 16;

reg              clk;
reg              reset;
reg              wr_en;
reg              rd_en;
reg  [WIDTH-1:0] din;
wire [WIDTH-1:0] dout;
wire             full;
wire             empty;
integer          errors = 0;

// DUT instantiation
FIFO #(.WIDTH(WIDTH), .DEPTH(DEPTH)) DUT (
    .clk(clk), .reset(reset),
    .wr_en(wr_en), .rd_en(rd_en),
    .din(din), .dout(dout),
    .full(full), .empty(empty)
);

// Clock generation: 10ns period
initial clk = 1'b0;
always #5 clk = ~clk;

// ------------------------------------------------------------------
// Reference model (golden queue)
// ------------------------------------------------------------------
reg [WIDTH-1:0] golden_mem [0:4095];
integer         golden_wr;
integer         golden_rd;
integer         golden_count;

// Scoreboard: every accepted write is shadowed; every accepted read is checked.
// Fires at posedge so it samples the same pre-edge values the DUT does.
always @(posedge clk) begin
    if (reset) begin
        golden_wr    <= 0;
        golden_rd    <= 0;
        golden_count <= 0;
    end else begin
        // Data check: dout (pre-edge) must equal expected head
        if (rd_en && !empty) begin
            if (dout !== golden_mem[golden_rd[11:0]]) begin
                $display("[%0t] DATA FAIL: got %02h, expected %02h (idx=%0d)",
                         $time, dout, golden_mem[golden_rd[11:0]], golden_rd);
                errors = errors + 1;
            end
        end
        // Shadow accepted ops
        case ({wr_en && !full, rd_en && !empty})
            2'b10: begin
                golden_mem[golden_wr[11:0]] <= din;
                golden_wr    <= golden_wr + 1;
                golden_count <= golden_count + 1;
            end
            2'b01: begin
                golden_rd    <= golden_rd + 1;
                golden_count <= golden_count - 1;
            end
            2'b11: begin
                golden_mem[golden_wr[11:0]] <= din;
                golden_wr <= golden_wr + 1;
                golden_rd <= golden_rd + 1;
                // count unchanged
            end
            default: ; // no-op
        endcase
    end
end

// Flag check: after each cycle settles, full/empty should match golden_count.
// negedge guarantees the DUT's combinational flags have caught up.
always @(negedge clk) begin
    if (!reset) begin
        if (full !== (golden_count == DEPTH)) begin
            $display("[%0t] FULL  FAIL: dut=%b expected=%b (count=%0d)",
                     $time, full, (golden_count == DEPTH), golden_count);
            errors = errors + 1;
        end
        if (empty !== (golden_count == 0)) begin
            $display("[%0t] EMPTY FAIL: dut=%b expected=%b (count=%0d)",
                     $time, empty, (golden_count == 0), golden_count);
            errors = errors + 1;
        end
    end
end

// ------------------------------------------------------------------
// Stimulus helpers
// ------------------------------------------------------------------
task do_write(input [WIDTH-1:0] data);
    begin
        @(negedge clk);
        din   = data;
        wr_en = 1'b1;
        rd_en = 1'b0;
        @(posedge clk);
        @(negedge clk);
        wr_en = 1'b0;
    end
endtask

task do_read;
    begin
        @(negedge clk);
        wr_en = 1'b0;
        rd_en = 1'b1;
        @(posedge clk);
        @(negedge clk);
        rd_en = 1'b0;
    end
endtask

task do_rw(input [WIDTH-1:0] data);  // simultaneous read + write
    begin
        @(negedge clk);
        din   = data;
        wr_en = 1'b1;
        rd_en = 1'b1;
        @(posedge clk);
        @(negedge clk);
        wr_en = 1'b0;
        rd_en = 1'b0;
    end
endtask

// ------------------------------------------------------------------
// Stimulus
// ------------------------------------------------------------------
integer i;
initial begin
    $dumpfile("fifo_tb.vcd");
    $dumpvars(0, FIFO_tb);

    // ---- T1: reset & idle ----
    wr_en = 0; rd_en = 0; din = 0;
    reset = 1;
    @(posedge clk); @(posedge clk);
    @(negedge clk); reset = 0;
    if (empty !== 1'b1 || full !== 1'b0) begin
        $display("[%0t] T1 FAIL: post-reset empty=%b full=%b", $time, empty, full);
        errors = errors + 1;
    end

    // ---- T2: single round-trip ----
    do_write(8'hA5);
    do_read();   // scoreboard checks dout == 0xA5

    // ---- T3: ordering ----
    do_write(8'h11); do_write(8'h22); do_write(8'h33); do_write(8'h44);
    do_read();  do_read();  do_read();  do_read();

    // ---- T4: fill to full ----
    for (i = 0; i < DEPTH; i = i + 1) do_write(i);
    @(negedge clk);
    if (!full) begin
        $display("[%0t] T4 FAIL: full should be 1 after %0d writes", $time, DEPTH);
        errors = errors + 1;
    end

    // ---- T5: overflow protection ----
    do_write(8'hFF);   // blocked by DUT; scoreboard does not shadow

    // ---- T6: drain to empty ----
    for (i = 0; i < DEPTH; i = i + 1) do_read();
    @(negedge clk);
    if (!empty) begin
        $display("[%0t] T6 FAIL: empty should be 1 after drain", $time);
        errors = errors + 1;
    end

    // ---- T7: underflow protection ----
    do_read();         // blocked; no data check fires (empty=1)

    // ---- T8: pointer wraparound (3 x DEPTH = 48 items) ----
    for (i = 0; i < 3*DEPTH; i = i + 1) begin
        do_write(i & 8'hFF);
        do_read();
    end

    // ---- T9: simultaneous R+W in steady state ----
    for (i = 0; i < 8; i = i + 1) do_write(8'h80 + i);   // half-fill
    for (i = 0; i < 16; i = i + 1) do_rw(8'hC0 + i);     // count holds at 8
    while (!empty) do_read();

    // ---- T10: simultaneous R+W at full boundary ----
    for (i = 0; i < DEPTH; i = i + 1) do_write(i);       // fill
    do_rw(8'hAA);   // FWFT spec: write blocked (full), read advances
    while (!empty) do_read();

    // ---- T11: random stress ----
    for (i = 0; i < 2000; i = i + 1) begin
        @(negedge clk);
        wr_en = $random & 1;
        rd_en = $random & 1;
        din   = $random;
    end
    @(negedge clk);
    wr_en = 0; rd_en = 0;

    // Drain whatever is left so final state is clean
    while (!empty) do_read();
    @(negedge clk);

    // ---- Final report ----
    #20;
    if (errors == 0)
        $display("=== ALL TESTS PASSED ===");
    else
        $display("=== %0d FAILURE(S) ===", errors);
    $finish;
end

endmodule