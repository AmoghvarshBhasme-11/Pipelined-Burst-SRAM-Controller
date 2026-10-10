# Verification Results and Evidence Status

## Simulation configuration
- RTL language: Verilog
- Simulator reported in the project: Vivado XSim
- Behavioral memory: 1,024 words × 16 bits
- Testbench top: `tb_top`

## Evidence status

| Scenario | Status based on available evidence | Notes |
|---|---|---|
| Directed writes/readback | Partial pass evidence | Several PASS READ lines are visible |
| Mixed transactions and bursts | Partial evidence | Scenarios exist; full edge-case coverage is not established |
| Backpressure | Stall/resume visible | No-loss/no-duplicate behavior for all concurrent events is not established |
| Randomized stress | Not established | Available log stops shortly after random stress starts |
| Final performance report | Not established | An intermediate counter snapshot is not a final report |
| Baseline comparison | Not performed | No speed or throughput improvement can be claimed |
| Area, timing, power | Not measured | Requires appropriate synthesis/implementation or power methodology |

## Preliminary counter snapshot

A previously observed snapshot showed:

| Counter | Value |
|---|---:|
| Total cycles | 96 |
| Read requests | 6 |
| Write requests | 8 |
| Consumed response beats | 13 |
| Request-side stall cycles | 11 |
| SRAM request pulses | 25 |

Derived snapshot ratios:
- Request-stall ratio: 11/96 = 11.46%.
- Consumed-response rate: 13/96 = 0.135 beats/cycle.
- SRAM-request rate: 25/96 = 0.260 request pulses/cycle.

These are **preliminary snapshot values, not final benchmark results**. Reproduce them at a defined end-of-test measurement point before using them in the paper.

## Required final evidence

1. Complete XSim log with random-test completion, zero errors, and an explicit final PASS marker.
2. Waveform showing `rvalid` and `rdata` stability during `rvalid && !rready`.
3. Directed tests for simultaneous response arrival/consumption, including a full FIFO.
4. End-of-test metrics and deterministic random seed.
5. Baseline results from identical workloads.
6. Raw logs and waveforms committed to the repository.

See [Claim Matrix](CLAIM_MATRIX.md) and [Experiment Plan](EXPERIMENT_PLAN.md).
