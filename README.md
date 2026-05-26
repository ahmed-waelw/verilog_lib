# Verilog Arithmetic Library — Functionally Verified

A library of six synthesizable arithmetic and logic modules in **Verilog-2001**, each verified with an independent, self-checking testbench. Two modules are verified **exhaustively** (every possible input applied); the wide 32-bit datapaths are verified with directed corner cases plus heavy randomization.

> **6 / 6 modules verified · 1,717,077 self-checking comparisons · 0 failures**
> Simulator: ModelSim – Intel FPGA Edition 10.5b · Target: Intel Cyclone V

---

## Why this repo is worth a look

Most testbenches "pass" because they were never pushed hard enough to fail. This one **caught a real bug** — a sign-extension defect in the ALU's arithmetic shift-right that a manual waveform review would almost certainly have missed. It was root-caused to a toolchain quirk, fixed with a portable construct, and re-verified clean across all 1,048,576 ALU input combinations. See [The Bug](#the-bug-alu-arithmetic-shift-right) below.

---

## Modules at a glance

| Module      | Width  | Verification method      | Checks        | Result |
|-------------|--------|--------------------------|---------------|:------:|
| ALU         | 8-bit  | **Exhaustive**           | 1,048,576     | ✅ PASS |
| Adder       | 32-bit | Directed + random        | 200,080       | ✅ PASS |
| Subtractor  | 32-bit | Directed + random        | 200,080       | ✅ PASS |
| Multiplier  | 32-bit | Directed + random        | 100,041       | ✅ PASS |
| Divider     | 8-bit  | **Exhaustive** (sequential) | 65,292     | ✅ PASS |
| Comparator  | 32-bit | Directed + random        | 103,008       | ✅ PASS |
| **Total**   | —      | —                        | **1,717,077** | ✅ PASS |

---

## The Bug: ALU Arithmetic Shift-Right

During ALU bring-up the self-checking flow flagged a functional defect in the arithmetic shift-right (`SRA`): for **negative operands** it was zero-filling (a logical shift) instead of replicating the sign bit.

```verilog
// BEFORE — relied on signed-operator semantics
4'h8: result = A_signed >>> B[SHAMT_WIDTH-1:0];   // SRA
// observed: SRA 0x80 >> 1  ->  0x40   (sign bit lost)
// expected: SRA 0x80 >> 1  ->  0xC0
```

**Root cause:** under the simulator's Verilog-2001 compatibility mode the `signed` attribute was not propagated into the `>>>` shift, so the sign bit was dropped. The exhaustive sweep isolated the failure to exactly the vectors with a negative operand.

**Fix** — explicit, toolchain-independent sign extension:

```verilog
// AFTER — explicit sign fill, no reliance on signed semantics
4'h8: result = A[WIDTH-1] ? ~((~A) >> B[SHAMT_WIDTH-1:0])
                          : (   A  >> B[SHAMT_WIDTH-1:0]);   // SRA
// result: SRA 0x80 >> 1  ->  0xC0   (correct)
```

After the fix, all 65,536 `SRA` vectors — and all 1,048,576 ALU vectors — passed with zero failures.

**Two lessons:** (1) a directed-only or manual review could easily have missed a defect confined to negative operands; (2) relying on signed-operator semantics is fragile across toolchain modes, while the explicit sign-fill form is portable.

---

## Verification methodology

Every module uses the same self-checking philosophy: for each stimulus the testbench computes the expected output from an **independent reference model** (written separately from the design under test), then compares it against the DUT using a **strict (`!==`) comparison**. The strict operator also flags any unknown (`X`) or high-impedance (`Z`) value, so an uninitialized or floating output cannot silently pass. Only mismatches are printed; a running pass/fail tally is reported at completion.

Two coverage strategies are used depending on the size of the input space:

- **Exhaustive** — for the 8-bit ALU and 8-bit divider, whose input spaces are small enough to enumerate completely. Proves correctness for *all* inputs rather than inferring it from a sample.
- **Directed + randomized** — for the 32-bit datapaths, whose input spaces (~10¹⁹ combinations) cannot be enumerated. Hand-chosen corner cases (zeros, all-ones, carry/borrow boundaries, signed/unsigned edges, alternating patterns) and structured sweeps target the structural weak points where bugs concentrate; 100,000 randomized wide-operand vectors per module add statistical breadth.

