# Project Glossary and Abbreviations

This is the canonical terminology page for the public UCIe LTSM project documentation. It expands abbreviations and defines how each term is used in this repository.

The definitions explain the implemented model; they are not a substitute for the UCIe specification and do not imply protocol or electrical compliance. Source-code signal details are in the [signal guide](02_ltssm/signals.md), and state-transition details are in the [LTSM guide](02_ltssm/README.md).

## Core architecture, hardware, and interface terms

| Term | Long form | Meaning in this project |
|---|---|---|
| ALM | Adaptive Logic Module | An Intel FPGA logic resource. The checked Cyclone 10 LP reports use logic elements rather than ALMs. |
| APB | Advanced Peripheral Bus | A possible future lightweight control-register interface; no APB block is implemented. |
| ASIC | Application-Specific Integrated Circuit | A custom integrated circuit. Future Cadence work may target an ASIC flow, but current implementation evidence is FPGA-only. |
| BER | Bit Error Rate | The ratio of erroneous bits to transmitted bits. The current finite digital error-count tests are not a statistical BER qualification. |
| CRC | Cyclic Redundancy Check | An error-detection code. Physical sideband CRC generation/checking is outside the current RTL. |
| CSR | Control and Status Register | Software-visible configuration or status storage. A CSR block is planned, not implemented. |
| D2D | Die-to-Die | Communication between separate semiconductor dies, usually within one package. |
| DUT | Design Under Test | The RTL instance exercised by a testbench or UVM environment. |
| DVSEC | Designated Vendor-Specific Extended Capability | A PCI Express capability structure used by UCIe for configuration-related information; no DVSEC block is implemented here. |
| EDA | Electronic Design Automation | Software used to design, simulate, synthesize, place, route, and analyze hardware. Questa and Quartus are the current EDA tools. |
| FDI | Flit-Aware Die-to-Die Interface | A UCIe interface above the PHY-facing control boundary. It is architectural context, not an implemented interface in this repository. |
| Fmax | Maximum Operating Frequency | The highest frequency supported by a particular timed implementation under stated assumptions. The project reports checked 80 MHz slack, not a closed Fmax or UCIe link rate. |
| FPGA | Field-Programmable Gate Array | Reconfigurable hardware used for the current Quartus implementation evidence. |
| FSM | Finite State Machine | Sequential control logic with a finite set of states and defined transitions. The LTSM is hierarchical FSM control. |
| HDL | Hardware Description Language | A language for describing hardware. This project uses SystemVerilog. |
| I/O | Input/Output | Signals crossing a module or device boundary. FPGA external I/O timing and pin placement are not fully constrained. |
| LE | Logic Element | The primary logic-resource unit reported for the checked Cyclone 10 LP build. |
| LEC | Logic Equivalence Checking | Formal comparison of two representations, such as RTL and a synthesized netlist. No LEC result is currently published. |
| LFSR | Linear Feedback Shift Register | A shift register whose feedback taps generate a deterministic pseudo-random sequence. v0.3 uses one 23-bit LFSR per training lane. |
| LTSM | Link Training State Machine | The UCIe link-training controller modeled by `ucie_ltsm`. This is the preferred project term. |
| LTSSM | Link Training and Status State Machine | The similar PCI Express term. It is mentioned only to distinguish it from this repository's UCIe `LTSM` naming. |
| LUT | Look-Up Table | Programmable combinational logic used inside many FPGA logic elements. |
| MB | Mainband | The primary high-width data path of the link, distinguished from the sideband control path. |
| MBINIT | Mainband Initialization | The top-level LTSM phase that initializes mainband-related capability, calibration, and repair control. Most physical operations remain abstract. |
| MBTRAIN | Mainband Training | The top-level LTSM phase containing ordered training substates. v0.3 implements a digital LFSR operation in `DATATRAINCENTER1`. |
| PHY | Physical Layer | The layer responsible for electrical signaling and low-level link operation. This project models digital control, not the complete analog/electrical PHY. |
| PM | Power Management | Control for entering and leaving lower-power link states. |
| P&amp;R | Place and Route | Mapping synthesized logic into device locations and routing connections between them. Quartus Fitter performs the FPGA P&amp;R stage. |
| PVT | Process, Voltage, and Temperature | Conditions used to characterize or time hardware. Quartus reports FPGA device timing models; ASIC PVT evidence is absent. |
| RDI | Raw Die-to-Die Interface | The UCIe adapter/PHY-side interface context used by LINKINIT. Only abstract `rdi_active_i` coordination is modeled. |
| RTL | Register-Transfer Level | A synthesizable hardware description based on registers, combinational logic, and clocked transfers. |
| RX | Receive or Receiver | The direction entering the DUT, such as the received training pattern. |
| SB | Sideband | The lower-bandwidth control path used during initialization and management. |
| SBINIT | Sideband Initialization | The LTSM phase that establishes sideband readiness. This project implements one bounded transaction-level done request/response exchange. |
| TX | Transmit or Transmitter | The direction leaving the DUT, such as the generated training pattern. |
| UCIe | Universal Chiplet Interconnect Express | A die-to-die interconnect standard for chiplet communication. |
| Vref | Reference Voltage | A receiver decision reference used by physical training. The state names are modeled; analog Vref generation/sweeping is not. |

