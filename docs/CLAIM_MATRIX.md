# Claim-to-Evidence Matrix

This file intentionally separates what the repository contains from what the available simulation evidence proves.

| ID | Claim | Current evidence | Status | What is needed |
|---|---|---|---|---|
| C1 | Directed transaction/readback correctness | Log excerpt contains several PASS READ lines and test completion markers for directed tests | Partially supported | Complete final log, clean error count, repeated run |
| C2 | Burst operation correctness | Testbench contains burst read and same-data burst write scenarios | Partially supported | Boundary lengths, final address, exact response count and ordering |
| C3 | Backpressure preserves responses | Testbench forces `rready=0`, then resumes; displayed log shows stall/resume | Partial | Assert data stability, conservation, no duplicates/loss under simultaneous events and full buffer |
| C4 | Randomized stress completed | Available log only shows random stress start | Not established | Run to `TEST 5 RANDOM STRESS DONE` and final PASS marker |
| C5 | Final performance results | One screenshot snapshot contains counters | Preliminary only | End-of-test report from same completed run; counter semantics |
| C6 | Candidate outperforms baseline | No comparable baseline measurement | Not established | Same workload, timing, seed, and metric definitions for candidate and baseline |
| C7 | Timing/area/power improvement | No synthesis or physical measurement | Not established | Synthesis/implementation reports or appropriate power methodology |

## Counter definitions in current RTL

- `total_cycles`: active clock cycles after reset.
- `read_req_count` / `write_req_count`: accepted request handshakes, counted when `valid && ready`.
- `response_count`: consumed response beats, counted when `rvalid && rready`.
- `stall_cycles`: request-side stall cycles, counted when `valid && !ready`; this is not response-side backpressure.
- `sram_access_count`: cycles with `sram_req` asserted.

## Snapshot-derived values (not final benchmark results)

The reported snapshot was total_cycles=96, read_req_count=6, write_req_count=8, response_count=13, stall_cycles=11, sram_access_count=25.

- Request-stall ratio = 11 / 96 = 11.46%.
- Consumed-response rate = 13 / 96 = 0.135 response beats/cycle.
- SRAM-request rate = 25 / 96 = 0.260 request pulses/cycle.

Do not call these end-of-test or comparative results unless a completed simulation produces the same values at its final measurement point.
