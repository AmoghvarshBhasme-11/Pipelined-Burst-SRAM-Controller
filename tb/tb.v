module tb_top;

reg clk;
reg rst;

// CPU side
reg valid;
reg we;
reg [9:0] addr;
reg [15:0] wdata;
reg [3:0] burst_len;

wire [15:0] rdata;
wire rvalid;
reg rready;
wire ready;

// SRAM side
wire sram_req;
wire sram_we;
wire [9:0] sram_addr;
wire [15:0] sram_wdata;
wire [15:0] sram_rdata;
wire sram_rvalid;

// Performance counter wires
wire [31:0] total_cycles;
wire [31:0] read_req_count;
wire [31:0] write_req_count;
wire [31:0] response_count;
wire [31:0] stall_cycles;
wire [31:0] sram_access_count;

// Golden memory
reg [15:0] golden_mem [0:1023];

// Expected read-address queue
reg [9:0] exp_addr_q [0:255];
integer exp_wr_ptr;
integer exp_rd_ptr;
integer exp_count;

// Error counter
integer error_count;

// Loop/random variables
integer i;
integer rand_addr;
integer rand_len;
integer rand_data;

//////////////////////////////
// CONTROLLER
//////////////////////////////
sram_controller dut (
    .clk(clk),
    .rst(rst),

    .valid(valid),
    .ready(ready),
    .we(we),
    .addr(addr),
    .wdata(wdata),
    .burst_len(burst_len),

    .rdata(rdata),
    .rvalid(rvalid),
    .rready(rready),

    .sram_req(sram_req),
    .sram_we(sram_we),
    .sram_addr(sram_addr),
    .sram_wdata(sram_wdata),
    .sram_rdata(sram_rdata),
    .sram_rvalid(sram_rvalid)
);

//////////////////////////////
// SRAM MODEL
//////////////////////////////
sram_model sram (
    .clk(clk),
    .rst(rst),
    .req(sram_req),
    .we(sram_we),
    .addr(sram_addr),
    .wdata(sram_wdata),
    .rdata(sram_rdata),
    .rvalid(sram_rvalid)
);

//////////////////////////////
// PERFORMANCE COUNTER
//////////////////////////////
perf_counter perf (
    .clk(clk),
    .rst(rst),

    .valid(valid),
    .ready(ready),
    .we(we),

    .rvalid(rvalid),
    .rready(rready),

    .sram_req(sram_req),
    .sram_we(sram_we),

    .total_cycles(total_cycles),
    .read_req_count(read_req_count),
    .write_req_count(write_req_count),
    .response_count(response_count),
    .stall_cycles(stall_cycles),
    .sram_access_count(sram_access_count)
);

//////////////////////////////
// CLOCK
//////////////////////////////
always #5 clk = ~clk;

//////////////////////////////
// SELF-CHECKERS
//////////////////////////////

