// ----------------------------------------------------------------------------
// Module:      DLatch
// Description: D latch, transparent when En is high, async reset active high.
// Ports:       D     - data input
//              En    - enable, active high (transparent when high)
//              reset - asynchronous reset, active high
//              Q     - data output
//              Qn    - inverted data output
// Author:      Amr Said
// Date:        2026-05-13
// ----------------------------------------------------------------------------
module DLatch(
    input  D,
    input  En,
    input  reset,
    output reg Q,
    output Qn
);
    always @(*) begin
        if (reset)
            Q = 1'b0;       // async reset takes priority
        else if (En)
            Q = D;          // transparent when enable is high
        // else: hold
    end

    assign Qn = ~Q;
endmodule
