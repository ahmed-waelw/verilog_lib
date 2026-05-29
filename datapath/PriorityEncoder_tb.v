// ----------------------------------------------------------------------------
// Module:      PriorityEncoder_tb
// Description: Self-checking testbench for parameterized priority encoder.
// DUT:         PriorityEncoder #(.N(3))
//              Ports: D [(1<<N)-1:0] -> Y [N-1:0], valid
// Author:      Amr Said
// Date:        2026-05-29
// ----------------------------------------------------------------------------
`timescale 1ns/1ps

module PriorityEncoder_tb();
parameter WIDTH = 3;  // output width in bits (N)
reg  [(1<<WIDTH)-1:0] D;
wire [WIDTH-1:0] Y;
wire             valid;
integer    errors = 0;
integer    i;
reg  [WIDTH-1:0] expected_Y;
reg              expected_valid;

// DUT instantiation
PriorityEncoder #(.N(WIDTH)) DUT (.D(D), .Y(Y), .valid(valid));

// reference model
localparam W = 1 << WIDTH;   // input width = 2^N

// highest set-bit index (MSB priority)
function [WIDTH-1:0] ref_prio(input [W-1:0] d);
    integer k;
    begin
        ref_prio = {WIDTH{1'b0}};
        for (k = 0; k < W; k = k + 1)
            if (d[k]) ref_prio = k[WIDTH-1:0];  // later k overwrites -> highest wins
    end
endfunction

localparam max = (1 << W) - 1;  // exhaustive over every input (feasible to ~N=4)

initial begin
    $dumpfile("PriorityEncoder_tb.vcd");
    $dumpvars(0, PriorityEncoder_tb);
    $display("=== Priority encoder testbench ===");
    // priority encoder is defined for ALL inputs -> sweep the full space
    for (i = 0; i <= max; i = i + 1) begin
        D = i;
        #5;  // wait for outputs to settle
        expected_valid = |D;             // high if any input is active
        expected_Y     = ref_prio(D);    // index of highest-priority set bit

        // valid must always match; Y is don't-care when valid is low
        if (valid !== expected_valid) begin
            $display("FAIL: D=%b -> valid=%b (exp %b) @ %0t",
                     D, valid, expected_valid, $time);
            errors = errors + 1;
        end
        else if (expected_valid && (Y !== expected_Y)) begin
            $display("FAIL: D=%b -> Y=%b (exp %b) @ %0t",
                     D, Y, expected_Y, $time);
            errors = errors + 1;
        end
        #5;
    end
    if (errors == 0) $display("PASS: all %0d cases correct", (1<<W));
    else             $display("DONE: %0d error(s)", errors);
    $finish;
end

endmodule