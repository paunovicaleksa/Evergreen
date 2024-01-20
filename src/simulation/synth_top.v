module synth_top; 

    reg dut_clk, dut_rst_n;
    reg [15:0] dut_mem_in, dut_in;
    wire [5:0] dut_pc, dut_sp, dut_mem_addr;
    wire [15:0] dut_mem_data, dut_mem_out;
    wire dut_mem_we;
    wire [31:0] dut_state;

    cpu my_cpu(
        .clk(dut_clk),
        .rst_n(dut_rst_n),
        .mem_in(),
        .in(dut_in),
        .mem_we(dut_mem_we),
        .mem_addr(dut_mem_addr),
        .mem_data(dut_mem_data),
        .out(),
        .pc(dut_pc),
        .sp(dut_sp),
        .state(dut_state)
    );

    memory my_mem (
        .clk(dut_clk),
        .we(dut_mem_we),
        .addr(dut_mem_addr),
        .data(dut_mem_data),
        .out(dut_mem_out)
    );

    initial begin
        $readmemh("./mem_init.hex", my_mem.mem);        
        dut_rst_n = 1'b0;
        dut_clk = 1'b0;
        #2 dut_rst_n = 1'b1;
        repeat(100) begin
            #10;
        end
        $finish; 
    end

    always
        #5 dut_clk = ~dut_clk;

    initial begin
        $monitor("Vreme = %d, sp = %d, pc = %d, mem_we = %b, mem_addr = %d, mem_data = %d, state = %d, mem_out = %x",
        $time, dut_sp, dut_pc, dut_mem_we, dut_mem_addr, dut_mem_data, dut_state, dut_mem_out);
    end

endmodule