Where an output convention could be ambiguous, the reference model encodes a specific assumption and a clean pass confirms it. For the subtractor, the reference assumes the **borrow convention** (`cout = 1` signals a borrow); the zero-failure result confirms the design matches it, since the opposite carry-style convention would have failed every borrowing case.

All modules compile under Verilog-2001 compatibility mode with **zero errors and zero warnings**.

---

## Per-module verification detail

<details>
<summary><b>ALU (8-bit, exhaustive)</b></summary>

16 operations selected by a 4-bit opcode (`ADD, SUB, AND, OR, XOR, NOT, SLL, SRL, SRA, SLT, SLTU, EQ, NEQ, PASS, INC, DEC`), producing an 8-bit result plus carry, overflow, zero, and negative flags. Verified exhaustively: all 16 opcodes × 256 (A) × 256 (B) = 1,048,576 vectors, with the result word and all four flags checked on every vector.

</details>

<details>
<summary><b>Adder (32-bit)</b></summary>

Computes `a + b + cin` with carry-out. Written as a single continuous assignment (`{cout, s} = a + b + cin`) so synthesis infers the optimal carry structure — on Cyclone V this maps onto the dedicated hardened carry chain. Sum and carry-out are checked together as a 33-bit quantity so the carry is never lost. Directed corner cases (16) + walking-one carry sweep across all 32 bit positions (64) + 100,000 random pairs at both carry-in values (200,000). Total 200,080.

</details>

<details>
<summary><b>Subtractor (32-bit)</b></summary>

Computes `s = a - b - cin` with a borrow-out (borrow convention). Difference and borrow checked together as a 33-bit quantity. Directed corner cases (16) + single-set-bit sweep across all 32 positions of both operands (64) + 100,000 random pairs at both borrow-in values (200,000). Total 200,080.

</details>

<details>
<summary><b>Multiplier (32-bit)</b></summary>

Produces the full 64-bit unsigned product, no truncation. The complete 64-bit result is checked on every vector. Power-of-two cases are emphasized because multiplying large powers of two drives the product into the high 64-bit range, exercising upper bits that mid-range random operands tend to under-stress. Directed (9) + power-of-two sweep (32) + 100,000 random pairs. Total 100,041. *(Unsigned only — signed multiplication is out of scope for this version.)*

</details>

<details>
<summary><b>Divider (8-bit, sequential, exhaustive)</b></summary>

A multi-cycle unit producing quotient and remainder under synchronous reset. Verified exhaustively over every dividend (0–255) against every nonzero divisor (1–255) = 65,280 vectors; division by zero is excluded as undefined. Because the unit holds state across cycles, two sequential-specific tests were added: **reset-mid-operation recovery** (reset partway through must cleanly abort to a known state) and **back-to-back operation** (consecutive divisions must not leak residual state). Total 65,292.

</details>

<details>
<summary><b>Comparator (32-bit)</b></summary>

Asserts one of three mutually exclusive outputs — `eq`, `lt`, `gt` — for unsigned operands. Because the reference is always one-hot, checking all three against it also confirms mutual exclusivity. Since two random 32-bit values are equal only about once in four billion, dedicated equality (1,000 `a == b` vectors) and near-boundary (2,000 differ-by-one) coverage exercise the `eq` output and its transitions. Directed (8) + equality (1,000) + near-boundary (2,000) + 100,000 random. Total 103,008. *(Unsigned magnitude only.)*

</details>

---

## Repository layout

```
verilog_lib/arithmetic/
├── rtl/            # synthesizable module sources
├── tb/             # self-checking testbenches + reference models
├── docs/           # consolidated verification report (PDF)
└── README.md
```

## Running the testbenches

**ModelSim / Questa:**
```bash
vlog rtl/<module>.v tb/<module>_tb.v
vsim -c <module>_tb -do "run -all; quit"
```

**Icarus Verilog (open-source alternative):**
```bash
iverilog -g2001 -o sim rtl/<module>.v tb/<module>_tb.v
vvp sim
```

Each testbench prints only mismatches and ends with a pass/fail tally.

---

## What's next

This is the **Verilog** baseline. The planned follow-on rebuilds the library in **SystemVerilog** with class-based testbenches, constrained-random stimulus, functional coverage closure, and SystemVerilog Assertions (SVA) — the way verification is done in industry.

---

*Author: Amr Said · Verified with ModelSim – Intel FPGA Edition 10.5b · Verilog-2001*
