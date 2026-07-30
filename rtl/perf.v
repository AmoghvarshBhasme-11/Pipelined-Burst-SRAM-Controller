module perf_counter (
    input  wire clk,
    input  wire rst,

    // CPU request side
    input  wire valid,
    input  wire ready,
    input  wire we,

    // CPU response side
    input  wire rvalid,
    input  wire rready,

    // SRAM side
    input  wire sram_req,
    input  wire sram_we,

    // Performance outputs
    output reg [31:0] total_cycles,
    output reg [31:0] read_req_count,
    output reg [31:0] write_req_count,
    output reg [31:0] response_count,
    output reg [31:0] stall_cycles,
    output reg [31:0] sram_access_count
);

always @(posedge clk) begin
    if (rst) begin
        total_cycles      <= 0;
        read_req_count    <= 0;
        write_req_count   <= 0;
        response_count    <= 0;
        stall_cycles      <= 0;
        sram_access_count <= 0;
    end else begin
        // Counts every active simulation clock cycle after reset
        total_cycles <= total_cycles + 1;

        // CPU request accepted only when valid && ready
        if (valid && ready) begin
            if (we)
                write_req_count <= write_req_count + 1;
            else
                read_req_count <= read_req_count + 1;
        end

        // CPU response accepted only when rvalid && rready
        if (rvalid && rready) begin
            response_count <= response_count + 1;
        end

        // CPU is trying to send request but controller is not ready
        if (valid && !ready) begin
            stall_cycles <= stall_cycles + 1;
        end

        // SRAM transaction issued
        if (sram_req) begin
            sram_access_count <= sram_access_count + 1;
        end
    end
end

endmodule