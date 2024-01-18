module top;
    
    reg [2:0] alu_dut_oc;
    reg [3:0] alu_dut_a, alu_dut_b;
    wire [3:0] alu_dut_f;

    alu alu_dut(.oc(alu_dut_oc), .a(alu_dut_a), .b(alu_dut_b), .f(alu_dut_f));

    reg reg_dut_clk, reg_dut_rst_n, reg_dut_cl, reg_dut_ld, reg_dut_inc, reg_dut_dec, reg_dut_sr, reg_dut_ir, reg_dut_sl, reg_dut_il;
    reg [3:0] reg_dut_in;
    wire [3:0] reg_dut_out;

    register reg_dut(.clk(reg_dut_clk), 
            .rst_n(reg_dut_rst_n), 
            .cl(reg_dut_cl), 
            .ld(reg_dut_ld),
            .inc(reg_dut_inc),
            .dec(reg_dut_dec),
            .sr(reg_dut_sr),
            .ir(reg_dut_ir),
            .sl(reg_dut_sl),
            .il(reg_dut_il),
            .in(reg_dut_in),
            .out(reg_dut_out)
    );

    integer i;

    initial begin
        for(i = 0; i < 2 ** 11; i = i + 1) begin
            {alu_dut_oc, alu_dut_a, alu_dut_b} = i;
            #5;
        end

        $stop;

        reg_dut_rst_n = 1'b0;
        reg_dut_clk = 1'b0;
        #2 reg_dut_rst_n = 1'b1;

        repeat(1000) begin
            reg_dut_cl = $urandom_range(1);
            reg_dut_ld = $urandom_range(1);
            reg_dut_inc = $urandom_range(1);
            reg_dut_dec = $urandom_range(1);
            reg_dut_sr = $urandom_range(1);
            reg_dut_ir = $urandom_range(1);
            reg_dut_sl = $urandom_range(1);
            reg_dut_il = $urandom_range(1);

            reg_dut_in = $urandom % (2 ** 4);
            #10;
        end
        $finish;
    end

    always
        #5 reg_dut_clk = ~reg_dut_clk;

    initial begin
        $monitor("Vreme = %d, oc = %b, a = %b, b = %b, f = %b", $time, alu_dut_oc, alu_dut_a, alu_dut_b, alu_dut_f);
    end

    always @(reg_dut_out) begin
        $strobe("Vreme = %d, cl = %b, ld = %b, inc = %b, dec = %b, sr = %b, ir = %b, sl = %b, il = %b, in = %b, out = %b", 
        $time, reg_dut_cl, reg_dut_ld, reg_dut_inc, reg_dut_dec, reg_dut_sr, reg_dut_ir, reg_dut_sl, reg_dut_il, reg_dut_in, reg_dut_out);
    end

endmodule