// X-checker
always @(posedge clk) begin
    if (!rst) begin
        #1;
        if (rvalid && (^rdata === 1'bx)) begin
            $display("ERROR: rvalid high but rdata is XXXX at time %0t", $time);
            error_count = error_count + 1;
            $stop;
        end
    end
end

// Golden-memory checker
always @(posedge clk) begin
    if (!rst) begin
        #1;   // sample after DUT nonblocking assignments settle

        if (rvalid && rready) begin
            if (exp_count <= 0) begin
                $display("ERROR: Unexpected read response at time %0t | rdata=%h", $time, rdata);
                error_count = error_count + 1;
                $stop;
            end else begin
                if (rdata !== golden_mem[exp_addr_q[exp_rd_ptr]]) begin
                    $display("ERROR: DATA MISMATCH at time %0t", $time);
                    $display("       Address  = %0d", exp_addr_q[exp_rd_ptr]);
                    $display("       Expected = %h", golden_mem[exp_addr_q[exp_rd_ptr]]);
                    $display("       Got      = %h", rdata);
                    error_count = error_count + 1;
                    $stop;
                end else begin
                    $display("PASS READ: addr=%0d data=%h time=%0t",
                             exp_addr_q[exp_rd_ptr], rdata, $time);
                end

                exp_rd_ptr = exp_rd_ptr + 1;
                exp_count  = exp_count - 1;
            end
        end
    end
end

//////////////////////////////
// TASKS
//////////////////////////////

task write_burst(input [9:0] a, input [15:0] d, input [3:0] len);
integer j;
begin
    if (len == 0) begin
        $display("ERROR: burst_len cannot be 0 in write_burst");
        error_count = error_count + 1;
        $stop;
    end

    @(posedge clk);
    valid     <= 1;
    we        <= 1;
    addr      <= a;
    wdata     <= d;
    burst_len <= len;

    wait(ready);

    @(posedge clk);
    valid     <= 0;
    we        <= 0;
    addr      <= 0;
    wdata     <= 0;
    burst_len <= 0;

    // Update golden memory for same-data write burst
    for (j = 0; j < len; j = j + 1) begin
        golden_mem[a + j] = d;
    end
end
endtask

task read_burst(input [9:0] a, input [3:0] len);
integer j;
integer got;
begin
    if (len == 0) begin
        $display("ERROR: burst_len cannot be 0 in read_burst");
        error_count = error_count + 1;
        $stop;
    end

    // Push expected read addresses
    for (j = 0; j < len; j = j + 1) begin
        exp_addr_q[exp_wr_ptr] = a + j;
        exp_wr_ptr = exp_wr_ptr + 1;
        exp_count  = exp_count + 1;
    end

    @(posedge clk);
    valid     <= 1;
    we        <= 0;
    addr      <= a;
    wdata     <= 0;
    burst_len <= len;

    wait(ready);

    @(posedge clk);
    valid     <= 0;
    addr      <= 0;
    wdata     <= 0;
    burst_len <= 0;

    // Wait safely for accepted responses
    got = 0;
    while (got < len) begin
        @(posedge clk);
        #1;
        if (rvalid && rready)
            got = got + 1;
    end
end
endtask

//////////////////////////////
// TEST
//////////////////////////////

initial begin
    clk = 0;
    rst = 1;

    valid = 0;
    we = 0;
    addr = 0;
    wdata = 0;
    burst_len = 0;
    rready = 1;

    error_count = 0;
    exp_wr_ptr = 0;
    exp_rd_ptr = 0;
    exp_count  = 0;

    // Initialize golden memory
    for (i = 0; i < 1024; i = i + 1) begin
        golden_mem[i] = 16'h0000;
    end

    // Reset
    repeat(5) @(posedge clk);
    rst = 0;

    // ============================
    // TEST 1: NORMAL SINGLE WRITES + BURST READ
    // ============================
    $display("TEST 1 START");

    write_burst(5, 16'h1111, 1);
    write_burst(6, 16'h2222, 1);
    write_burst(7, 16'h3333, 1);

    read_burst(5, 3);

    $display("TEST 1 DONE");

    // ============================
    // TEST 2: TRUE WRITE BURST SAME DATA
    // ============================
    $display("TEST 2 START");

    write_burst(20, 16'h9999, 4);
    read_burst(20, 4);

    $display("TEST 2 DONE");

    // ============================
    // TEST 3: MIXED READ/WRITE
    // ============================
    $display("TEST 3 START");

    write_burst(30, 16'hAAAA, 1);
    write_burst(31, 16'hBBBB, 1);
    read_burst(30, 2);

    write_burst(40, 16'h1234, 1);
    read_burst(40, 1);

    write_burst(41, 16'h5678, 1);
    read_burst(41, 1);

    $display("TEST 3 DONE");

    // ============================
    // TEST 4: BACKPRESSURE TEST
    // ============================
    $display("TEST 4 START");

    fork
        begin
            read_burst(5, 3);
        end

        begin
            #20;
            rready = 0;
            $display("STALL: rready = 0 at time %0t", $time);

            #50;
            rready = 1;
            $display("RESUME: rready = 1 at time %0t", $time);
        end
    join

    $display("TEST 4 DONE");

    // ============================
    // TEST 5: RANDOM STRESS TEST
    // ============================
    $display("TEST 5 RANDOM STRESS START");

    for (i = 0; i < 20; i = i + 1) begin
        rand_addr = ($random & 32'h7fffffff) % 100;
        rand_len  = (($random & 32'h7fffffff) % 4) + 1;
        rand_data = $random;

        if (rand_addr + rand_len >= 1024)
            rand_addr = 0;

        write_burst(rand_addr[9:0], rand_data[15:0], rand_len[3:0]);
        read_burst(rand_addr[9:0], rand_len[3:0]);
    end

    $display("TEST 5 RANDOM STRESS DONE");

    // ============================
    // PERFORMANCE REPORT
    // ============================
    #50;

    $display("====================================");
    $display("PERFORMANCE REPORT");
    $display("Total cycles       = %0d", total_cycles);
    $display("Read requests      = %0d", read_req_count);
    $display("Write requests     = %0d", write_req_count);
    $display("Read responses     = %0d", response_count);
    $display("Stall cycles       = %0d", stall_cycles);
    $display("SRAM accesses      = %0d", sram_access_count);

    if (total_cycles != 0) begin
        $display("Throughput x100    = %0d", (response_count * 100) / total_cycles);
        $display("SRAM Util x100     = %0d", (sram_access_count * 100) / total_cycles);
        $display("Stall %% x100       = %0d", (stall_cycles * 100) / total_cycles);
    end

    $display("====================================");

    if (error_count == 0) begin
        $display("FINAL RESULT: PASS - All self-checking tests passed");
    end else begin
        $display("FINAL RESULT: FAIL - error_count = %0d", error_count);
    end

    $display("ALL TESTS COMPLETE");
    $stop;
end

endmodule