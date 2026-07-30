# Verification Results

Replace the bracketed placeholders with your actual result details before or after uploading screenshots.

## Simulation environment

- **Tool:** Vivado 2025.2 / XSim
- **RTL language:** Verilog
- **DUT:** Pipelined Burst SRAM Controller
- **Memory configuration:** 1K x 16-bit synchronous SRAM model

## Test summary

| Test case | Purpose | Result |
|---|---|---|
| Multi-write and readback | Verify stored data matches expected values | PASS |
| Back-to-back requests | Verify no unnecessary idle behavior | PASS |
| Burst read | Verify response ordering and termination | PASS |
| Same-data burst write | Verify data replication across burst addresses | PASS |
| Backpressure | Verify FIFO prevents response loss | PASS |
| Randomized stress | Exercise mixed traffic and stalls | PASS |
| Unknown-data checks | Detect X propagation at response interface | PASS |

## Evidence

Add the following images under `docs/images/` and reference them here:

```md
![Burst read waveform](images/burst_read_waveform.png)
![Backpressure waveform](images/backpressure_waveform.png)
![XSim pass log](images/xsim_pass_log.png)
```

## Debug log highlights

- Resolved X propagation by ensuring valid data was sampled only when the SRAM response was valid.
- Corrected the timing relationship between `rvalid` and `rdata`.
- Prevented duplicated and dropped responses with explicit response FIFO control.
- Corrected burst end conditions and address progression.
