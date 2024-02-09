module top #(
    parameter DIVISOR = 50_000_000,
    parameter FILE_NAME = "mem_init.mif",
    parameter ADDR_WIDTH = 6,
    parameter DATA_WIDTH = 16
) (
    input clk,
    input rst_n,
    input [2:0] btn,
    input [8:0] sw,
    output [9:0] led,
    output [27:0] hex
);
    wire clk_out;
    clk_div #(
        .DIVISOR(DIVISOR)
    ) my_clk_div (
        .rst_n(rst_n),
        .clk(clk),
        .out(clk_out)
    );

    wire we;
    wire [ADDR_WIDTH - 1:0] addr;
    wire [DATA_WIDTH - 1:0] mem_data, mem_in;
    wire [ADDR_WIDTH - 1:0] pc, sp;
    wire [DATA_WIDTH - 1:0] cpu_in;
    wire [DATA_WIDTH - 1:0] cpu_out;
    assign cpu_in = {{(DATA_WIDTH - 4){1'b0}}, sw[3:0]};
    // assign cpu_in = {sw[3:0], {(DATA_WIDTH - 4){1'b0}}};
    assign led = {5'h0, cpu_out[4:0]};

    cpu #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) my_cpu (
        .rst_n(rst_n),
        .clk(clk_out),
        .out(cpu_out),
        .in(cpu_in),
        .mem_we(we),
        .mem_addr(addr),
        .mem_data(mem_data),
        .mem_in(mem_in),
        .pc(pc),
        .sp(sp)
    );

    memory #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) my_memory (
        .clk(clk_out),
        .we(we),
        .addr(addr),
        .data(mem_data),
        .out(mem_in)
    );

    wire [3:0] pc_ones, pc_tens;
    bcd bcd_pc (
        .in(pc),
        .ones(pc_ones),
        .tens(pc_tens)
    );

    ssd ssd_pc_tens (
        .in(pc_tens),
        .out(hex[27:21])
    );

    ssd ssd_pc_ones (
        .in(pc_ones),
        .out(hex[20:14])
    );

    wire [3:0] sp_ones, sp_tens;
    bcd bcd_sp (
        .in(sp),
        .ones(sp_ones),
        .tens(sp_tens)
    );

    ssd ssd_sp_tens (
        .in(sp_tens),
        .out(hex[13:7])
    );

    ssd ssd_sp_ones (
        .in(sp_ones),
        .out(hex[6:0])
    );

endmodule