// ----------------------------------------------------------------------------
// Module:      ROM_tb
// Description: Self-checking testbench for synchronous ROM.
// DUT:         ROM #(.WIDTH(8), .DEPTH(16), .INIT_FILE("rom_test.hex"))
//              Ports: clk, addr [AW-1:0] -> dout [WIDTH-1:0]
// Author:      Amr Said
// Date:        2026-05-31
// ----------------------------------------------------------------------------
`timescale 1ns/1ps

module ROM_tb();
    parameter WIDTH = 8;
    parameter DEPTH = 16;
    localparam AW = $clog2(DEPTH);

    reg              clk;
    reg  [AW-1:0]    addr;
    wire [WIDTH-1:0] dout;
    integer          errors = 0;
    integer          i;

    // DUT instantiation (DEPTH=16, contents from rom_test.hex)
    ROM #(.WIDTH(WIDTH), .DEPTH(DEPTH), .INIT_FILE("rom_test.hex")) DUT (
        .clk(clk), .addr(addr), .dout(dout)
    );

    // Clock generation: 10ns period
    initial clk = 1'b0;
    always #5 clk = ~clk;

    // Independent reference model: the known ROM contents (must match rom_test.hex)
    reg [WIDTH-1:0] expected_rom [0:DEPTH-1];
    initial begin
        expected_rom[0]  = 8'hA5; expected_rom[1]  = 8'h3C;
        expected_rom[2]  = 8'hFF; expected_rom[3]  = 8'h00;
        expected_rom[4]  = 8'h12; expected_rom[5]  = 8'h34;
        expected_rom[6]  = 8'h56; expected_rom[7]  = 8'h78;
        expected_rom[8]  = 8'h9A; expected_rom[9]  = 8'hBC;
        expected_rom[10] = 8'hDE; expected_rom[11] = 8'hF0;
        expected_rom[12] = 8'h01; expected_rom[13] = 8'h23;
        expected_rom[14] = 8'h45; expected_rom[15] = 8'h67;
    end

    // Read addr 'a' was presented before the edge; after the edge dout = mem[a].
    task check_rom;
        input [AW-1:0]  a;
        input [255:0]   label;
        begin
            if (dout !== expected_rom[a]) begin
                $display("[%0t] FAIL %0s: addr=%0d expected=%h got=%h",
                         $time, label, a, expected_rom[a], dout);
                errors = errors + 1;
            end else begin
                $display("[%0t] PASS %0s: addr=%0d dout=%h", $time, label, a, dout);
            end
        end
    endtask

    // small fixed scramble for random-order reads
    reg [AW-1:0] order [0:DEPTH-1];
    initial begin
        order[0]=4'd7;  order[1]=4'd0;  order[2]=4'd15; order[3]=4'd3;
        order[4]=4'd9;  order[5]=4'd1;  order[6]=4'd12; order[7]=4'd5;
        order[8]=4'd14; order[9]=4'd2;  order[10]=4'd8; order[11]=4'd11;
        order[12]=4'd4; order[13]=4'd13; order[14]=4'd6; order[15]=4'd10;
    end

    initial begin
        $dumpfile("ROM_tb.vcd");
        $dumpvars(0, ROM_tb);

        addr = 0;
        @(negedge clk);

        // T1: sequential read of all 16 addresses (1-cycle read latency)
        for (i = 0; i < DEPTH; i = i + 1) begin
            addr = i[AW-1:0];
            @(posedge clk); #1;
            check_rom(i[AW-1:0], "T1_sequential");
        end

        // T2: random-order reads
        for (i = 0; i < DEPTH; i = i + 1) begin
            addr = order[i];
            @(posedge clk); #1;
            check_rom(order[i], "T2_random_order");
        end

        // T3: repeated reads of the same address
        addr = 4'd8;
        @(posedge clk); #1; check_rom(4'd8, "T3_repeat_1");
        @(posedge clk); #1; check_rom(4'd8, "T3_repeat_2");
        @(posedge clk); #1; check_rom(4'd8, "T3_repeat_3");

        #10;
        if (errors == 0) $display("=== ALL TESTS PASSED ===");
        else             $display("=== %0d FAILURE(S) ===", errors);
        $finish;
    end

endmodule
