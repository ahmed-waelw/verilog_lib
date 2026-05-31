# Verilog HDL Library

A personal, growing library of synthesizable Verilog modules, each shipped with an independent, self-checking testbench. The library is being built and verified **section by section**, a module is only marked ✅ once it has passed a full self-checking verification suite against an independent reference model.

**Three sections complete — Arithmetic, Control, and Datapath — all fully verified.** The remaining sections are in active development.

> **Arithmetic:** 6 / 6 modules verified · 1,717,077 self-checking comparisons · 0 failures
> **Control:** 12 / 12 modules verified · all self-checking testbenches PASS · 0 failures
> **Datapath:** 6 / 6 modules verified · 8,552 exhaustive comparisons · 0 failures
> Simulator: ModelSim – Intel FPGA Edition 10.5b

---

## Library status

| Section | Modules | Status |
|---|---|:---:|
| **Arithmetic** | ALU, Adder, Subtractor, Multiplier, Divider, Comparator | ✅ **Complete & verified** |
| **Control** | UpCounter, DownCounter, UpDownCounter, BCDCounter, GrayCounter, JohnsonCounter, LFSR, ModNCounter, PWMCounter, RingCounter, RippleCounter, Timer | ✅ **Complete & verified** |
| **Datapath** | Decoder, Demultiplexer, Encoder, PriorityEncoder, BarrelShifter, Multiplexer | ✅ **Complete & verified** |
| **Memory** | DFlipFlop, JKFlipFlop, TFlipFlop, SRFlipFlop, DLatch, SRLatch, Register, ShiftRegisterSISO/SIPO/PISO/PIPO/Universal, RAMSinglePort, RAMDualPort, ROM, FIFO | 🔬 Verification in progress |
| Communication | UART, SPI, I²C | 🚧 In development |
| Finite state machines | Pattern/sequence FSMs, control units | 🚧 Planned |
| Capstone | RV32I RISC-V core (assembled from the blocks above) | 🚧 Planned |

All three completed sections carry verification results below. In-progress sections will be documented and verified to the same standard before being marked complete.

---

## Why the verified sections are worth a look

Most testbenches "pass" because they were never pushed hard enough to fail. The verification passes for both sections **caught real bugs** that manual waveform reviews would almost certainly have missed:

