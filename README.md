# 10GE MAC: UVM Verification Environment (TX Path)

![SystemVerilog](https://img.shields.io/badge/SystemVerilog-UVM%201.1d-blue)
![SVA](https://img.shields.io/badge/Assertions-SVA-green)
![Simulator](https://img.shields.io/badge/Simulator-Questa%20Sim%2010.7c-orange)
![License](https://img.shields.io/badge/License-LGPL%202.1-lightgrey)

A UVM testbench for the transmit path of a 10-Gigabit Ethernet MAC. The MAC's XGMII output is looped back to its XGMII input, and the packet interface is driven with constrained-random Ethernet frames (runt, normal and jumbo). The verification plan was written from the specification alone, treating the DUT as a black box.

> **Scope.** Only the TX path is real RTL. The receive side of the wrapper (`rtl/dut.sv`) is a placeholder that echoes the TX input, so RX checking is **not** yet verified. See [Known limitations](#known-limitations). Items marked *planned* are not built yet.

## Contents

1. [What is verified](#what-is-verified)
2. [Interfaces and frame format](#interfaces-and-frame-format)
3. [Clocks and reset](#clocks-and-reset)
4. [Loopback strategy](#loopback-strategy)
5. [Testbench architecture](#testbench-architecture)
6. [Tests](#tests)
7. [Assertions and coverage](#assertions-and-coverage)
8. [Verification plan summary](#verification-plan-summary)
9. [How to run](#how-to-run)
10. [Results](#results)
11. [Known limitations](#known-limitations)
12. [Findings so far](#findings-so-far)
13. [Open specification questions](#open-specification-questions)
14. [Future work](#future-work)
15. [Repository layout](#repository-layout)
16. [Credits and license](#credits-and-license)

## What is verified

The DUT is the OpenCores `xge_mac` core. The TX path takes frames on a packet interface and produces XGMII:

```
pkt_tx_*  ->  Enqueue (pad, CRC-32)  ->  Data FIFO (128 x 64 bit)  ->  Dequeue (preamble, IFG)  ->  xgmii_txd / xgmii_txc
```

- Padding of short frames to the 64-byte minimum.
- CRC-32 generation (FCS) and its position at the end of the frame.
- Preamble, SFD and start/terminate character insertion.
- Inter-frame gap with deficit-idle-count (DIC) behaviour, so the average gap is at least 12 bytes.
- Start of frame in lane 0 or lane 4.
- Flow control through `pkt_tx_full`, and flow-through of frames larger than the FIFO.
- Reaction to local and remote fault inputs (remote-fault message or idle, no new frame). *Fault inputs are tied to 0 in this setup, so this is planned.*

## Interfaces and frame format

| Interface | Signals | Notes |
|---|---|---|
| Packet TX | `pkt_tx_data[63:0]`, `pkt_tx_val`, `pkt_tx_sop`, `pkt_tx_eop`, `pkt_tx_mod[2:0]`, `pkt_tx_full` | User sends words; must stop when `pkt_tx_full` is high |
| Packet RX | `pkt_rx_data[63:0]`, `pkt_rx_val`, `pkt_rx_sop`, `pkt_rx_eop`, `pkt_rx_mod[2:0]`, `pkt_rx_err`, `pkt_rx_avail`, `pkt_rx_ren` | RX is a placeholder in this repo |
| XGMII | `xgmii_txd[63:0]`, `xgmii_txc[7:0]` (and RX equivalents) | One control bit per byte lane. Idle = `0x07`, start = `0xFB`, terminate = `0xFD` |

**Frame as the user sends it** (first byte in the top byte of the word):

| Word | Content |
|---|---|
| 0 | Destination MAC (6 bytes) + source MAC bits [47:32] |
| 1 | Source MAC bits [31:0] + EtherType (2 bytes) + first two payload bytes |
| 2 to N | Payload, 8 bytes per word |
| last | Remaining payload bytes |

- `pkt_tx_mod` gives the number of valid bytes in the last word (0 means all 8).
- The MAC adds the preamble, SFD and CRC-32 itself, and pads frames shorter than 64 bytes. **The user data must not contain a preamble** (see [Findings](#findings-so-far)).
- Runt means a payload of 0 to 45 bytes (frame under 64 bytes on the wire). Jumbo means a payload above 1500 bytes.

## Clocks and reset

- `clk_156m25`, `clk_xgmii_tx` and `clk_xgmii_rx` run at 156.25 MHz (6.4 ns). In this testbench one 100 MHz clock drives all of them. <!-- TODO: change to 156.25 MHz when the clock generator is updated -->
- Resets `reset_156m25_n`, `reset_xgmii_tx_n` and `reset_xgmii_rx_n` are active low and must be released within two cycles of each other. The testbench releases them together after 100 ns.
- The Wishbone clock and reset are present on the port list but tied off.
- Crossings between clock domains are at the FIFOs (Gray-code pointers inside `generic_fifo.v`).

## Loopback strategy

`xgmii_rxd` and `xgmii_rxc` are connected directly to `xgmii_txd` and `xgmii_txc`. This gives a self-contained setup with no PHY model: whatever the MAC transmits, it receives.

- **A tap monitor on the loop wire** (planned) decodes the XGMII stream and checks it against an independent reference model (padding, CRC-32, preamble, IFG).
- **A round-trip scoreboard** compares frames sent on `pkt_tx` with frames read from `pkt_rx`.
- **An optional shim** on the loop wire (planned) could corrupt a bit or drop a word, to reach the CRC-error, runt, fragment and fault paths. It is a pass-through unless a test turns it on.
- **Limit:** a loopback can hide a bug that is the same on both sides (for example, the same wrong bit order in TX and RX). The independent reference model is what catches that.

## Testbench architecture

```
 test -> sequence -> sequencer -> driver --> pkt_tx_* --> [ DUT ] --> xgmii_tx
                                                             |            |
                                                             |       (loopback)
                        TX monitor -> scoreboard <- RX monitor <-- pkt_rx_* / xgmii_rx
                            |
                        subscriber (functional coverage)
                        assertions (SVA, bound to the DUT)
```

| Component | File | Role |
|---|---|---|
| Sequence item | `tb/seq_item.sv` | One frame: MAC addresses, EtherType, payload, packet-interface fields |
| Sequence | `tb/ether_sequence.sv` | Builds a frame and packs it into 64-bit words |
| Config object | `tb/config_object.sv` | Frame type (runt / jumbo), size constraints, agent mode |
| Driver | `tb/driver.sv` | Drives `pkt_tx_*`, respects `pkt_tx_full`, computes `mod` |
| Monitor | `tb/ethernet_monitor.sv` | One class, used as a TX monitor and an RX monitor |
| Agent | `tb/ethernet_agent.sv` | Active TX agent and passive RX agent |
| Scoreboard | `tb/scoreboard.sv` | Compares transmitted and received frames |
| Subscriber | `tb/subscriber.sv` | Covergroups: frame length, MAC addresses, EtherType, control signals |
| Assertions | `tb/assertions.sv` | SVA for the packet interface, bound into the DUT |
| Environment | `tb/environment.sv` | Builds and connects everything |

## Tests

| Test | Frame type | Status |
|---|---|---|
| `test` | Fixed size (64-byte payload), three frames | Implemented |
| `ethernet_runt_test` | Runt, random payload 0 to 45 bytes | Implemented <!-- TODO: confirm --> |
| `ethernet_jumbo_test` | Jumbo, random payload 1500 to 9000 bytes | Implemented <!-- TODO: confirm --> |

To run a test, set `+UVM_TESTNAME=<test name>` in `sim/run.do`. The full planned list is in the [verification plan summary](#verification-plan-summary).

## Assertions and coverage

**SVA (bound into the DUT):**
- `pkt_tx_sop` is high on the first valid beat of a frame.
- `pkt_tx_eop` is high on the last valid beat.
- `pkt_tx_val` is never asserted while `pkt_tx_full` is high.
- `pkt_tx_sop` and `pkt_tx_eop` are mutually exclusive on a beat.
- `pkt_rx_mod` is zero unless `pkt_rx_eop` is high.

**Functional coverage (subscriber):**
- Packet-interface signals: `val`, `sop`, `eop`, `mod`.
- Frame fields: preamble and SFD, destination and source MAC ranges, EtherType, payload size (runt, normal, jumbo, illegal above 9000 bytes).

## Verification plan summary

The plan was written from the specification: requirements with IDs, architecture and clock-domain analysis, signal and waveform scenarios, a coverage plan and a test plan with a traceability matrix. The tests below are **planned** unless listed as implemented above.

| Area | Planned tests | Focus |
|---|---|---|
| Reset and bring-up | 7 | Reset release skew (0, 1, 2 cycles), reset mid-frame, loop-wire check |
| Transmit path | 15 | Length sweep 1 to 130 bytes, all `mod` values, back-to-back frames, IFG and DIC, FIFO full, large frames, start in lane 4 |
| Receive path (round trip) | 18 | Frame delivery for all terminate lanes, read pacing, overflow, pause frames sent as user data. Error, runt and fragment tests need the shim |
| Fault handling | 7 | Local and remote fault sequences, fault during a frame, recovery. All need the shim |
| Clocking and stress | 6 | Random clock phase, clock offset, full-rate duplex traffic, soak with random seeds |

**Coverage plan:** ten covergroups (frame length and `mod`, FIFO full, IFG and alignment, receive frames, error timing, read pacing, faults, reset, clock phase, stress), plus code coverage goals. Directed tests are written for coverage holes and waivers are documented.

**Regression tiers:** sanity (every change), nightly (all directed and random tests, 10 seeds), weekly (100 seeds and coverage merge), closure (directed tests for holes).

## How to run

Requires Questa Sim (tested with 10.7c) and its bundled UVM 1.1d.

```
cd sim
vsim -do run.do
```

`run.do` compiles the RTL and testbench, starts the simulation with the chosen test, adds the interface and DUT signals to the waveform, and runs to completion.

## Results

<!-- TODO: paste the UVM report summary and coverage numbers after a clean run -->

| Test | Result | Notes |
|---|---|---|
| `test` | TODO | |
| `ethernet_runt_test` | TODO | |
| `ethernet_jumbo_test` | TODO | |

Functional coverage: TODO %

<!-- TODO: add docs/waveforms/first_frame.png: first XGMII frame (start FB, preamble, SFD, data) -->

## Known limitations

- **The RX path is a placeholder.** `rtl/dut.sv` drives `pkt_rx_*` from `pkt_tx_*`, so the scoreboard compares the testbench input with itself. Real RX checking needs the RX RTL, or a monitor on the XGMII loop wire with an independent reference model.
- The scoreboard reports a mismatch as an informational message, not as a UVM error. <!-- TODO: remove once fixed -->
- `xgmii_txc` in the interface is 3 bits wide, but the DUT port is 8 bits. <!-- TODO: remove once fixed -->
- Wishbone, the register block and the interrupt logic are out of scope (tied off).
- The fault state machine and the clock-domain synchronisers for status signals are not connected; the fault inputs are tied to 0.

## Findings so far

- **Doubled preamble.** The stimulus put the preamble and SFD in the user data, and the MAC adds its own, so every frame carried a second preamble inside the frame on XGMII.
- **XGMII control bus truncated.** The interface declared `xgmii_txc` as 3 bits, so idle showed as `7` instead of `FF`.
- **Possible RTL bug.** In `tx_dequeue.v`, the condition that allows a new frame to start tests `status_local_fault_ctx` twice and never tests `status_remote_fault_ctx`. Not yet reproduced, because the fault inputs are tied to 0.

## Open specification questions

The specification has gaps that decide what a checker may assert. The ones that matter most:

1. **Shim allowed?** Can a pass-through block be placed on the loop wire to inject errors and faults? Without it, error and fault tests cannot run.
2. **Frame conventions.** Are the preamble and FCS part of the frame the user sees, and does the 64-byte minimum include the FCS?
3. **Fault state machine.** The section is empty, so fault behaviour can only be recorded.
4. **RX read-out.** The RX dequeue section is empty (latency and legal read patterns).
5. **Runts and fragments.** Are they dropped or delivered with `pkt_rx_err`?
6. **`pkt_tx_full` threshold, IFG limits, maximum frame size and gaps in `pkt_tx_val`** are not defined.

Other spec issues: a register base address of `0x180` versus `0x00` with an 8-bit address, a missing figure, and typos in one table. In total, 24 questions are logged for the designer.

## Future work

- Replace the RX placeholder with real RX checking: a loop-wire monitor with an independent CRC-32 and padding model.
- Make the scoreboard raise a UVM error on a mismatch.
- Fix the interface width and the stimulus preamble, and rerun all tests.
- Add the optional error and fault injection shim, then the fault tests.
- Run the directed and random tests from the plan, collect coverage, and close holes.

## Repository layout

```
rtl/      design files (OpenCores xge_mac TX path) and the dut.sv wrapper
tb/       UVM testbench: interface, agents, scoreboard, coverage, assertions
tests/    base test and individual tests
sim/      run.do and simulation scripts
docs/     architecture notes and waveform screenshots
results/  run summaries
```

## Credits and license

The RTL is the OpenCores **10GE MAC** core by A. Tanguay (<http://www.opencores.org/cores/xge_mac/>), released under the GNU LGPL 2.1. The original copyright headers are kept in `rtl/`. The testbench, tests and scripts in this repository are my own work and are released under the same license.
