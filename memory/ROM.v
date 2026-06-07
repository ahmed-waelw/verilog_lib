// ----------------------------------------------------------------------------
// Module:      ROM
// Description: Synchronous read-only memory. Contents loaded from an external
//              hex file at elaboration via $readmemh.
// Parameters:  WIDTH    - data width in bits (default 8)
//              DEPTH    - number of words (default 256)
//              AW       - address width = $clog2(DEPTH) (derived, override only
//                         if you know what you are doing)
//              INIT_FILE - path to .hex / .mem file (default "rom_init.hex")
// Ports:       clk   - input clock (rising edge)
//              addr  - address input (AW bits)
//              dout  - registered data output
// Author:      Amr Said
// Date:        2026-06-07
// ----------------------------------------------------------------------------
module ROM #(
    parameter        WIDTH     = 8,
    parameter        DEPTH     = 256,
    parameter        AW        = $clog2(DEPTH),
    parameter        INIT_FILE = "rom_init.hex"
)(
    input                  clk,
    input      [AW-1:0]    addr,
    output reg [WIDTH-1:0] dout
);

    reg [WIDTH-1:0] mem [0:DEPTH-1];

    initial begin
        $readmemh(INIT_FILE, mem);
    end

    always @(posedge clk) begin
        dout <= mem[addr];
    end

endmodule