- **Arithmetic:** A sign-extension defect in the ALU's arithmetic shift-right, root-caused to a toolchain quirk and fixed with a portable construct. Re-verified clean across all 1,048,576 ALU input combinations. See [The Bug](#the-bug-alu-arithmetic-shift-right).
- **Control:** Two Verilog scheduling subtleties — a width-promotion bug in the JohnsonCounter testbench reference model (context-determined vs. self-determined operands) and an active-region vs. NBA-region race in the RippleCounter wrap-catch. Both were silent failures the simulator accepted without warning. See [The Bugs: Control Testbenches](#the-bugs-control-testbenches).
- **Datapath:** A for-loop scan-direction bug in the PriorityEncoder that silently returned the lowest-numbered set bit instead of the highest. One-hot inputs passed either way, masking the defect — only an exhaustive multi-hot sweep caught it. See [The Bug: PriorityEncoder Scan Direction](#the-bug-priorityencoder-scan-direction).

---

## Arithmetic section — verification summary

| Module      | Width  | Verification method         | Checks        | Result |
|-------------|--------|-----------------------------|---------------|:------:|
| ALU         | 8-bit  | **Exhaustive**              | 1,048,576     | ✅ PASS |
| Adder       | 32-bit | Directed + random           | 200,080       | ✅ PASS |
| Subtractor  | 32-bit | Directed + random           | 200,080       | ✅ PASS |
| Multiplier  | 32-bit | Directed + random           | 100,041       | ✅ PASS |
| Divider     | 8-bit  | **Exhaustive** (sequential) | 65,292        | ✅ PASS |
| Comparator  | 32-bit | Directed + random           | 103,008       | ✅ PASS |
| **Total**   | —      | —                           | **1,717,077** | ✅ PASS |

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

## Control section — verification summary

All 12 counter/timer modules are parameterized (except BCDCounter, which is inherently 4-bit). Each testbench uses an **independent reference model** structurally different from the DUT, strict (`!==`) comparison, and property-based invariants (one-hot, Hamming-1, Q < MOD, etc.). Every module was also tested for correct **asynchronous reset** behavior — asserting reset mid-count between clock edges and verifying the output clears without a clock edge.

| Module | Default width | Verification method | Key properties checked | Result |
|---|---|---|---|:---:|
| UpCounter | 4-bit | Ref model + wrap | Free-run, wrap 2^N, async reset | ✅ PASS |
| DownCounter | 4-bit | Ref model + wrap | Count-down from MAX, wrap, async reset | ✅ PASS |
| UpDownCounter | 4-bit | UpCounter + DownCounter refs | Both directions vs. proven refs, active-low reset | ✅ PASS |
| BCDCounter | 4-bit (fixed) | Ref model + BCD invariant | 0-9 sequence, Q ≤ 9, wrap 9→0, async reset | ✅ PASS |
| GrayCounter | 4-bit | Binary→Gray ref + properties | Reflected-binary match, Hamming-1, uniqueness, cycle = 2^N | ✅ PASS |
| JohnsonCounter | 8-bit | Shift-feedback ref | Sequence match, cycle = 2N, async reset from all-ones | ✅ PASS |
| LFSR | 4-bit | Record/replay + properties | SEED load, period = 2^N−1, never-zero, uniqueness, determinism | ✅ PASS |
| ModNCounter | 4-bit × 3 DUTs | Three concurrent refs (MOD 10/6/13) | Value match, Q < MOD invariant, async reset | ✅ PASS |
| PWMCounter | 4-bit | Duty sweep 0..PERIOD | High-cycle count per period for all duty values, async reset | ✅ PASS |
| RingCounter | 4-bit | Position formula ref | One-hot invariant, Q == SEED << idx, cycle = N, async reset | ✅ PASS |
| RippleCounter | 4-bit | Synchronous ref (negedge sampling) | Full-count wraps, MAX→0 cascade after settling, parallel clear | ✅ PASS |
| Timer | 4-bit | Tick-spacing monitor | Single-cycle tick width, PERIOD-clock spacing, 5+ ticks, async reset | ✅ PASS |

---

## The Bugs: Control Testbenches

During control verification, two testbenches were initially failing. The design modules themselves were correct in both cases — the bugs were on the verification side, both belonging to the same family of **Verilog scheduling subtleties**.

### 1. JohnsonCounter_tb — width-promotion in the reference model

The behavioral reference used `~exp[N-1]` as feedback. Inside an expression, every operand inherits the context width (4 bits, from `exp`). The 1-bit bit-select `exp[N-1]` is zero-extended to 4 bits *before* `~` is applied, so `~exp[N-1]` becomes `~4'b0001 = 4'b1110` instead of the intended single-bit complement — pinning the model at `1110` forever and producing ~38 false errors per run.

**Fix:** wrap the feedback in a concatenation to force self-determined width:

```verilog
// BEFORE — context-determined, 4-bit inversion
exp <= (exp << 1) | ~exp[N-1];
// AFTER — self-determined, single-bit inversion
exp <= (exp << 1) | {{N-1{1'b0}}, ~exp[N-1]};
```

### 2. RippleCounter_tb — active-region vs. NBA-region race

After 32 free-running cycles, the wrap-catch `wait (Q == MAX)` executed immediately in the active region — *before* the NBA update had applied — seeing the stale pre-update value of `Q`. This caused the subsequent sample to land one cycle late, capturing `Q = 0001` instead of the wrap target `0000`.

**Fix:** insert `@(negedge clk);` to advance past the NBA region before the `wait`:

```verilog
repeat (2 * DEPTH) @(posedge clk);
@(negedge clk);                         // settle past the last posedge's NBA
wait (Q == {WIDTH{1'b1}});
```

**Lesson:** both bugs are silent — the simulator accepts the code without warning. Defensive habits (wrap single-bit feedback in `{ }`; advance past an NBA region with `@(negedge clk)` or `#1` before sampling) prevent both.

---

## Datapath section — verification summary

All 6 datapath modules are parameterized and purely combinational. Each testbench uses an **independent reference model** structurally different from the DUT (e.g. bit-indexing vs. shifting, per-bit position mapping vs. operator expressions) and strict (`!==`) comparison. Every module with a feasible input space was verified **exhaustively**.

| Module | Default config | Verification method | Cases | Result |
|---|---|---|---:|:---:|
| Decoder | N=3 (3-to-8) | Exhaustive (en × sel) | 16 | ✅ PASS |
| Demultiplexer | N=3 (1-to-8) | Exhaustive (D × sel) | 16 | ✅ PASS |
| Encoder | N=3 (8-to-3) | All one-hot inputs | 8 | ✅ PASS |
| PriorityEncoder | N=3 (8-to-3) | Exhaustive over all 2^8 inputs (incl. multi-hot) | 256 | ✅ PASS |
| BarrelShifter | WIDTH=8 | Exhaustive (4 modes × 8 amounts × 256 data) | 8,192 | ✅ PASS |
| Multiplexer | WIDTH=4 (4-to-1) | Exhaustive (4 selects × 16 data) | 64 | ✅ PASS |
| **Total** | — | — | **8,552** | ✅ PASS |

---

## The Bug: PriorityEncoder Scan Direction

During datapath verification the self-checking flow flagged mismatches on **multi-hot inputs** for the PriorityEncoder. One-hot inputs passed in both directions, so the bug was invisible to any test suite that only drove valid one-hot patterns.

```verilog
// BEFORE — scans high-to-low, last write wins = lowest set bit
for (i = (1<<N)-1; i >= 0; i = i - 1)
    if (D[i]) Y = i;
// observed: D=10000001  ->  Y=000  (bit 0, the lowest)
// expected: D=10000001  ->  Y=111  (bit 7, the highest)
```

**Root cause:** the for-loop iterates from `(1<<N)-1` down to `0`. In a combinational `always @(*)` block, the last assignment wins. When `i` reaches the lowest set bit, it overwrites all earlier assignments — so the module returns the lowest-numbered set bit, contradicting its spec ("highest-numbered asserted input bit").

**Fix** — reverse the scan direction so the last write is the highest:

```verilog
// AFTER — scans low-to-high, last write wins = highest set bit
for (i = 0; i < (1<<N); i = i + 1)
    if (D[i]) Y = i;
// result: D=10000001  ->  Y=111  (correct)
```

After the fix, all 256 exhaustive input patterns — including every multi-hot combination — passed with zero failures.

**Lesson:** one-hot-only test coverage is a false sense of security for encoders. The PriorityEncoder's entire purpose is to handle multi-hot inputs, yet a one-hot-only suite would have marked it clean. Exhaustive coverage over the full 2^N input space caught what directed testing missed.

---

## Verification methodology

Every completed module uses the same self-checking philosophy: for each stimulus the testbench computes the expected output from an **independent reference model** (written separately from the design under test), then compares it against the DUT using a **strict (`!==`) comparison**. The strict operator also flags any unknown (`X`) or high-impedance (`Z`) value, so an uninitialized or floating output cannot silently pass. Only mismatches are printed; a running pass/fail tally is reported at completion.

Two coverage strategies are used depending on the size of the input space:

- **Exhaustive** — for the 8-bit ALU and 8-bit divider, whose input spaces are small enough to enumerate completely. Proves correctness for *all* inputs rather than inferring it from a sample.
- **Directed + randomized** — for the 32-bit datapaths, whose input spaces (~10¹⁹ combinations) cannot be enumerated. Hand-chosen corner cases (zeros, all-ones, carry/borrow boundaries, signed/unsigned edges, alternating patterns) and structured sweeps target the structural weak points where bugs concentrate; 100,000 randomized wide-operand vectors per module add statistical breadth.

Where an output convention could be ambiguous, the reference model encodes a specific assumption and a clean pass confirms it. For the subtractor, the reference assumes the **borrow convention** (`cout = 1` signals a borrow); the zero-failure result confirms the design matches it, since the opposite carry-style convention would have failed every borrowing case.

All arithmetic modules compile under Verilog-2001 compatibility mode with **zero errors and zero warnings**.

---

## Per-module verification detail (Arithmetic)

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
verilog_lib/
├── arithmetic/         # ✅ complete & verified (6 modules + 6 testbenches)
├── control/            # ✅ complete & verified (12 modules + 12 testbenches)
├── datapath/           # ✅ complete & verified (6 modules + 6 testbenches)
├── memory/             # 🔬 verification in progress (16 modules + 16 testbenches)
├── communication/      # 🚧 in development
└── README.md
```

Each folder contains paired `<Module>.v` and `<Module>_tb.v` files side by side. Design modules and their testbenches live in the same directory for easy navigation.

## Running the testbenches

**ModelSim / Questa (Arithmetic):**
```bash
vlog arithmetic/<module>.v arithmetic/<module>_tb.v
vsim -c <module>_tb -do "run -all; quit"
```

**ModelSim / Questa (Control):**
```bash
vlog control/*.v memory/TFlipFlop.v
vsim -c <module>_tb -do "run -all; quit"
```

The control folder requires the T-flip-flop primitive (used by RippleCounter) to be compiled alongside.

**ModelSim / Questa (Memory):**
```bash
vlog memory/<module>.v memory/<module>_tb.v
vsim -c <module>_tb -do "run -all; quit"
```

**ModelSim / Questa (Datapath):**
```bash
vlog datapath/<module>.v datapath/<module>_tb.v
vsim -c <module>_tb -do "run -all; quit"
```

All datapath modules are self-contained with no external dependencies.

**Icarus Verilog (open-source alternative):**
```bash
iverilog -g2001 -o sim <section>/<module>.v <section>/<module>_tb.v
vvp sim
```

Each testbench prints only mismatches and ends with a pass/fail tally.

---

## Roadmap

- [x] **Arithmetic** — ALU, adder, subtractor, multiplier, divider, comparator (verified)
- [x] **Control** — 12 parameterized counters and timers (verified)
- [x] **Datapath** — decoder, demultiplexer, encoder, priority encoder, barrel shifter, multiplexer (verified)
- [ ] **Memory** — flip-flops, latches, register, shift registers, RAM, ROM, FIFO (verification in progress)
- [ ] **Communication** — UART, SPI, I²C
- [ ] **FSMs** — sequence detectors, control units
- [ ] **SystemVerilog rebuild** — class-based testbenches, constrained-random stimulus, functional coverage, and SVA assertions
- [ ] **Capstone** — RV32I RISC-V core assembled from the library blocks

Each new section will be held to the same self-checking standard before being marked complete.

---

*Author: Amr Said · Verified with ModelSim – Intel FPGA Edition 10.5b · Verilog-2001*
