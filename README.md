# 10GE MAC: UVM Verification Environment (TX Path)

![SystemVerilog](https://img.shields.io/badge/SystemVerilog-UVM%201.1d-blue)
![SVA](https://img.shields.io/badge/Assertions-SVA-green)
![Simulator](https://img.shields.io/badge/Simulator-Questa%20Sim%2010.7c-orange)
![License](https://img.shields.io/badge/License-LGPL%202.1-lightgrey)

A UVM testbench for the transmit path of a 10-Gigabit Ethernet MAC. The MAC's XGMII output is looped back to its XGMII input, and the packet interface is driven with constrained-random Ethernet frames (runt, normal and jumbo).

> **Scope.** Only the TX path is real RTL. The receive side of the wrapper (`rtl/dut.sv`) is a placeholder that echoes the TX input, so RX checking is **not** yet verified. See [Known limitations](#known-limitations).

## What is verified

The DUT is the OpenCores `xge_mac` core. The TX path takes frames on a packet interface and produces XGMII:

```
pkt_tx_*  ->  Enqueue (pad, CRC-32)  ->  Data FIFO  ->  Dequeue (preamble, IFG)  ->  xgmii_txd / xgmii_txc
```

- Packet interface: 64-bit data, `val`, `sop`, `eop`, `mod`, `full` handshake.
- XGMII: 64 data bits and 8 control bits, 156.25 MHz.
- Minimum frame padding, CRC-32, preamble and start character insertion, inter-frame gap.

## Testbench architecture

```
                 +------------------------- environment -------------------------+
 test -> sequence -> sequencer -> driver ---> pkt_tx_* ---> [ DUT ] ---> xgmii_tx
                                                               |             |
                                                               |        (loopback)
                          TX monitor -> scoreboard <- RX monitor <---- pkt_rx_* / xgmii_rx
                              |
                          subscriber (functional coverage)
                          assertions (SVA, bound to the DUT)
 +----------------------------------------------------------------------------+
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

| Test | Frame type | Description |
|---|---|---|
| `test` | Fixed size | Three frames of a fixed payload length |
| `ethernet_runt_test` | Runt | Random payload 0 to 45 bytes (padded by the MAC) |
| `ethernet_jumbo_test` | Jumbo | Random payload 1500 to 9000 bytes |

<!-- TODO: add the final list once the tests are written and passing -->

## Assertions

- `pkt_tx_sop` is high on the first valid beat of a frame.
- `pkt_tx_eop` is high on the last valid beat.
- `pkt_tx_val` is never asserted while `pkt_tx_full` is high.
- `pkt_tx_sop` and `pkt_tx_eop` are mutually exclusive on a beat.
- `pkt_rx_mod` is zero unless `pkt_rx_eop` is high.

## How to run

Requires Questa Sim (tested with 10.7c) and its bundled UVM 1.1d.

```
cd sim
vsim -do run.do
```

`run.do` compiles the RTL and testbench, starts the simulation with the chosen test, adds the interface and DUT signals to the waveform, and runs to completion. To pick a test, change `+UVM_TESTNAME=<test name>` in `run.do`.

## Results

<!-- TODO: paste the UVM report summary and coverage numbers after a clean run -->

| Test | Result | Notes |
|---|---|---|
| `test` | TODO | |
| `ethernet_runt_test` | TODO | |
| `ethernet_jumbo_test` | TODO | |

Functional coverage: TODO %

Waveform of the first frame on XGMII (start `FB`, preamble, SFD, data):

<!-- TODO: add docs/waveforms/first_frame.png -->

## Known limitations

- **The RX path is a placeholder.** `rtl/dut.sv` drives `pkt_rx_*` from `pkt_tx_*`, so the scoreboard compares the testbench input with itself. Real RX checking needs the RX RTL or a monitor on the XGMII loop wire with an independent reference model.
- The scoreboard reports a mismatch as an informational message, not as a UVM error. <!-- TODO: change once fixed -->
- `xgmii_txc` in the interface is 3 bits wide, but the DUT port is 8 bits. <!-- TODO: remove once fixed -->
- Wishbone, the register block and the interrupt logic are out of scope (tied off).
- The fault state machine is not connected; the fault inputs are tied to 0.

## Findings so far

- The stimulus put the preamble and SFD in the user data, and the MAC adds its own, so every frame carried a duplicate preamble on XGMII.
- The XGMII control bus was truncated to 3 bits in the interface.
- A possible RTL bug in `tx_dequeue.v`: the condition that blocks a new frame during a fault tests `status_local_fault_ctx` twice and never tests `status_remote_fault_ctx`. Not yet reproduced, because the fault inputs are tied to 0.

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
