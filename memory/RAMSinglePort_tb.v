// ----------------------------------------------------------------------------
// Module:      RAMSinglePort_tb
// Description: Self-checking testbench for single-port synchronous RAM.
// DUT:         RAMSinglePort #(.WIDTH(8), .DEPTH(16))
//              Ports: clk, we, addr [AW-1:0], din [WIDTH-1:0]
//                     -> dout [WIDTH-1:0]
// Author:      Amr Said
// Date:        2026-05-31
// ----------------------------------------------------------------------------
`timescale 1ns/1ps

module RAMSinglePort_tb();
    parameter WIDTH = 8;
    parameter DEPTH = 16;
    localparam AW = $clog2(DEPTH);

    reg              clk, we;
    reg  [AW-1:0]    addr;
    reg  [WIDTH-1:0] din;
    wire [WIDTH-1:0] dout;
    integer          errors = 0;
    integer          i;

    // DUT instantiation (DEPTH=16, not the default 256)
    RAMSinglePort #(.WIDTH(WIDTH), .DEPTH(DEPTH)) DUT (
        .clk(clk), .we(we), .addr(addr), .din(din), .dout(dout)
    );

    // Clock generation: 10ns period
    initial clk = 1'b0;
    always #5 clk = ~clk;

    // Independent reference model: shadow memory with read-first semantics
    // (dout takes the pre-write value, mirroring the DUT's NBA ordering).
    reg [WIDTH-1:0] ref_mem [0:DEPTH-1];
    reg [WIDTH-1:0] ref_dout;
    always @(posedge clk) begin
        if (we) ref_mem[addr] <= din;
        ref_dout <= ref_mem[addr];
    end

    task check;
        input [255:0] label;
        begin
            if (dout !== ref_dout) begin
                $display("[%0t] FAIL %0s: expected dout=%h, got dout=%h", $time, label, ref_dout, dout);
                errors = errors + 1;
            end else begin
                $display("[%0t] PASS %0s: dout=%h", $time, label, dout);
            end
        end
    endtask

    initial begin
        $dumpfile("RAMSinglePort_tb.vcd");
        $dumpvars(0, RAMSinglePort_tb);

        we = 1'b0; addr = 0; din = 0;
        @(negedge clk);

        // T1: write a value to addr 0, then read it back next cycle
        we = 1'b1; addr = 4'd0; din = 8'hAB; @(posedge clk); #1; check("T1_write_addr0");
        we = 1'b0; addr = 4'd0;              @(posedge clk); #1; check("T1_read_addr0");

        // T2: write a unique value to every address, then read all back
        we = 1'b1;
        for (i = 0; i < DEPTH; i = i + 1) begin
            addr = i[AW-1:0]; din = (8'h10 + i[7:0]);
            @(posedge clk); #1; check("T2_write_sweep");
        end
        we = 1'b0;
        for (i = 0; i < DEPTH; i = i + 1) begin
            addr = i[AW-1:0];
            @(posedge clk); #1; check("T2_read_sweep");
        end

        // T3: overwrite addr 5, read back -> second value
        we = 1'b1; addr = 4'd5; din = 8'h99; @(posedge clk); #1; check("T3_overwrite_first");
        we = 1'b1; addr = 4'd5; din = 8'h66; @(posedge clk); #1; check("T3_overwrite_second");
        we = 1'b0; addr = 4'd5;              @(posedge clk); #1; check("T3_read_after_overwrite");

        // T4: read-during-write at the same address -> read-first (OLD value)
        we = 1'b1; addr = 4'd7; din = 8'h11; @(posedge clk); #1; check("T4_seed_addr7");
        we = 1'b0; addr = 4'd7;              @(posedge clk); #1; check("T4_confirm_11");
        // now write new value while reading the same address in the same cycle
        we = 1'b1; addr = 4'd7; din = 8'h22; @(posedge clk); #1;
        check("T4_read_first_during_write");        // dout should still be OLD 0x11
        if (dout !== 8'h11) begin
            $display("[%0t] FAIL T4_read_first_value: expected OLD 0x11, got %h", $time, dout);
            errors = errors + 1;
        end else
            $display("[%0t] PASS T4_read_first_value: dout=%h (old value, read-first)", $time, dout);

        // T5: no-write reads across several addresses
        we = 1'b0;
        addr = 4'd2;  @(posedge clk); #1; check("T5_read_addr2");
        addr = 4'd9;  @(posedge clk); #1; check("T5_read_addr9");
        addr = 4'd15; @(posedge clk); #1; check("T5_read_addr15");

        #10;
        if (errors == 0) $display("=== ALL TESTS PASSED ===");
        else             $display("=== %0d FAILURE(S) ===", errors);
        $finish;
    end

endmodule