## LTSM top-level state names

| State | Expansion | Project behavior |
|---|---|---|
| `RESET` | Reset | Holds the controller in its reset/safe condition until residence and readiness requirements are met. |
| `SBINIT` | Sideband Initialization | Runs the bounded SBINIT-done transaction or accepts the compatibility completion bypass. |
| `MBINIT` | Mainband Initialization | Sequences six mainband-initialization substates. |
| `MBTRAIN` | Mainband Training | Sequences thirteen mainband-training substates. |
| `LINKINIT` | Link Initialization | Waits for the abstract RDI-active indication before normal operation. |
| `ACTIVE` | Active | Represents normal link operation and accepts retrain or power-management requests. |
| `PHYRETRAIN` | Physical Layer Retraining | Resolves a retrain request to a selected MBTRAIN re-entry point. |
| `TRAINERROR` | Training Error | Represents training failure handling and controlled return to RESET. |
| `L1L2` | L1/L2 low-power states | A combined project representation of the L1 and L2 power-management conditions. |

## MBINIT substate names

These are explanatory expansions of the RTL enum labels. The current design sequences the control states; it does not implement every physical procedure named by them.

| Enum label | Expansion / meaning |
|---|---|
| `MBI_PARAM` | Parameter exchange and initialization. |
| `MBI_CAL` | Calibration control. |
| `MBI_REPAIRCLK` | Clock-lane repair. |
| `MBI_REPAIRVAL` | Valid-lane repair. |
| `MBI_REVERSALMB` | Mainband lane-reversal handling. |
| `MBI_REPAIRMB` | Mainband data-lane repair. |

## MBTRAIN substate names

| Enum label | Expansion / meaning in the control sequence |
|---|---|
| `MBT_VALVREF` | Valid-lane reference-voltage setup. |
| `MBT_DATAVREF` | Data-lane reference-voltage setup. |
| `MBT_SPEEDIDLE` | Speed and idle configuration/training stage. |
| `MBT_TXSELFCAL` | Transmit self-calibration stage. |
| `MBT_RXCLKCAL` | Receive clock-calibration stage. |
| `MBT_VALTRAINCENTER` | Valid-lane training-centering stage. |
| `MBT_VALTRAINVREF` | Valid-lane training reference-voltage stage. |
| `MBT_DATATRAINCENTER1` | Data-lane training centering, stage 1. v0.3 implements the digital LFSR generator/checker control here. |
| `MBT_DATATRAINVREF` | Data-lane training reference-voltage stage. |
| `MBT_RXDESKEW` | Receive deskew stage. |
| `MBT_DATATRAINCENTER2` | Data-lane training centering, stage 2. |
| `MBT_LINKSPEED` | Link-speed selection/confirmation stage. |
| `MBT_REPAIR` | Training repair stage. |

## Sideband and transaction terms

