module synth_top; 

    reg dut_clk, dut_rst_n;
    reg [8:0] dut_in;
    wire [5:0] dut_pc, dut_sp, dut_mem_addr;
    wire [15:0] dut_mem_data, dut_mem_out;
    wire [9:0] dut_out;
    wire dut_mem_we, dut_clk_out;
    wire [27:0] dut_hex;
    wire [31:0] state;

    top #(
        .DIVISOR(5)
    ) my_top (
        .clk(dut_clk),
        .rst_n(dut_rst_n),
        .sw(dut_in),
        .led(dut_out),
        .hex(dut_hex)
    );

    // clk_div #(
    //     .DIVISOR(5)
    // ) my_div (
    //     .rst_n(dut_rst_n),
    //     .clk(dut_clk),
    //     .out(dut_clk_out)
    // );

    // cpu my_cpu(
    //     .clk(dut_clk_out),
    //     .rst_n(dut_rst_n),
    //     .mem_in(dut_mem_out),
    //     .in(dut_in),
    //     .mem_we(dut_mem_we),
    //     .mem_addr(dut_mem_addr),
    //     .mem_data(dut_mem_data),
    //     .out(dut_out),
    //     .pc(dut_pc),
    //     .sp(dut_sp),
    //     .state(state)
    // );

    // memory my_mem (
    //     .clk(dut_clk_out),
    //     .we(dut_mem_we),
    //     .addr(dut_mem_addr),
    //     .data(dut_mem_data),
    //     .out(dut_mem_out)
    // );

    initial begin
        $readmemh("./mem_init.hex", my_top.my_memory.mem);        
        dut_rst_n = 1'b0;
        dut_clk = 1'b0;
        dut_in = 9'h008;
        #2 dut_rst_n = 1'b1;
        #700;
        dut_in = 9'h009;
        #400;
        dut_in = 9'h003;
        #5000;
        $finish; 
    end

    always
        #5 dut_clk = ~dut_clk;

    // initial begin
    //     $monitor("Vreme = %d, sp = %d, pc = %d, state = %d, mem_we = %b,  mem_addr = %d, mem_data = %d, mem_out = %x, out = %x",
    //     $time, dut_sp, dut_pc, state, dut_mem_we,   dut_mem_addr, dut_mem_data, dut_mem_out, dut_out);
    // end
    initial begin
        $monitor("Vreme = %d led = %x",
        $time, dut_out); 
    end


endmodule