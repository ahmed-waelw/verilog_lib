// ----------------------------------------------------------------------------
// Module:      RAMDualPort
// Description: True dual-port synchronous RAM. Two independent ports, each
//              with its own clock, address, write-enable, data-in and
//              registered data-out. Either port can read or write on any
//              cycle.
// Parameters:  WIDTH - data width in bits (default 8)
//              DEPTH - number of words (default 256)
//              AW    - address width = $clog2(DEPTH) (derived, override only
//                      if you know what you are doing)
// Ports:       clk_a, clk_b      - independent clocks
//              we_a, we_b        - write enables
//              addr_a, addr_b    - addresses
//              din_a, din_b      - data inputs
//              dout_a, dout_b    - registered data outputs
// Author:      Amr Said
// Date:        2026-05-14
// ----------------------------------------------------------------------------
module RAMDualPort #(
    parameter WIDTH = 8,
    parameter DEPTH = 256,
    parameter AW    = $clog2(DEPTH)
)(
    input                  clk_a,
    input                  we_a,
    input      [AW-1:0]    addr_a,
    input      [WIDTH-1:0] din_a,
    output reg [WIDTH-1:0] dout_a,

    input                  clk_b,
    input                  we_b,
    input      [AW-1:0]    addr_b,
    input      [WIDTH-1:0] din_b,
    output reg [WIDTH-1:0] dout_b
);

    reg  [WIDTH-1:0] mem [0:DEPTH-1];

    // Port A
    always @(posedge clk_a) begin
        if (we_a) mem[addr_a] <= din_a;
        dout_a <= mem[addr_a];
    end

    // Port B
    always @(posedge clk_b) begin
        if (we_b) mem[addr_b] <= din_b;
        dout_b <= mem[addr_b];
    end

endmodule
