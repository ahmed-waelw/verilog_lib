// ----------------------------------------------------------------------------
// Module:      ALU_tb
// Description: Exhaustive self-checking testbench for the ALU. Verifies all
//              16 opcodes across all 8-bit input combinations (1M+ vectors)
//              using an independent reference model. Checks result, carry,
//              overflow, zero, and negative flags. Prints only on failure.
// DUT:         ALU.v
// Author:      Amr Said
// Date:        2026-05-26
// ----------------------------------------------------------------------------
`timescale 1ns/1ps

module ALU_tb();
    reg  [7:0] a;
    reg  [7:0] b;
    reg  [3:0] sel;
    wire [7:0] out;
    wire       zero, negative, carry, overflow;

    ALU DUT (
        .A(a), .B(b), .op(sel), .result(out),
        .zero(zero), .negative(negative), .carry(carry), .overflow(overflow)
    );

    integer errors = 0;
    integer checks = 0;
    integer ai, bi, si;

    // ---- independent reference model ----
    function [7:0] ref_result(input [7:0] x, input [7:0] y, input [3:0] s);
        case (s)
            4'h0: ref_result = x + y;
            4'h1: ref_result = x - y;
            4'h2: ref_result = x & y;
            4'h3: ref_result = x | y;
            4'h4: ref_result = x ^ y;
            4'h5: ref_result = ~x;
            4'h6: ref_result = x << y[2:0];
            4'h7: ref_result = x >> y[2:0];
            4'h8: ref_result = $signed(x) >>> y[2:0];
            4'h9: ref_result = ($signed(x) < $signed(y)) ? 1 : 0;
            4'hA: ref_result = (x < y) ? 1 : 0;
            4'hB: ref_result = (x == y) ? 1 : 0;
            4'hC: ref_result = (x != y) ? 1 : 0;
            4'hD: ref_result = x;
            4'hE: ref_result = x + 1;
            4'hF: ref_result = x - 1;
            default: ref_result = 8'h00;
        endcase
    endfunction

    // ---- self-check: prints ONLY on failure ----
    task check;
        reg [7:0] exp_res;
        reg [8:0] wide;
        reg       exp_c, exp_v, exp_z, exp_n;
        begin
            checks  = checks + 1;
            exp_res = ref_result(a, b, sel);
            exp_c   = 1'b0;
            exp_v   = 1'b0;
            case (sel)
                4'h0: begin wide={1'b0,a}+{1'b0,b}; exp_c=wide[8]; exp_v=(a[7]==b[7])&&(exp_res[7]!=a[7]); end
                4'h1: begin wide={1'b0,a}-{1'b0,b}; exp_c=wide[8]; exp_v=(a[7]!=b[7])&&(exp_res[7]!=a[7]); end
                4'hE: begin wide={1'b0,a}+9'd1;     exp_c=wide[8]; exp_v=(a[7]==1'b0)&&(exp_res[7]==1'b1); end
                4'hF: begin wide={1'b0,a}-9'd1;     exp_c=wide[8]; exp_v=(a[7]==1'b1)&&(exp_res[7]==1'b0); end
            endcase
            exp_z = (exp_res == 8'h00);
            exp_n = exp_res[7];

            if (out!==exp_res || carry!==exp_c || overflow!==exp_v ||
                zero!==exp_z || negative!==exp_n) begin
                errors = errors + 1;
                $display("FAIL op=%h a=%h b=%h | res got=%h exp=%h | C=%b/%b V=%b/%b Z=%b/%b N=%b/%b",
                         sel, a, b, out, exp_res,
                         carry,exp_c, overflow,exp_v, zero,exp_z, negative,exp_n);
            end
        end
    endtask

    // ---- exhaustive sweep ----
    initial begin
        $display("=== ALU exhaustive verification: 16 x 256 x 256 = 1048576 vectors ===");
        for (si = 0; si < 16; si = si + 1) begin
            for (ai = 0; ai < 256; ai = ai + 1) begin
                for (bi = 0; bi < 256; bi = bi + 1) begin
                    sel = si[3:0];
                    a   = ai[7:0];
                    b   = bi[7:0];
                    #1 check;
                end
            end
            $display("  op %h complete  (checks=%0d, errors=%0d)", si[3:0], checks, errors);
        end
        $display("=== done: %0d checks, %0d errors ===", checks, errors);
        if (errors == 0) $display(">>> ALL %0d VECTORS PASSED <<<", checks);
        else             $display(">>> %0d FAILURE(S) <<<", errors);
        $finish;
    end
endmodule