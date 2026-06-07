// ----------------------------------------------------------------------------
// Module:      RAMSinglePort
// Description: Single-port synchronous RAM. One port handles both reads and
//              writes; writes occur on clock edge when we is high, reads
//              produce data on the next clock edge.
// Parameters:  WIDTH - data width in bits (default 8)
//              DEPTH - number of words (default 256)
//              AW    - address width = $clog2(DEPTH) (derived, override only
//                      if you know what you are doing)
// Ports:       clk   - input clock (rising edge)
//              we    - write enable
//              addr  - address input (AW bits)
//              din   - data input
//              dout  - registered data output
// Author:      Amr Said
// Date:        2026-06-07
// ----------------------------------------------------------------------------
module RAMSinglePort #(
    parameter WIDTH = 8,
    parameter DEPTH = 256,
    parameter AW    = $clog2(DEPTH)
)(
    input                  clk,
    input                  we,
    input      [AW-1:0]    addr,
    input      [WIDTH-1:0] din,
    output reg [WIDTH-1:0] dout
);

    reg [WIDTH-1:0] mem [0:DEPTH-1];

    always @(posedge clk) begin
        if (we) mem[addr] <= din;
        dout <= mem[addr];
    end

endmodule
