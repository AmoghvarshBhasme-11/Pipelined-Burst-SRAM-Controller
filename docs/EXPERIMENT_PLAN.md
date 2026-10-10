# Experimental Plan and Required RTL Verification

## Immediate priority: correctness before performance

The controller and testbench should be re-run together in Vivado XSim. A prior screenshot shows simulation stopping around 1,000 ns after the random test starts; increase the run duration or use `run all` and let the testbench terminate itself. The final output must include `TEST 5 RANDOM STRESS DONE`, a zero error count, and `FINAL RESULT: PASS`.

## Important concurrent-event risk to test

In `rtl/sram_cont.v`, `resp_count` is assigned in more than one conditional block in the same clocked process. If a response is consumed from the FIFO and a new SRAM response is captured in the same cycle, separate nonblocking assignments may compete, with the later assignment taking precedence. If the FIFO is full at the beginning of that cycle, the incoming response may also be rejected by the old-value full check even if an entry is being consumed that cycle. This is a concrete verification risk, not proof that a failure has occurred in a specific run.

Before changing the RTL, add a directed test that aligns:
1. an already-valid output response with `rready=1`,
2. nonzero response FIFO occupancy,
3. `sram_rvalid=1` in the same cycle,
4. and, separately, a full response FIFO.

Then check response order, count, and data. If the test fails, revise FIFO next-state logic so simultaneous push/pop is handled atomically. Re-run the entire regression after any fix.

## Testbench checks to add

- While `rvalid && !rready`, assert `rvalid` remains high and `rdata` remains stable until handshake.
- At quiescence, compare expected response obligations against consumed responses; verify no missing or extra beat.
- Record maximum FIFO occupancy and flag overflow/underflow.
- Test burst lengths 1, 2, 4, 8, and 15.
- Test addresses near 0 and 1023, including bursts that approach or cross the address boundary. Decide whether wraparound is supported; otherwise reject illegal bursts explicitly.
- Test deterministic random seeds and print each seed in the log.
- Use an explicit timeout that fails the simulation if the testbench hangs.

## Metrics collection

Extend the instrumentation to distinguish:
- request-side stall cycles: `valid && !ready`;
- response-side stall cycles: `rvalid && !rready`;
- consumed response beats: `rvalid && rready`;
- generated/returned SRAM response beats: `sram_rvalid`;
- maximum FIFO occupancy;
- latency from request handshake to corresponding response handshake.

Use a CSV record per run with: design revision, simulator version, seed, workload, measurement cycles, read requests, write requests, consumed responses, request stalls, response stalls, SRAM request pulses, max FIFO occupancy, errors, mean latency, max latency.

## Fair baseline

Implement or select a documented single-beat reference controller. Do not compare a feature-rich burst controller with a baseline under different traffic. Use the same SRAM model, clock, reset policy, request sequence, random seeds, and measurement window. Report correctness separately from throughput and stall metrics. Do not infer area or power from simulation counters.

## Publication gate

Do not submit a paper until:
- the final regression passes;
- concurrent push/pop and full-buffer cases pass;
- raw logs and scripts are committed;
- baseline results are measured;
- related-work metadata is verified;
- the manuscript's tables contain only reproducible numbers.
