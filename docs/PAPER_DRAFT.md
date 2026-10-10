# Research Paper Draft (Preliminary)

## A Verification-Oriented Study of a Burst-Capable SRAM Controller with Valid/Ready Flow Control

**Author:** Amoghvarsh V. Bhasme  
**Affiliation:** Department of Electronics and Communication Engineering, JSS Academy of Technical Education, Bengaluru, India  
**Status:** Preliminary manuscript draft — experimental validation incomplete

## Abstract

Small on-chip memories are often accessed through controller logic that must coordinate request acceptance, synchronous memory timing, burst sequencing, and response consumption. A controller can return correct data under nominal traffic yet fail when the consumer applies backpressure or when responses arrive close together. This work documents a parameterized Verilog SRAM-controller prototype with a 16-bit data path, 10-bit word address, a 1,024-location behavioral SRAM model, valid/ready request acceptance, burst reads, same-data burst writes, and a two-entry response buffer. A golden-memory testbench is used to check read responses, while performance counters record accepted read and write requests, consumed responses, request-side stall cycles, and SRAM request pulses. The current directed simulation log shows successful readbacks and a backpressure stall/resume sequence; however, the available run ends shortly after randomized testing begins. Consequently, randomized-test completion, response-conservation under all concurrent events, and any performance advantage remain unverified. Rather than claim a new controller architecture, this paper proposes a reproducible evaluation methodology for measuring data integrity, response conservation, latency, throughput, and backpressure behavior against a clearly specified baseline. The main intended contribution is an evidence-driven verification and measurement study; novelty and performance claims are reserved until the full experiment is completed.

**Keywords:** SRAM controller, Verilog, burst transfer, valid-ready handshake, backpressure, response buffering, self-checking verification, RTL performance counters.

## 1. Introduction

On-chip SRAM interfaces need control logic that sequences requests, drives addresses and write data, and returns read data at the correct time. When a requester and a response consumer can independently apply flow control, the controller must preserve transaction order and avoid losing or duplicating responses. Burst operations add another concern: addresses and beat counts must advance consistently until the final beat.

This project implements a compact controller around a synchronous behavioral SRAM model. The request interface uses `valid` and `ready`; the response interface uses `rvalid` and `rready`. A burst-length field controls consecutive accesses. A small response FIFO is intended to absorb read data while the consumer is stalled. A separate performance-counter module records selected events.

The project is not presented as the first SRAM controller with bursts, buffering, or ready/valid flow control. These are established design techniques. The research question proposed here is narrower: **how can response integrity and performance under burst traffic and downstream backpressure be measured reproducibly in a small RTL controller, and what measurable trade-offs appear against a simpler reference design?**

### Contributions intended for evaluation

1. An openly inspectable Verilog prototype with a stated 16-bit data path and 1,024-word memory model.
2. A golden-memory-based testbench with directed write/readback, mixed traffic, burst, and backpressure scenarios.
3. A claim-to-evidence matrix that separates demonstrated behavior from incomplete tests.
4. A measurement plan for response conservation, latency, throughput, stall cycles, and buffer occupancy.
5. A proposed controlled comparison against a baseline using identical traffic and seeds.

Items 3–5 are research-process contributions; they do not by themselves establish architectural novelty or a measured improvement.

## 2. Related Work and Positioning

Burst-mode SRAM controllers and FSM-based control schemes have been described in prior literature, including the 2025 paper “Design of Burst Mode Enabled SRAM Controller Using FSM” (DOI: 10.1109/ICITEICS64870.2025.11341477). Therefore, burst operation and FSM-based sequencing alone are not sufficient novelty claims.

OpenTitan's SRAM-controller verification documentation describes a structured design-verification environment. Work on SystemVerilog-based memory-controller verification also discusses test plans, scoreboards, assertions, and functional coverage. These precedents make it important to position a golden-memory checker or a collection of directed tests as standard verification practice rather than a new verification theory.

The proposed distinction is an **experimentally reproducible evaluation of response conservation under backpressure and simultaneous events**, supported by explicit counters and a fair baseline. This positioning remains provisional: a publication-quality related-work review must search IEEE Xplore, ACM Digital Library, Google Scholar, and relevant open-source RTL repositories using documented search terms, date ranges, and inclusion criteria. No claim of “first” or “state of the art” is made.

### Sources to verify and cite in the final manuscript

