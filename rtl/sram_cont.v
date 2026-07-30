`timescale 1ns / 1ps

module sram_controller #(
    parameter ADDR_WIDTH = 10,
    parameter DATA_WIDTH = 16
)(
    input  wire clk,
    input  wire rst,

    // CPU side
    input  wire valid,
    output reg  ready,
    input  wire we,
    input  wire [ADDR_WIDTH-1:0] addr,
    input  wire [DATA_WIDTH-1:0] wdata,
    input  wire [3:0] burst_len,

    output reg  [DATA_WIDTH-1:0] rdata,
    output reg  rvalid,
    input  wire rready,

    // SRAM side
    output reg sram_req,
    output reg sram_we,
    output reg [ADDR_WIDTH-1:0] sram_addr,
    output reg [DATA_WIDTH-1:0] sram_wdata,
    input  wire [DATA_WIDTH-1:0] sram_rdata,
    input  wire sram_rvalid
);

localparam IDLE = 1'b0,
           WAIT = 1'b1;

reg state;

// transaction registers
reg [ADDR_WIDTH-1:0] addr_reg;
reg [DATA_WIDTH-1:0] wdata_reg;
reg we_reg;

// burst control
reg [3:0] burst_cnt;

// read request tracking
reg read_pending;

// response FIFO
reg [DATA_WIDTH-1:0] resp_data [1:0];
reg resp_wr_ptr;
reg resp_rd_ptr;
reg [1:0] resp_count;

wire resp_fifo_full;
assign resp_fifo_full = (resp_count == 2);

always @(posedge clk) begin
    if (rst) begin
        state <= IDLE;
        ready <= 1;

        rdata  <= 0;
        rvalid <= 0;

        sram_req   <= 0;
        sram_we    <= 0;
        sram_addr  <= 0;
        sram_wdata <= 0;

        addr_reg  <= 0;
        wdata_reg <= 0;
        we_reg    <= 0;

        burst_cnt    <= 0;
        read_pending <= 0;

        resp_wr_ptr <= 0;
        resp_rd_ptr <= 0;
        resp_count  <= 0;

        resp_data[0] <= 0;
        resp_data[1] <= 0;

    end else begin

        // default
        sram_req <= 0;
        ready    <= (state == IDLE);

        // ==========================================================
        // RESPONSE OUTPUT LOGIC
        // This fixes duplicate data issue.
        // If CPU accepts current data, immediately move to next FIFO data.
        // ==========================================================
        if (rvalid && rready) begin
            if (resp_count > 0) begin
                rdata <= resp_data[resp_rd_ptr];
                rvalid <= 1;

                resp_rd_ptr <= resp_rd_ptr + 1;
                resp_count  <= resp_count - 1;
            end else begin
                rvalid <= 0;
            end
        end

        // ==========================================================
        // SRAM RESPONSE CAPTURE
        // If CPU output is free, send directly to rdata.
        // If output is busy, store in response FIFO.
        // ==========================================================
        if (sram_rvalid) begin
            if (!rvalid) begin
                rdata  <= sram_rdata;
                rvalid <= 1;
            end else if (!resp_fifo_full) begin
                resp_data[resp_wr_ptr] <= sram_rdata;
                resp_wr_ptr <= resp_wr_ptr + 1;
                resp_count  <= resp_count + 1;
            end
        end

        case (state)

        // ==========================================================
        // IDLE: accept CPU request
        // ==========================================================
        IDLE: begin
            ready <= 1;

            if (valid && ready) begin
                addr_reg  <= addr;
                wdata_reg <= wdata;
                we_reg    <= we;

                burst_cnt <= (burst_len == 0) ? 4'd1 : burst_len;

                read_pending <= 0;

                ready <= 0;
                state <= WAIT;
            end
        end

        // ==========================================================
        // WAIT: execute transaction
        // ==========================================================
        WAIT: begin
            ready <= 0;

            sram_we    <= we_reg;
            sram_addr  <= addr_reg;
            sram_wdata <= wdata_reg;

            // ---------------------------
            // WRITE BURST
            // ---------------------------
            if (we_reg) begin
                sram_req <= 1;

                addr_reg  <= addr_reg + 1;
                burst_cnt <= burst_cnt - 1;

                if (burst_cnt == 1) begin
                    state <= IDLE;
                end
            end

            // ---------------------------
            // READ BURST
            // ---------------------------
            else begin
                // Issue read request only if:
                // 1. no read is pending
                // 2. response FIFO has space
                if (!read_pending && !resp_fifo_full) begin
                    sram_req     <= 1;
                    read_pending <= 1;
                end

                // When SRAM returns data, advance address and burst counter
                if (sram_rvalid) begin
                    read_pending <= 0;

                    addr_reg  <= addr_reg + 1;
                    burst_cnt <= burst_cnt - 1;

                    if (burst_cnt == 1) begin
                        state <= IDLE;
                    end
                end
            end
        end

        endcase
    end
end

endmodule