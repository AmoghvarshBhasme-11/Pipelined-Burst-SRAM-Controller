# Pipelined Burst SRAM Controller

A Verilog RTL project exploring burst-capable SRAM control, request/response flow control, response buffering, self-checking simulation, and basic performance instrumentation.

> **Research status:** Directed-test evidence is partial. The available log does not establish randomized stress completion or a performance improvement over a baseline. See the [preliminary paper](docs/PAPER_DRAFT.md), [claim matrix](docs/CLAIM_MATRIX.md), [experiment plan](docs/EXPERIMENT_PLAN.md), and [results status](docs/RESULTS.md).

## Configuration

| Property | Value |
|---|---:|
| Data width | 16 bits |
| Address width | 10 bits |
| Behavioral SRAM depth | 1,024 words |
| Request interface | `valid` / `ready` |
| Response interface | `rvalid` / `rready` |
| Burst field | 4 bits; zero is treated as one beat |
| Response storage | Two-entry data array in controller RTL |
| Simulator reported | Vivado XSim |

## Repository layout

```text
rtl/
  sram_cont.v   # sram_controller
  sram.v        # sram_model
  perf.v        # perf_counter
tb/
  tb.v          # tb_top and self-checking testbench
docs/
  RESULTS.md
  CLAIM_MATRIX.md
  EXPERIMENT_PLAN.md
  PAPER_DRAFT.md
```

## Implemented functionality

- Valid/ready request acceptance and rvalid/rready response interface.
- Read and write transactions with burst sequencing.
- Same-data burst writes and synchronous behavioral SRAM model.
- Golden-memory-based read-response checking.
- Directed readback, mixed-traffic, burst, and backpressure scenarios.
- Counters for active cycles, accepted requests, consumed response beats, request-side stalls, and SRAM request pulses.

## Verification status

The available log excerpt shows selected successful readbacks and a backpressure stall/resume event. It does **not** establish randomized stress completion: the visible run only shows the random test starting. Do not claim the complete regression passed until the run reaches the random-test completion marker and final PASS summary.

The response FIFO needs explicit tests for simultaneous response consumption and arrival, particularly when full. See [the experiment plan](docs/EXPERIMENT_PLAN.md).

## Performance counter note

The existing `stall_cycles` counter measures request-side stalls (`valid && !ready`), not response-side backpressure. The response count measures consumed beats (`rvalid && rready`). These simulation counters are not area, timing, or power measurements.

## Running in Vivado XSim

1. Add `rtl/sram.v`, `rtl/sram_cont.v`, and `rtl/perf.v` as design sources.
2. Add `tb/tb.v` as a simulation source and set `tb_top` as the simulation top.
3. Run until the testbench reaches its own completion marker; do not stop at a short fixed simulation duration.
4. Save the complete console log and relevant waveforms as evidence.

## Author

**Amoghvarsh V. Bhasme**  
B.E. Electronics and Communication Engineering | RTL Design