| Term | Long form / definition | Project usage |
|---|---|---|
| Backpressure | A receiver temporarily withholding readiness | `sb_tx_ready_i` can remain low while the sequencer must hold a valid request stable. |
| Handshake | A transfer accepted when both sides assert their required control signals | The sideband ready/valid transfer is accepted when valid and ready are high together. |
| NOP | No Operation | `SB_MSG_NOP` is used as a non-matching sideband message in error tests. |
| REQ | Request | Suffix used for a message that asks the partner to perform or acknowledge an operation. |
| RESP | Response | Suffix used for the reply expected by a request. |
| `SB_MSG_SBINIT_DONE_REQ` | Sideband message: SBINIT Done Request | Internal transaction-level label transmitted during the implemented SBINIT exchange. |
| `SB_MSG_SBINIT_DONE_RESP` | Sideband message: SBINIT Done Response | Internal transaction-level label accepted as the expected successful response. |
| Ready/valid | A two-signal flow-control protocol | A transfer occurs on a clock edge when `valid` and `ready` are both asserted. |
| Retry | A bounded repeat of a request after its response timeout | The default sequencer permits one retry. |
| Retry exhaustion | Consuming the allowed retry budget without success | Causes a protocol-error outcome and LTSM recovery. |
| Responder | Logic that receives a request and returns its response | The current testbench/channel acts as the responder; a partner responder RTL block is not implemented. |
| Timeout | A configured maximum waiting interval | The sideband sequencer and the LTSM have separate parameterized timeout mechanisms. |
| Transaction-level | Modeling an operation as a request/response event rather than physical bit framing | The sideband messages and training channel are transaction/digital abstractions. |

## v0.3 training terms

| Term | Definition | Project usage |
|---|---|---|
| Accepted sample | A training sample consumed on a cycle with `train_busy_o` and `train_rx_valid_i` asserted | LFSRs and the sample counter advance only for accepted samples. |
| Corruption mask | A bit mask XORed into the expected receive pattern | Verification rotates one through sixteen corrupt lane positions. |
| Error count | Accumulated popcount of received-versus-expected differences | `train_error_count_o` saturates at `16'hffff`. |
| Fibonacci LFSR | An LFSR realization that shifts state and computes one feedback bit from selected taps | The project implements polynomial `X^23 + X^21 + X^16 + X^8 + X^5 + X^2 + 1`. |
| Lane | One bit position in the 16-bit digital training pattern | Sixteen lane LFSRs are initialized from eight seeds repeated modulo eight. |
| Polynomial | The tap relationship defining the LFSR recurrence | Verification calculates every 23-bit step independently. |
| Popcount | Population count; the number of `1` bits in a value | Used to count mismatches in `RX XOR expected`. |
| Saturating counter | A counter that remains at its maximum rather than wrapping | The 16-bit error counter stops at 65,535. |
| Seed | Initial LFSR state or simulator PRNG starting value | Lane seeds initialize patterns; regression seeds reproduce randomized scenarios. |
| Strict threshold | A comparison where equality is a failure | Training passes only when `error_count < error_threshold`. |

## Signal and code naming conventions

| Form | Meaning | Example |
|---|---|---|
| `_i` | Module input | `train_rx_valid_i` |
| `_o` | Module output | `train_done_o` |
| `_q` | Registered/current-state value | `sample_count_q` |
| `_d` | Combinational next-state value | `state_d` |
| `_n` | Active-low signal | `rst_n` in testbenches |
| `_ni` | Active-low module input | `rst_ni` |
| `clk` | Clock | `clk_i` |
| `rst` | Reset | `rst_ni` |
| `req` / `resp` | Request / response | `DONE_REQ`, `DONE_RESP` |
| `tx` / `rx` | Transmit / receive | `train_tx_pattern_o`, `train_rx_pattern_i` |
| `vif` | Virtual interface | UVM handle used by class-based components to access the SystemVerilog interface. |
| `LTSM_` | Top-level state enum prefix | `LTSM_ACTIVE` |
| `MBI_` | MBINIT substate enum prefix | `MBI_PARAM` |
| `MBT_` | MBTRAIN substate enum prefix | `MBT_DATATRAINCENTER1` |
| `SB_MSG_` | Sideband message enum prefix | `SB_MSG_SBINIT_DONE_REQ` |
| `OP_` | UVM operation enum prefix | `OP_TRAIN_TRIAL` |

## Verification terminology

