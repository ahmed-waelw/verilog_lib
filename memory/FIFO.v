// ----------------------------------------------------------------------------
// Module:      FIFO
// Description: Parameterized synchronous FIFO (first-in first-out) buffer.
//              Single-clock domain. Uses a circular buffer with read/write
//              pointers and an extra MSB to distinguish full from empty.
// Parameters:  WIDTH - data width in bits (default 8)
//              DEPTH - number of entries (default 16, must be power of 2)
// Ports:       clk   - input clock (rising edge)
//              reset - asynchronous reset, active high
//              wr_en - write enable (writes din when high and not full)
//              rd_en - read enable (advances read pointer when high and not empty)
//              din   - WIDTH-bit data input
//              dout  - WIDTH-bit data output (head of FIFO)
//              full  - high when FIFO is full
//              empty - high when FIFO is empty
// Author:      Amr Said
// Date:        2026-06-07
// ----------------------------------------------------------------------------
module FIFO #(
    parameter WIDTH = 8,
    parameter DEPTH = 16
)(
    input                  clk,
    input                  reset,
    input                  wr_en,
    input                  rd_en,
    input  [WIDTH-1:0]     din,
    output [WIDTH-1:0]     dout,
    output                 full,
    output                 empty
);

    localparam AW = $clog2(DEPTH);   // address width

    // Memory array
    reg [WIDTH-1:0] mem [0:DEPTH-1];

    // Pointers: extra MSB distinguishes full (pointers equal, MSBs differ)
    // from empty (pointers equal, MSBs match)
    reg [AW:0] wr_ptr;
    reg [AW:0] rd_ptr;

    // Status
    assign full  = (wr_ptr[AW] != rd_ptr[AW]) &&
                   (wr_ptr[AW-1:0] == rd_ptr[AW-1:0]);
    assign empty = (wr_ptr == rd_ptr);

    // Read data: combinational read from head
    assign dout = mem[rd_ptr[AW-1:0]];

    // Write logic
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            wr_ptr <= {(AW+1){1'b0}};
        end else begin
            if (wr_en && !full) begin
                mem[wr_ptr[AW-1:0]] <= din;
                wr_ptr <= wr_ptr + 1'b1;
            end
        end
    end

    // Read logic
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            rd_ptr <= {(AW+1){1'b0}};
        end else begin
            if (rd_en && !empty) begin
                rd_ptr <= rd_ptr + 1'b1;
            end
        end
    end

endmodule
