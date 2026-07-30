# GitHub Upload Checklist

## Upload these

- Your real Verilog design files from the Vivado **Design Sources** folder
- Your real self-checking Verilog testbench from **Simulation Sources**
- Waveform screenshots that prove burst reads and backpressure handling
- TCL/XSim console screenshot that shows a clean pass
- This `README.md`, `docs/RESULTS.md`, and `.gitignore`

## Do not upload these

- Entire `.Xil`, `.runs`, `.cache`, `.sim`, or `xsim.dir` folders
- Large `.wdb` databases, generated bitstreams, reports, and logs
- A `.zip` file containing the project instead of the actual source files
- Copied code that you cannot explain line-by-line in an interview

## Recommended commit sequence

1. `Initial RTL: controller, SRAM model, FIFO, and counters`
2. `Add self-checking testbench and golden memory model`
3. `Fix response alignment and burst termination`
4. `Add randomized stress testing and backpressure coverage`
5. `Document waveforms and verification results`