| Term | Definition | Project usage |
|---|---|---|
| Agent | A reusable UVM container for sequencer, driver, and monitor components | The LTSM agent drives controls and observes behavior. |
| Assertion | A property that must hold during simulation | SVA checks transition, timeout, training busy/done, threshold, and counter invariants. |
| Constrained-domain random | Seeded random selection restricted to explicit legal values | Used because the installed Starter license cannot run class `randomize()`. |
| Cover property | An SVA statement recording that a target event occurred | The project includes reachability covers for selected states/results. |
| Directed test | A deliberately scripted scenario with known stimulus and outcome | Used for nominal, sideband, LFSR, boundary, and saturation proofs. |
| Driver | A verification component that converts sequence items into signal activity | The UVM driver controls LTSM and training inputs. |
| Explicit sampled coverage | User-maintained counters for defined bins and crosses | Used for v0.3 functional coverage because native covergroups are unlicensed. |
| Functional coverage | Measurement of whether defined behavioral scenarios or value categories occurred | v0.3 reports outcome, error, gap, threshold, and scenario-by-gap bins. |
| Monitor | A passive component that observes DUT activity without driving it | The UVM monitor records state and sideband events. |
| Objection | UVM mechanism that keeps a simulation phase active while a test is running | Tests raise and drop run-phase objections around their sequences. |
| Passive | Observing without driving DUT inputs | The monitor and scoreboard path is passive. |
| Predictor | Logic that calculates the expected outcome independently of the DUT | Sideband totals and v0.3 pattern/error results are predicted. |
| Race-free | Stimulus and sampling are ordered to avoid simulator scheduling ambiguity | Drivers use defined clock-edge timing and delays for deterministic observation. |
| Reference model | An independent behavioral calculation used as the expected result | The v0.3 model reproduces seeds, polynomial progression, masks, and counts. |
| Regression | A set of tests rerun after a change to detect new failures | v0.3 preserves eight deterministic UVM tests, five v0.2 seeds, and directed suites. |
| Scoreboard | A component comparing observed behavior with legal or predicted behavior | Rejects illegal LTSM transitions and checks expected event totals. |
| Self-checking testbench | A testbench that automatically reports pass/fail | The directed tests use `$fatal` on mismatches and print a PASS message on success. |
| Sequence | A UVM object that generates an ordered stream of sequence items | Random and directed UVM scenarios are expressed as sequences. |
| Sequence item / transaction | A data object describing one requested operation | `ltsm_item` carries the operation and training scenario fields. |
| Sequencer | A UVM component that arbitrates sequence items for a driver | Connects the active sequence to the LTSM driver. |
| Smoke test | A short test proving basic compilation and behavior | The directed nominal flow serves as a basic smoke layer. |
| SVA | SystemVerilog Assertions | SystemVerilog language constructs for temporal assertions and coverage. |
| TB | Testbench | Simulation code that instantiates and stimulates the DUT. |
| UCDB | Unified Coverage Database | Questa coverage database format. No native v0.3 UCDB percentage is claimed. |
| UVM | Universal Verification Methodology | A SystemVerilog class library and architecture for reusable verification environments. The installed bundled version is UVM 1.1d. |
| UVM error / fatal | UVM severity levels for recoverable and unrecoverable verification failures | Release regressions require both final counts to be zero. |
| VCD | Value Change Dump | Text waveform format used as an ignored intermediate for reviewed SVG figures. |
| WLF | Wave Log Format | Questa's native waveform database format (`.wlf`); raw WLF files are ignored. |

## Synthesis, timing, and implementation evidence

| Term | Definition | Project usage |
|---|---|---|
| Clock constraint | A timing requirement defining a clock period/frequency | `clk_i` is constrained to 12.5 ns, or 80 MHz, in Quartus. |
| Fitter | Quartus stage that places and routes the synthesized design | Produces device utilization and placement/routing results. |
| Functional netlist | A generated gate/device-primitive representation intended for logical simulation | Versioned `.vo` files are evidence, not editable RTL or timing netlists. |
| Hold slack | Margin for the minimum-delay requirement after a clock edge | Positive reported slack passes the analyzed internal hold paths. |
| Netlist | A connectivity representation of logic elements and signals | The reviewed Quartus functional netlist contains Intel device primitives. |
| Programming image | A device configuration file such as a bitstream | Generated programming files are ignored and not release evidence. |
| QPF | Quartus Project File | Identifies a Quartus project/revision. |
| QSF | Quartus Settings File | Holds source, device, and project assignments. |
| Routing | Selecting physical interconnect paths between placed resources | Performed by the Quartus Fitter. |
| SDC | Synopsys Design Constraints | Tcl-based timing-constraint format used for the 80 MHz clock. |
| Setup slack | Margin before the next clock edge for a maximum-delay path | Positive slack passes the analyzed internal setup paths at the stated constraint. |
| STA | Static Timing Analysis | Timing analysis without dynamic input vectors. Quartus Timing Analyzer performs the current FPGA STA. |
| Standard-cell netlist | ASIC netlist mapped to a characterized cell library | Not present; the published `.vo` file is an FPGA functional netlist. |
| Synthesis | Converting RTL into a technology-mapped logic representation | Quartus Analysis &amp; Synthesis maps the design to Cyclone 10 LP resources. |
| TNS | Total Negative Slack | Sum of negative slack across failing timing paths. Reported setup/hold TNS is zero for analyzed paths. |
| Unconstrained path | A path lacking the timing requirements needed for complete analysis | External I/O delays are absent, so the design is not fully timing-constrained. |
| WNS | Worst Negative Slack | The most negative slack among failing paths. When all slack is positive, the project reports the worst positive setup/hold slack instead. |

