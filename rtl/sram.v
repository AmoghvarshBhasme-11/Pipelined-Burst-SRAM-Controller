module sram_model #(
    parameter DATA_WIDTH = 16,
    parameter ADDR_WIDTH = 10
)(
    input clk,
    input rst,
    input req,
    input we,
    input [ADDR_WIDTH-1:0] addr,
    input [DATA_WIDTH-1:0] wdata,
    output reg [DATA_WIDTH-1:0] rdata,
    output reg rvalid
);

reg [DATA_WIDTH-1:0] mem [0:(1<<ADDR_WIDTH)-1];

integer i;
initial begin
    for (i = 0; i < (1<<ADDR_WIDTH); i = i + 1)
        mem[i] = 0;
end

reg [ADDR_WIDTH-1:0] addr_reg;
reg read_pending;

always @(posedge clk) begin
    if (rst) begin
        rvalid <= 0;
        read_pending <= 0;
    end else begin
        rvalid <= 0;

        if (req && we) begin
            mem[addr] <= wdata;
        end

        if (req && !we) begin
            addr_reg <= addr;
            read_pending <= 1;
        end

        if (read_pending) begin
            rdata <= mem[addr_reg];
            rvalid <= 1;
            read_pending <= 0;
        end
    end
end

endmodule