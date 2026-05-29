// ----------------------------------------------------------------------------
// Module:      BarrelShifter_tb
// Description: Self-checking testbench for parameterized barrel shifter.
// DUT:         BarrelShifter #(.WIDTH(8), .SHIFT_BITS(3))
//              Ports: D, amount, dir, mode -> Y
// Author:      Amr Said
// Date:        2026-05-29
// ----------------------------------------------------------------------------
`timescale 1ns/1ps
module BarrelShifter_tb();
parameter  WIDTH      = 8;
localparam SHIFT_BITS = $clog2(WIDTH);

reg  [WIDTH-1:0]      D;
reg  [SHIFT_BITS-1:0] amount;
reg                   dir, mode;
wire [WIDTH-1:0]      Y;
integer errors = 0;
integer d, a, di, mo;
reg  [WIDTH-1:0] expected;

BarrelShifter #(.WIDTH(WIDTH), .SHIFT_BITS(SHIFT_BITS)) DUT
    (.D(D), .amount(amount), .dir(dir), .mode(mode), .Y(Y));

// independent reference: defines shift/rotate by where each bit GOES
function [WIDTH-1:0] ref_bs(input [WIDTH-1:0] din, input integer k,
                            input dr, input md);
    integer j;
    begin
        ref_bs = {WIDTH{1'b0}};
        if (md == 1'b0) begin                       // logical shift (zero fill)
            if (dr == 1'b0)                          // left
                for (j = 0; j < WIDTH; j = j + 1)
                    begin if (j + k < WIDTH) ref_bs[j + k] = din[j]; end
            else                                     // right
                for (j = 0; j < WIDTH; j = j + 1)
                    begin if (j - k >= 0)    ref_bs[j - k] = din[j]; end
        end else begin                               // rotate (wrap)
            if (dr == 1'b0)                          // rotate left
                for (j = 0; j < WIDTH; j = j + 1)
                    ref_bs[(j + k) % WIDTH] = din[j];
            else                                     // rotate right
                for (j = 0; j < WIDTH; j = j + 1)
                    ref_bs[(j - k + WIDTH) % WIDTH] = din[j];
        end
    end
endfunction

initial begin
    $dumpfile("BarrelShifter_tb.vcd");
    $dumpvars(0, BarrelShifter_tb);
    $display("=== BarrelShifter testbench (WIDTH=%0d) ===", WIDTH);
    for (di = 0; di <= 1; di = di + 1)
      for (mo = 0; mo <= 1; mo = mo + 1)
        for (a = 0; a < (1 << SHIFT_BITS); a = a + 1)
          for (d = 0; d < (1 << WIDTH); d = d + 1) begin
            D = d[WIDTH-1:0]; amount = a[SHIFT_BITS-1:0]; dir = di[0]; mode = mo[0];
            #1;
            expected = ref_bs(D, a, dir, mode);
            if (Y !== expected) begin
                $display("FAIL: dir=%b mode=%b amt=%0d D=%b -> Y=%b (exp %b)",
                         dir, mode, amount, D, Y, expected);
                errors = errors + 1;
            end
            #1;
          end
    if (errors == 0) $display("PASS: all %0d cases correct", 2*2*(1<<SHIFT_BITS)*(1<<WIDTH));
    else             $display("DONE: %0d error(s)", errors);
    $finish;
end
endmodule