## File, documentation, and release terms

| Term | Long form / definition | Project usage |
|---|---|---|
| Annotated tag | A Git tag object containing a message and metadata | Stable milestone snapshots use ordered annotated tags. |
| Artifact / evidence | A reviewable output supporting an engineering claim | Examples are selected SVG waveforms, diagrams, summaries, and versioned netlists. |
| Branch | A movable Git development line | Feature work occurs on `feature/...`; stable releases are merged into `main`. |
| Commit | A recorded Git source snapshot | Design, verification, documentation, and merge checkpoints have exact SHAs. |
| Git | Distributed version-control system | Tracks incremental project history. |
| GitHub Release | A public page associated with a tag and release notes | Used to present milestone scope, evidence, and limitations. |
| Markdown | Plain-text documentation markup (`.md`) | Most project pages use GitHub-flavored Markdown. |
| Mermaid | Text-based diagram syntax rendered by supported Markdown viewers | Used for compact documentation flows; release evidence diagrams are standalone SVGs. |
| Milestone | One bounded, evidence-backed project advancement | v0.3 is the DATATRAINCENTER1 digital LFSR training milestone. |
| `main` | The stable repository branch | It should point to the latest released, reproducible milestone. |
| PDF | Portable Document Format | Private specification PDFs are excluded; no copied specification pages are published. |
| PNG | Portable Network Graphics | Raster format used for temporary visual QA; reviewed release assets are SVG where practical. |
| Release | A stable, documented snapshot with verified evidence and explicit limits | A release does not imply full UCIe compliance. |
| Repository | The version-controlled collection of source, tests, scripts, docs, and selected evidence | Raw generated databases and private references are excluded. |
| SHA | Secure Hash Algorithm; in Git, commonly the object identifier | Exact commit SHAs identify checkpoints. |
| SHA-256 | Secure Hash Algorithm with a 256-bit digest | Used to identify reviewed generated netlist bytes. |
| SVG | Scalable Vector Graphics | Vector format used for colorful waveforms and connection diagrams. |
| Tag | A named Git reference to a source snapshot | Examples include `v0.2-random-uvm` and `v0.3-advanced-training`. |

## Units

| Symbol | Long form | Typical project usage |
|---|---|---|
| ps | picosecond | Questa/VCD base timescale and fine simulation timing. |
| ns | nanosecond | Clock periods, waveform axes, and simulation time. |
| µs / us | microsecond | Reduced simulation parameter values and timer descriptions. |
| ms | millisecond | Default RESET residence and LTSM timeout scale. |
| Hz | hertz | Cycles per second. |
| MHz | megahertz | FPGA clock frequency; the checked project uses 80 MHz. |
| GHz | gigahertz | Common high-speed frequency unit; no GHz PHY timing result is claimed. |
| mV | millivolt | Voltage unit used in physical-interface context; no analog voltage result is modeled. |
| °C | degrees Celsius | Temperature associated with FPGA timing models. |

## Related reference pages

- [Architecture and project boundary](01_ucie_architecture/README.md)
- [States and transitions](02_ltssm/states.md)
- [Signals and waveform pointers](02_ltssm/signals.md)
- [Timers and counters](02_ltssm/timers_counters.md)
- [RTL implementation](04_rtl/README.md)
- [Verification plan](05_verification/testplan.md)
- [Measured v0.3 results](06_results/datatrain_lfsr.md)
- [Version history](versions/README.md)
