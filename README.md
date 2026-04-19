# 🔬 4-Bit Up Counter: Scan Chain Insertion, Fault Detection & ATPG

> **Course Project | Electronics and Communication Engineering**  
> **Author:** Mridul S Kumar &nbsp;|&nbsp; **Roll No:** 123EC0006  
> **Instructor:** Dr. P. Rangababu  
> **Tools Used:** Cadence Genus (Synthesis + DFT) · Cadence Modus (ATPG)

---

## 📋 Table of Contents

- [Objective](#-objective)
- [Theory](#-theory)
- [Project Flow](#-project-flow)
- [Design Files](#-design-files)
  - [Verilog RTL](#1-verilog-rtl-design)
  - [Constraint File (SDC)](#2-constraint-file-sdc)
  - [Genus TCL Script](#3-genus-tcl-script)
  - [Modus TCL Script](#4-modus-tcl-script)
  - [Synthesized Post-DFT Netlist](#5-synthesized-post-dft-netlist)
- [Cadence Genus Results](#-cadence-genus-results)
  - [Area Report](#1-area-report)
  - [Timing Report](#2-timing-report)
  - [Power Report](#3-power-report)
  - [Gate-Level Summary](#4-gate-level-summary)
  - [DFT Rule Check](#5-dft-rule-check)
- [Cadence Modus Results](#-cadence-modus-results)
  - [DFT Test Structure Summary](#1-dft-test-structure-summary)
  - [Test Mode Pin Summary](#2-test-mode-pin-summary)
  - [Scan Pin Mapping](#3-scan-pin-mapping)
  - [Scan Chain Operations](#4-scan-chain-operations-and-test-events)
  - [Fault Coverage Analysis](#5-fault-coverage-analysis)
  - [Pattern Statistics](#6-final-pattern-statistics)
  - [Coverage Improvement](#7-coverage-improvement-during-atpg)
- [GUI Screenshots](#-gui-screenshots)
- [Conclusion](#-conclusion)

---

## 🎯 Objective

To design and synthesize a **4-bit up counter**, insert scan chains using **Cadence Genus**, and perform fault detection and **Automatic Test Pattern Generation (ATPG)** using **Cadence Modus** to achieve high fault coverage.

---

## 📚 Theory

### 4-Bit Up Counter
A 4-bit up counter is a synchronous sequential circuit that increments its binary output by one on every active clock edge when the enable signal is asserted. The counting sequence is:

```
0000 → 0001 → 0010 → 0011 → ... → 1111 → 0000
```

The next-state relation: **Count_next = Count + 1**  
When the counter reaches its maximum value, it overflows and returns to zero (modulo-16 counting).

### Sequential Circuit Testing Challenges
| Challenge | Description |
|-----------|-------------|
| Limited Controllability | Internal flip-flop states cannot be directly set via primary inputs |
| Limited Observability | Internal states are not directly visible at the output |
| State Dependency | Fault activation and propagation depend on the sequence of clock cycles |

### Scan Chain Architecture
In scan design, flip-flops are replaced by **scan flip-flops**, each containing a multiplexer at its input supporting two modes:

| Mode | Behavior |
|------|----------|
| **Functional Mode** | Circuit behaves normally and performs its intended operation |
| **Scan Mode** | Flip-flops connected in series to form a shift register |

**Scan chain connection:**
```
scan_in → FF0 → FF1 → FF2 → FF3 → scan_out
```

### Scan Test Operation (3 Phases)
```
┌──────────────┐     ┌───────────────┐     ┌────────────────┐
│  Shift-In    │ --> │    Capture    │ --> │  Shift-Out     │
│  Phase       │     │    Phase      │     │  Phase         │
│ (Load test   │     │ (Apply clock, │     │ (Read result,  │
│  data into   │     │  capture      │     │  compare with  │
│  scan chain) │     │  response)    │     │  expected)     │
└──────────────┘     └───────────────┘     └────────────────┘
```

### Fault Model — Stuck-At Faults
| Fault Type | Description |
|-----------|-------------|
| **Stuck-At-0 (SA0)** | Node permanently fixed at logic 0 |
| **Stuck-At-1 (SA1)** | Node permanently fixed at logic 1 |

**Fault Coverage Formula:**
$$\text{Fault Coverage} = \frac{\text{Detected Faults}}{\text{Total Faults}} \times 100\%$$

---

## 🔄 Project Flow

```
RTL Design (Verilog)
       │
       ▼
Constraint Definition (SDC)
       │
       ▼
Logic Synthesis — Cadence Genus
       │
       ▼
DFT Insertion & Scan Chain Implementation
       │
       ▼
Post-DFT Netlist Generation (.v / .sdf / .sdc / .scandef)
       │
       ▼
ATPG Setup — Cadence Modus
       │
       ▼
Fault Modeling & Test Pattern Generation
       │
       ▼
Fault Simulation & Coverage Analysis
       │
       ▼
Test Vector Export & Result Reporting
```

---

## 📁 Design Files

### 1. Verilog RTL Design

```verilog
`timescale 1ns / 1ps
module upcounter_4bit(
    input  wire        clk,
    input  wire        reset,     // Active-high asynchronous reset
    input  wire        enable,    // High to count, low to hold state
    // --- DFT Ports ---
    input  wire        scan_en,
    input  wire        scan_in,
    input  wire        test_mode,
    output wire        scan_out,
    // -----------------
    output reg  [3:0]  count
);

always @(posedge clk or posedge reset) begin
    if (reset) begin
        count <= 4'b0000;
    end else if (enable) begin
        count <= count + 1'b1;
    end
    // If enable is 0, it implicitly holds its state
end

// Tie off scan_out for RTL simulation; Genus overrides this during DFT
assign scan_out = 1'b0;

endmodule
```

### 2. Constraint File (SDC)

```tcl
# SDC Constraints for 4-bit Up-Counter
# Technology : 90nm
# Clock      : 50 MHz => period 20 ns

create_clock -name clk -period 20.0 [get_ports clk]
set_clock_uncertainty 0.5    [get_clocks clk]
set_clock_transition  0.2    [get_clocks clk]

set_input_delay  5.0 -clock clk [get_ports {reset enable test_mode}]
set_output_delay 5.0 -clock clk [get_ports {count}]

set_false_path -from [get_ports scan_en]
set_false_path -from [get_ports scan_in]
set_false_path -to   [get_ports scan_out]

set_driving_cell -lib_cell INVX1 -pin ZN \
    [get_ports {clk reset enable test_mode scan_en scan_in}]

set_load           0.05 [all_outputs]
set_max_transition 0.5  [current_design]
set_max_fanout     20   [current_design]
```

### 3. Genus TCL Script

```tcl
set_db init_lib_search_path /home/install/FOUNDRY/digital/90nm/dig/lib/
set_db library slow.lib

puts "\n>>> Reading RTL Design..."
read_hdl ./upcounter_4bit.v

puts "\n>>> Elaborating Design..."
set_db hdl_unconnected_value 0
elaborate upcounter_4bit
check_design -unresolved

puts "\n>>> Reading SDC Constraints..."
read_sdc ./upcounter_4bit.sdc

set_max_leakage_power 0.0
set_max_dynamic_power 0.0

set_db dft_scan_style muxed_scan
set_db dft_prefix DFT_
define_dft shift_enable -name scan_en_sig -active high scan_en
define_dft test_clock   -name clk_test   -period 10000 clk

puts "\n>>> Synthesizing..."
set_db syn_generic_effort high
syn_generic
set_db syn_map_effort high
syn_map
set_db syn_opt_effort high
syn_opt

puts "\n>>> Inserting Scan Chains..."
check_dft_rules > ./dft_rules_check.rpt
replace_scan
define_scan_chain -name chain1 -sdi scan_in -sdo scan_out -non_shared_output
connect_scan_chains

puts "\n>>> Post-DFT Optimization..."
syn_opt -incr

puts "\n>>> Generating Post-DFT Reports..."
report timing    > ./post_dft_timing.rpt
report area      > ./post_dft_area.rpt
report power     > ./post_dft_power.rpt
report gates     > ./post_dft_gates.rpt
report dft_setup > ./dft_setup.rpt
report dft_chains > ./scan_chains.rpt
check_dft_rules  > ./post_dft_rules.rpt

puts "\n>>> Writing Files for Modus..."
write_hdl       > ./upcounter_4bit_post_dft.v
write_sdf       > ./upcounter_4bit_post_dft.sdf
write_sdc       > ./upcounter_4bit_post_dft.sdc
write_scandef   > ./upcounter_4bit.scandef
write_dft_atpg -library ./upcounter_4bit_post_dft.v -directory ./

puts " Genus Complete!"
gui_show
```

### 4. Modus TCL Script

```tcl
puts "Starting Modus Test Run Script for upcounter_4bit"

set WORKDIR     ./
set CELL        upcounter_4bit
set RESULTS_DIR $WORKDIR/results
file mkdir $RESULTS_DIR

set NETLIST  $WORKDIR/upcounter_4bit_post_dft.v
set LIBRARY  "/home/install/FOUNDRY/digital/90nm/dig/vlog/typical.v"
set TESTMODE FULLSCAN

set ASSIGNFILE ""
set MODEDEF    ""
catch {
    set ASSIGNFILE [exec bash -c \
        "find $WORKDIR -type f -name \"*.pinassign\" | head -n 1"]
    set MODEDEF    [exec bash -c \
        "find $WORKDIR -type f -name \"*.modedef\"   | head -n 1"]
}

puts ">>> Building Test Model"
build_model -cell $CELL -workdir $WORKDIR \
    -designsource $NETLIST -techlib $LIBRARY \
    -designtop $CELL -allowmissingmodules yes

puts ">>> Building Test Mode $TESTMODE"
if {$MODEDEF ne ""} {
    build_testmode -workdir $WORKDIR -testmode $TESTMODE \
        -modedef $MODEDEF -assignfile $ASSIGNFILE
} else {
    build_testmode -workdir $WORKDIR -testmode $TESTMODE \
        -assignfile $ASSIGNFILE
}

puts ">>> Verifying & Reporting Test Structures..."
verify_test_structures  -workdir $WORKDIR -testmode $TESTMODE \
    > $RESULTS_DIR/verify_structures.rpt
report_test_structures  -workdir $WORKDIR -testmode $TESTMODE \
    > $RESULTS_DIR/test_structures.rpt

puts ">>> Building Test Fault Model..."
build_faultmodel -fullfault yes

puts ">>> Generating ATPG Tests..."
create_scanchain_tests -testmode $TESTMODE -experiment scan
create_logic_tests     -testmode $TESTMODE -experiment logic

puts ">>> Generating Coverage Statistics..."
redirect $RESULTS_DIR/test_coverage_logic.rpt {
    report_statistics -experiment logic
}

puts ">>> Writing Verilog Vectors..."
write_vectors -testmode $TESTMODE -inexperiment logic \
    -language verilog -scanformat serial \
    -outputfilename $RESULTS_DIR/test_results.v

puts "Modus Run Complete."
gui_open
```

### 5. Synthesized Post-DFT Netlist

```verilog
module upcounter_4bit(clk, reset, enable, scan_en, scan_in, test_mode,
                      scan_out, count);
  input  clk, reset, enable, scan_en, scan_in, test_mode;
  output scan_out;
  output [3:0] count;

  wire n_0, n_1, n_2, n_3, n_5, n_6, n_7, n_8;
  wire n_10, n_16, n_17, n_21, n_22;

  assign count[3] = scan_out;

  SDFFRHQX4  \count_reg[3] (.RN(n_10),.CK(clk),.D(n_22),.SI(count[2]),.SE(scan_en),.Q(scan_out));
  SDFFRHQX1  \count_reg[2] (.RN(n_10),.CK(clk),.D(n_16),.SI(count[1]),.SE(scan_en),.Q(count[2]));
  SDFFRHQX4  \count_reg[0] (.RN(n_10),.CK(clk),.D(n_17),.SI(scan_in),.SE(scan_en),.Q(count[0]));
  SDFFRHQX1  \count_reg[1] (.RN(n_10),.CK(clk),.D(n_7),.SI(count[0]),.SE(scan_en),.Q(count[1]));

  INVXL   g96  (.A(reset),            .Y(n_10));
  INVXL   g97  (.A(enable),           .Y(n_1));
  NAND2XL g95  (.A(count[0]),.B(count[1]),.Y(n_0));
  INVXL   g93  (.A(n_0),              .Y(n_2));
  OAI211XL g91 (.A0(count[1]),.A1(count[0]),.B0(n_0),.C0(enable),.Y(n_3));
  OAI2BB1XL g89(.A0N(count[1]),.A1N(n_1),.B0(n_3),.Y(n_7));
  OAI21XL g90  (.A0(n_2),.A1(count[2]),.B0(n_5),.Y(n_6));
  INVXL   g87  (.A(n_6),              .Y(n_8));
  NAND2XL g92  (.A(count[2]),.B(n_2), .Y(n_5));
  MX2XL   g103 (.A(count[2]),.B(n_8),.S0(enable),.Y(n_16));
  MX2XL   g104 (.A(enable),.B(n_1),  .S0(count[0]),.Y(n_17));
  NAND2BXL g3  (.AN(n_5),.B(enable), .Y(n_21));
  XNOR2XL g105 (.A(n_21),.B(scan_out),.Y(n_22));
endmodule
```

---

## ⚙️ Cadence Genus Results

### 1. Area Report

| Parameter | Value |
|-----------|-------|
| Module Name | upcounter_4bit |
| Total Cell Count | 17 |
| Cell Area | 171.816 |
| Net Area | 0.000 |
| **Total Area** | **171.816** |
| Operating Condition | Slow (balanced tree) |
| Wireload Model | Enclosed |

> **Observation:** The total synthesized area is 171.816 units, with no additional net area contribution due to the wireload model.

---

### 2. Timing Report

| Timing Parameter | Value (ps) |
|-----------------|-----------|
| Clock Period | 20,000 |
| Output Delay | 5,000 |
| Uncertainty | 500 |
| Data Path Delay | 689 |
| Required Time | 14,500 |
| **Slack** | **13,811** ✅ |

> **Observation:** The timing analysis shows a positive slack of **13,811 ps**, indicating that the design meets timing requirements with a significant margin. The critical path delay is very small compared to the clock period, confirming efficient synthesis.

---

### 3. Power Report

| Category | Total Power (W) | Percentage |
|----------|----------------|-----------|
| Register | 8.0863 × 10⁻⁶ | 85.73% |
| Logic | 1.0665 × 10⁻⁶ | 11.31% |
| Clock | 2.7945 × 10⁻⁷ | 2.96% |
| **Total** | **9.43224 × 10⁻⁶** | 100% |

> **Observation:** Most of the power consumption is dominated by sequential elements (flip-flops), contributing approximately **85.73%** of the total power.

---

### 4. Gate-Level Summary

| Gate Type | Instances | Area |
|-----------|-----------|------|
| INVXL | 4 | 9.083 |
| MX2XL | 2 | 15.138 |
| NAND2XL / NAND2BXL | 3 | 10.596 |
| OAI Gates | 3 | 15.137 |
| XNOR2XL | 1 | 8.326 |
| SDFFRHQX1 | 2 | 49.955 |
| SDFFRHQX4 | 2 | 63.580 |
| **Total** | **17** | **171.816** |

> **Observation:** Sequential elements (scan flip-flops) dominate the area, contributing over **66%** of the total design area, while combinational logic accounts for the remaining portion.

---

### 5. DFT Rule Check

| DFT Parameter | Value |
|---------------|-------|
| Total DFT Violations | 0 ✅ |
| Test Clock Domains | 1 |
| Total Registers | 4 |
| Registers Passing DFT | 4 |
| Registers Failing DFT | 0 |
| Scannable Registers | **100%** |

> **Observation:** No DFT rule violations were detected. All registers are fully scannable, confirming a correct full-scan design implementation.

---

## 🧪 Cadence Modus Results

### 1. DFT Test Structure Summary

*(FULLSCAN Mode)*

| Parameter | Value |
|-----------|-------|
| **Scan Chain Configuration** | |
| Total Flip-Flops | 4 |
| Total Scan Chains | 1 |
| Scan Chain Length | 4 |
| Longest Chain Coverage | 100% |
| Scan Input (SI) Pins | 1 |
| Scan Output (SO) Pins | 1 |
| Scan Enable (SE) Pins | 1 |
| System Clock (SC) Pins | 2 |
| Shift Clock (EC) Pins | 1 |
| **Chain Accessibility** | |
| Controllable Scan Chains | 1 |
| Observable Scan Chains | 1 |
| Chains via Pattern Generator | 0 |
| Chains via MISR | 0 |
| **Design Statistics** | |
| Total Blocks (Flattened) | 108 |
| Total Nets | 250 |
| Primary Inputs | 6 |
| Primary Outputs | 5 |

---

### 2. Test Mode Pin Summary

*(FULLSCAN)*

| Signal Type | Number of Pins |
|-------------|---------------|
| System Clock (SC) | 2 |
| Shift Clock (PC) | 0 |
| Shift Clock (EC) | 1 |
| Oscillator (OSC) | 0 |
| Test Inhibit (TI) | 0 |
| Scan Enable (SE) | 1 |
| Clock Isolation (CI) | 0 |
| Output Inhibit (OI) | 0 |
| Scan Input (SI) | 1 |
| Scan Output (SO) | 1 |

---

### 3. Scan Pin Mapping

| Pin Index | Type | Function | Name |
|-----------|------|----------|------|
| 2 | PI | SC | reset |
| 0 | PI | EC, SC | clk |
| 3 | PI | SE | scan_en |
| 4 | PI | SI | scan_in |
| 10 | PO | SO | scan_out |

---

### 4. Scan Chain Operations and Test Events

| Total Cycle | Rel Cycle | Time (ns) | Seq No. | Test No. | Offset | Len | Event Type |
|:-----------:|:---------:|:---------:|:-------:|:--------:|:------:|:---:|------------|
| 3 | 3 | 160 | 1 | 2 | 0 | 4 | Scan Load – Shift |
| 6 | 6 | 480 | 1 | 2 | 3 | 0 | End Scan Load |
| 8 | 8 | 560 | 1 | 2 | 0 | 4 | Scan Unload – Shift |
| 11 | 11 | 880 | 1 | 2 | 3 | 0 | End Scan Unload |
| 15 | 3 | 160 | 2 | 4 | 0 | 4 | Scan Load – Shift |
| 18 | 6 | 480 | 2 | 4 | 3 | 0 | End Scan Load |
| 21 | 9 | 640 | 2 | 4 | 0 | 4 | Scan Unload – Shift *(Overlap)* |
| 21 | 9 | 640 | 3 | 5 | 0 | 4 | Scan Load – Shift *(Overlap)* |
| 24 | 12 | 960 | 3 | 5 | 3 | 0 | End Scan Load *(Overlap)* |
| 25 | 13 | 960 | 3 | 5 | 0 | 1 | Measure PO |
| 27 | 15 | 1120 | 3 | 5 | 0 | 4 | Scan Unload – Shift *(Overlap)* |
| 27 | 15 | 1120 | 4 | 6 | 0 | 4 | Scan Load – Shift *(Overlap)* |
| 30 | 18 | 1440 | 4 | 6 | 3 | 0 | End Scan Load *(Overlap)* |
| 31 | 19 | 1440 | 4 | 6 | 0 | 1 | Measure PO |
| 33 | 21 | 1600 | 4 | 6 | 0 | 4 | Scan Unload – Shift *(Overlap)* |
| 33 | 21 | 1600 | 5 | 7 | 0 | 4 | Scan Load – Shift *(Overlap)* |
| 36 | 24 | 1920 | 5 | 7 | 3 | 0 | End Scan Load *(Overlap)* |
| 37 | 25 | 1920 | 5 | 7 | 0 | 1 | Measure PO |
| 39 | 27 | 2080 | 5 | 7 | 0 | 4 | Scan Unload – Shift *(Overlap)* |
| … | … | … | … | … | … | … | *pattern continues to Cycle 96* |
| 96 | 84 | 6720 | 14 | 16 | 3 | 0 | End Scan Unload |

---

### 5. Fault Coverage Analysis

#### Initial Fault Coverage (Before Test Generation)

| Fault Type | # Faults | # Tested | # Redundant | # Untested | %TCov | %ATCov |
|-----------|---------|---------|------------|----------|-------|--------|
| Static | 199 | 0 | 0 | 199 | 0.00 | 0.00 |
| Dynamic | 214 | 0 | 0 | 214 | 0.00 | 0.00 |

#### After Scan Test Generation

| Fault Type | # Faults | # Tested | # Redundant | # Untested | %TCov | %ATCov |
|-----------|---------|---------|------------|----------|-------|--------|
| Static | 199 | 98 | 0 | 101 | 49.25 | 49.25 |
| Dynamic | 214 | 62 | 0 | 152 | 28.97 | 28.97 |

#### Final Fault Coverage (After All Test Phases)

| Fault Type | # Faults | # Tested | # Redundant | # Untested | %TCov | %ATCov |
|-----------|---------|---------|------------|----------|-------|--------|
| Static | 199 | 199 | 0 | 0 | **100.00** ✅ | **100.00** ✅ |
| Dynamic | 214 | 62 | 0 | 152 | 28.97 | 28.97 |

> **Observation:** Using scan chains and ATPG, **complete (100%) static fault coverage** was achieved for all stuck-at faults.

#### Stuck-At Fault Summary

| Fault Type | Coverage |
|-----------|---------|
| Stuck-At-0 (SA0) | **100%** ✅ |
| Stuck-At-1 (SA1) | **100%** ✅ |

---

### 6. Final Pattern Statistics

| Test Type | # Sequences |
|-----------|-----------|
| Scan | 1 |
| Logic | 13 |
| **Total** | **14** |

---

### 7. Coverage Improvement During ATPG

| Step | Static Coverage (%) | Dynamic Coverage (%) |
|------|:-------------------:|:--------------------:|
| Initial | 0.00 | 0.00 |
| After Scan | 47.24 | 28.97 |
| After Reset/Set | 52.26 | 28.97 |
| **Final (Logic Tests)** | **100.00** ✅ | 28.97 |

```
Static Coverage Progress
0%       25%      50%      75%     100%
│────────│────────│────────│────────│
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░████  Initial   → 0.00%
░░░░░░░░░░░░░░░░░░░░████████████████  After Scan → 47.24%
░░░░░░░░░░░░░░░░░███████████████████  After R/S  → 52.26%
████████████████████████████████████  Final      → 100.00%
```

---

## 🖥️ GUI Screenshots

### Cadence Genus — Schematic Output
> Cadence Genus synthesis GUI showing the schematic view of the synthesized 4-bit up counter with scan flip-flops.
> *(See Figure 1 in the project report)*

### Cadence Modus — Verify Test Structures
> Cadence Modus DFT Software GUI showing `verify_test_structures` results with all scan chain checks passing and 15 informational messages.
> *(See Figure 2 in the project report)*

---

## ✅ Conclusion

A 4-bit synchronous up counter was successfully designed at the RTL level and implemented through a complete VLSI design and test flow using **Cadence Genus** and **Cadence Modus**.

| Metric | Result |
|--------|--------|
| Timing Slack | +13,811 ps ✅ |
| Total Area | 171.816 units |
| Total Power | 9.43 µW |
| DFT Violations | 0 ✅ |
| Scan Coverage | 100% ✅ |
| Static Fault Coverage | **100%** ✅ |
| Test Patterns Generated | 14 (1 scan + 13 logic) |

Key takeaways:
- All flip-flops were converted into scan flip-flops, ensuring **full controllability and observability**
- DFT rule checks confirmed a clean design with **zero violations and 100% scannability**
- ATPG achieved **100% static (stuck-at) fault coverage**
- Dynamic fault coverage of ~29% highlights the inherent complexity of timing-related faults, indicating potential scope for advanced test techniques
- The project validates that a structured flow — from RTL design to ATPG — ensures reliability, test efficiency, and readiness for silicon implementation

---

## 🛠️ Tools & Technology

| Tool | Version / Node | Purpose |
|------|---------------|---------|
| Cadence Genus | Synthesis Solution 20.1 | RTL Synthesis + DFT Insertion |
| Cadence Modus | DFT Software Solution | ATPG + Fault Simulation |
| Technology Node | 90 nm | Target Fabrication Process |
| Standard Cell Library | `slow.lib` / `typical.v` | Genus & Modus Libraries |
| HDL | Verilog | RTL Description |
| Constraints | SDC | Timing / Design Rules |

---

## 📂 Repository Structure

```
.
├── rtl/
│   └── upcounter_4bit.v            # RTL Verilog design
├── constraints/
│   └── upcounter_4bit.sdc          # Timing constraints
├── scripts/
│   ├── run_genus_dft.tcl           # Cadence Genus script
│   └── run_modus_atpg.tcl          # Cadence Modus script
├── netlist/
│   ├── upcounter_4bit_post_dft.v   # Post-DFT gate-level netlist
│   ├── upcounter_4bit_post_dft.sdf # Standard Delay Format file
│   ├── upcounter_4bit_post_dft.sdc # Post-DFT constraints
│   └── upcounter_4bit.scandef      # Scan chain definition
├── reports/
│   ├── post_dft_timing.rpt
│   ├── post_dft_area.rpt
│   ├── post_dft_power.rpt
│   ├── post_dft_gates.rpt
│   ├── dft_setup.rpt
│   ├── scan_chains.rpt
│   └── post_dft_rules.rpt
├── results/
│   ├── verify_structures.rpt
│   ├── test_structures.rpt
│   ├── test_coverage_logic.rpt
│   └── test_results.v              # ATPG Verilog test vectors
└── README.md
```

---

*Department of Electronics and Communication Engineering | VLSI Design & Testing*
