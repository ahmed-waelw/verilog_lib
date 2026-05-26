# Verilog Primitives Library

Parameterized Verilog 2005 primitives library for FPGA design.
Built for educational use and as a reusable IP foundation.

## Arithmetic Modules

| Module | Description |
|---|---|
| `Adder.v` | Parameterized N-bit ripple-carry adder with carry in/out |
| `ALU.v` | 16-operation arithmetic and logic unit with status flags |
| `Comparator.v` | N-bit unsigned magnitude comparator (eq, lt, gt) |
| `Divider.v` | Sequential restoring shift-and-subtract divider |
| `Multiplier.v` | N-bit unsigned combinational multiplier |
| `Subtractor.v` | N-bit subtractor with borrow in/out |

Each module has a matching `_tb.v` self-checking testbench.

## Conventions

- Classical Verilog 2005 (no SystemVerilog)
- Parameterized widths with sensible defaults
- Asynchronous reset, active high (unless noted)
- Standard file header with module description, ports, and author

## Module Template

```verilog
// ----------------------------------------------------------------------------
// Module:      <ModuleName>
// Description: <one or two sentences>
// Parameters:  WIDTH - data width in bits (default 8)
// Ports:       clk   - input clock (rising edge)
//              reset - asynchronous reset, active high
// Author:      Amr Said
// Date:        YYYY-MM-DD
// ----------------------------------------------------------------------------
module <ModuleName> #(
    parameter WIDTH = 8
)(
    input              clk,
    input              reset,
    // ...
);

    // implementation

endmodule
```

## Author

Amr Said — amr_said@aucegypt.edu