1. C. Paramasivam and G. M. Sri, “Design of Burst Mode Enabled SRAM Controller Using FSM,” 2025, DOI: [10.1109/ICITEICS64870.2025.11341477](https://doi.org/10.1109/ICITEICS64870.2025.11341477).
2. OpenTitan, “SRAM Controller DV,” [https://opentitan.org/book/hw/ip/sram_ctrl/dv/index.html](https://opentitan.org/book/hw/ip/sram_ctrl/dv/index.html).
3. “A System Verilog Approach for Verification of Memory Controller,” IJERT. The exact bibliographic metadata, authors, year, volume, issue, and pages must be checked before submission.
4. “Burst-Mode Asynchronous Controllers on FPGA,” Wiley, [https://onlinelibrary.wiley.com/doi/10.1155/2008/926851](https://onlinelibrary.wiley.com/doi/10.1155/2008/926851). Confirm the final citation metadata against the publisher page.

## 3. Design Overview

### 3.1 Configuration

| Property | Current repository configuration |
|---|---|
| RTL language | Verilog |
| Data width | 16 bits |
| Address width | 10 bits |
| Behavioral memory depth | 1,024 words |
| Request interface | `valid` / `ready` |
| Response interface | `rvalid` / `rready` |
| Burst length field | 4 bits |
| Zero burst-length handling | Controller coerces zero to one beat |
| Response storage | Two-entry data array in controller RTL |
| Performance counters | Active cycles, accepted read/write requests, consumed responses, request-side stall cycles, SRAM request pulses |
| Simulation environment reported by project | Vivado XSim |

The 4-bit burst field represents values from 0 through 15. In the current controller, a zero value is converted to a one-beat transaction, so the effective documented burst length is 1–15 beats. This behavior should be confirmed against any intended protocol specification before freezing the interface.

### 3.2 Request and memory sequencing

In the IDLE state, the controller accepts a request when `valid && ready` is true and captures its address, write data, operation type, and burst length. In the WAIT state, write bursts issue consecutive SRAM request pulses and increment the address. Read requests are issued while a read is not pending and the response FIFO is not full; returned read data advances the address and burst count.

### 3.3 Response handling

The controller can place SRAM read data directly on the response interface when the output is free, or store it in the response array when the output is occupied. The intended behavior is to preserve response order while `rready` is low. This behavior requires further verification for simultaneous response consumption and SRAM response arrival, including full-buffer boundary conditions. The present draft does not assume these corner cases are already correct.

### 3.4 Performance counters and definitions

The existing `perf_counter` module counts:
- **Total cycles:** each clock cycle after reset.
- **Read requests:** cycles where `valid && ready && !we`.
- **Write requests:** cycles where `valid && ready && we`.
- **Responses:** cycles where `rvalid && rready` (consumed response beats, not merely generated responses).
- **Stall cycles:** cycles where `valid && !ready` (request-side stalls).
- **SRAM accesses:** cycles where `sram_req` is asserted.

The existing `stall_cycles` counter is not a response-backpressure counter. A separate counter for `rvalid && !rready` should be added before making claims about downstream backpressure frequency. The SRAM counter measures request pulses; it should not be described as physical memory energy, area, or power.

## 4. Verification Methodology

The testbench maintains a golden memory and a queue of expected read addresses. Accepted read responses are compared with the expected word; unexpected responses and data mismatches increment an error counter and stop the simulation. A separate check flags unknown read data when `rvalid` is asserted.

The current directed scenarios are:
1. Single-word writes followed by burst readback.
2. Same-data write burst followed by readback.
3. Mixed single writes and reads.
4. Read-response backpressure, with `rready` held low and then re-enabled.
5. Randomized write/read bursts.

The available log excerpt shows PASS readbacks in the directed scenarios and a stall/resume sequence. It shows the randomized test starting but not completing. Thus, the present evidence supports partial directed-test success only; it does not support a completed random-stress claim.

### Required additional checks

- Run the simulation to its actual completion marker, not merely a fixed 1,000 ns window.
- Assert that every accepted read request produces exactly the expected number of consumed response beats.
- Check response ordering and data stability while `rvalid && !rready`.
- Exercise simultaneous `rvalid && rready` consumption and a new SRAM response.
- Exercise a full response buffer when a new SRAM response arrives.
- Test reset during idle and define whether reset during an active transaction is supported.
- Check burst lengths 1 and 15, first/last memory addresses, and boundary behavior near address 1023.
- Use deterministic random seeds and print the seed in the final report.
- End with a nonzero failure count or an explicit failure marker if any test fails.

## 5. Experimental Design

A meaningful performance claim requires a baseline and identical conditions. The proposed comparison is:

- **Candidate:** current controller, after correctness issues are resolved and regression tests pass.
- **Baseline:** a simple single-beat controller without response buffering or burst aggregation, or another explicitly documented reference implementation.
- **Fairness:** identical memory timing, clock period, workload, random seed, reset policy, and measurement interval. Report any feature differences that make a comparison imperfect.
- **Workloads:** isolated single-beat accesses, sequential bursts of 2/4/8/15 beats, mixed reads and writes, and controlled response stalls at several durations.
- **Repetitions:** at least 10 deterministic seeds for randomized workloads, with all seeds and aggregate statistics reported. If the design is deterministic and all seeds are not independent in a statistical sense, explain that limitation.

### Metrics

| Metric | Definition |
|---|---|
| Read/write request count | Accepted request handshakes, split by operation |
| Response beats consumed | Count of `rvalid && rready` |
| Response conservation | Accepted read-beat obligations compared with consumed responses at quiescence |
| Mean read latency | Cycles from accepted read request to corresponding consumed response; define burst latency separately |
| Maximum latency | Maximum measured request-to-response latency over the workload |
| Throughput | Consumed response beats divided by measurement cycles |
| Request stall ratio | Request-stall cycles divided by measurement cycles |
| Response stall ratio | Cycles with `rvalid && !rready` divided by measurement cycles |
| SRAM request rate | `sram_req` pulses divided by measurement cycles |
| Maximum FIFO occupancy | Highest observed response-buffer occupancy |
| Errors | Data mismatches, unknown values on valid data, missing/extra/out-of-order responses |

Report counts as well as ratios. Throughput and stall ratios must use the same clearly stated measurement window. Burst requests and response beats must not be conflated.

## 6. Results: Current Evidence and Missing Measurements

The currently available screenshot/log snapshot shows these counter values at one observed point: total cycles = 96, read request count = 6, write request count = 8, response count = 13, request stall cycles = 11, and SRAM request pulses = 25. If the counters were sampled consistently at that point, the corresponding preliminary ratios are:

- Request-stall ratio: 11/96 = **11.46%**.
- Consumed-response rate: 13/96 = **0.135 response beats/cycle**.
- SRAM-request rate: 25/96 = **0.260 request pulses/cycle**.

These are **snapshot-derived preliminary values**, not final benchmark results. They must not be presented as the full workload's results because the screenshot is not a verified end-of-test report and the random test had not been shown to complete. They also do not establish an improvement over another controller.

| Claim | Evidence status |
|---|---|
| Directed readback data matches expected words | Partially supported by displayed PASS lines |
| Burst behavior | Some burst read/write scenarios are present; full edge-case coverage not yet established |
| Backpressure stall/resume | A directed stall/resume is visible; exhaustive no-loss/no-duplicate behavior is not established |
| Randomized stress completes | Not established by available log |
| Final performance summary | Not established; only an intermediate counter snapshot is available |
| Better than baseline | Not measured |
| Area, timing, power, FPGA resource usage | Not measured in the available evidence |

## 7. Novelty and Expected Value

### What is not claimed as novel

- Burst access by itself.
- Valid/ready handshaking by itself.
- A response FIFO by itself.
- Golden-memory self-checking verification by itself.
- Performance counters by themselves.

Each is a known technique or a standard engineering practice.

### Defensible contribution if completed

The strongest potential contribution is a reproducible, open evaluation of response conservation and throughput/stall trade-offs in a burst-capable controller under controlled backpressure, including corner cases where response consumption and arrival overlap. To make that contribution credible, the final work must provide the complete RTL revision, testbench, deterministic seeds, simulator version, full logs, metric definitions, baseline RTL, and raw results.

A performance improvement should be reported only if the same workload produces a measured difference. For a metric where higher is better, percentage improvement is `100 × (candidate − baseline) / baseline`. For a metric where lower is better, percentage reduction is `100 × (baseline − candidate) / baseline`. State the metric and baseline explicitly. Do not use “better” as a general claim if throughput improves while latency or buffering cost worsens.

## 8. Limitations

This is currently a preliminary RTL simulation study. No synthesis report, FPGA utilization, maximum clock frequency, physical power measurement, ASIC implementation, formal proof, or verified baseline comparison is available in the reviewed evidence. A behavioral SRAM model does not establish physical SRAM timing or silicon performance. Simulation correctness is bounded by the testbench coverage and simulator configuration.

The paper also requires a broader, documented literature search and verified bibliographic metadata before submission. Novelty cannot be guaranteed from a limited preliminary search.

## 9. Conclusion

A burst-capable SRAM controller with request/response flow control, response buffering, a golden-memory testbench, and basic performance instrumentation has been implemented. The available evidence demonstrates selected directed readbacks and a backpressure stall/resume event, but does not yet establish completion of randomized testing or a performance advantage. The next step is to close response-conservation corner cases, run the full regression, collect end-of-test metrics, and compare against a documented baseline. Only after those steps should the paper make quantitative claims about reliability or performance.

## Reproducibility checklist

- [ ] Full test reaches `ALL TESTS COMPLETE` and reports final PASS.
- [ ] No data mismatch, X-value, missing response, duplicate response, or ordering error.
- [ ] Concurrent response arrival/consumption and full-buffer cases pass.
- [ ] Seed and simulation duration are recorded.
- [ ] Counter semantics and measurement window are documented.
- [ ] Baseline uses the same workload and memory timing.
- [ ] Raw logs and results are committed to the repository.
- [ ] All references and publication metadata are verified.
