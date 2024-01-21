module synth_top; 

    reg dut_clk, dut_rst_n;
    reg [8:0] dut_sw;
    wire [15:0] dut_led;
    wire [27:0] dut_hex;

    top #(
        .DIVISOR(5)
    ) my_top (
        .clk(dut_clk),
        .rst_n(dut_rst_n),
        .sw(dut_sw),
        .led(dut_led),
        .hex(dut_hex)
    );

    initial begin
        dut_sw[3:0] = 8; 
        dut_rst_n = 1'b0;
        dut_clk = 1'b0;
        #2 dut_rst_n = 1'b1;
        #285 dut_sw[3:0] = 16'h0009;
        #100 dut_sw[3:0]= 16'h0003;
        #600000;
        $finish; 
    end

    always
        #5 dut_clk = ~dut_clk;

    initial begin
        $monitor("Time = %d, pc_ones = %x, pc_tens = %x, sp_ones = %x, sp_tens = %x, led = %x", 
        $time, dut_hex[20:14], dut_hex[27:21], dut_hex[6:0], dut_hex[13:7], dut_led);
    end

endmodule