module mem_top;

    reg clk, we;
    reg [5:0] addr;
    reg [15:0] data;
    wire [15:0] data_out;


    memory my_mem (
        .clk(clk),
        .we(we),
        .addr(addr),
        .data(data),
        .out(data_out)
    );

    initial begin
        $readmemh("./mem_init.hex", my_mem.mem);        
        addr = 0;
        we = 0;
        data = 0;
        clk = 0;
        #5 addr = 3;
        #10;
        we = 1;
        addr = 3;
        data = 5;
        #10
        we = 0;
        addr = 3;
        #100;
        $finish; 
    end

    always
        #5 clk = ~clk;

    initial begin
        $monitor("Vreme = %d, we = %d, addr = %d, data = %d, out = %d", 
        $time, we, addr, data, data_out);
    end




endmodule