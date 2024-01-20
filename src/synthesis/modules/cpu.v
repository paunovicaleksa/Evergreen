module cpu #(
    parameter ADDR_WIDTH = 6,
    parameter DATA_WIDTH = 16
) (
    input clk,
    input rst_n,
    input [DATA_WIDTH - 1 : 0] mem_in,
    input [DATA_WIDTH - 1 : 0] in,
    output mem_we,
    output [ADDR_WIDTH - 1 : 0] mem_addr,
    output [DATA_WIDTH - 1 : 0] mem_data,
    output [DATA_WIDTH - 1 : 0] out,
    output [ADDR_WIDTH - 1 : 0] pc,
    output [ADDR_WIDTH - 1 : 0] sp,
    output [31:0] state
);
    // constants
    parameter PC_WIDTH = ADDR_WIDTH;
    parameter SP_WIDTH = ADDR_WIDTH;
    parameter IR_WIDTH = DATA_WIDTH;
    parameter REG_NUM = 5;
    parameter PC = 0;
    parameter SP = 1;
    parameter IR_HIGH = 2;
    parameter IR_LOW = 3;
    parameter ACC = 4;

    // states
    parameter INIT = 0, STOP = 1, FETCH_0 = 2, FETCH_1 = 3;
    integer state_next, state_reg;
    assign state = state_reg;

    // memory control signals
    reg mem_we_reg, mem_we_next;
    assign mem_we = mem_we_reg;

    reg [ADDR_WIDTH - 1:0] mem_addr_reg, mem_addr_next;
    reg [DATA_WIDTH - 1:0] mem_data_reg, mem_data_next;
    assign mem_addr = mem_addr_reg;
    assign mem_data = mem_data_reg;

    // register control signals
    reg [REG_NUM - 1:0] cl_reg, ld_reg, inc_reg, dec_reg, sr_reg, ir_reg, sl_reg, il_reg;
    reg [REG_NUM - 1:0] cl_next, ld_next, inc_next, dec_next, sr_next, ir_next, sl_next, il_next;

    reg [PC_WIDTH - 1:0] pc_in_reg, pc_in_next;
    register #(
       .DATA_WIDTH(PC_WIDTH) 
    ) pc_reg (
        .clk(clk),
        .rst_n(rst_n),
        .cl(cl_reg[PC]),
        .ld(ld_reg[PC]),
        .in(pc_in_reg),
        .inc(inc_reg[PC]),
        .dec(dec_reg[PC]),
        .sr(sr_reg[PC]),
        .ir(ir_reg[PC]),
        .sl(sl_reg[PC]),
        .il(il_reg[PC]),
        .out(pc)
    );

    reg[SP_WIDTH - 1:0] sp_in_reg, sp_in_next;
    register #(
       .DATA_WIDTH(SP_WIDTH) 
    ) sp_reg (
        .clk(clk),
        .rst_n(rst_n),
        .cl(cl_reg[SP]),
        .ld(ld_reg[SP]),
        .in(sp_in_reg),
        .inc(inc_reg[SP]),
        .dec(dec_reg[SP]),
        .sr(sr_reg[SP]),
        .ir(ir_reg[SP]),
        .sl(sl_reg[SP]),
        .il(il_reg[SP]),
        .out(sp)
    );

    wire [IR_WIDTH -1:0] ir_high_out;
    register #(
       .DATA_WIDTH(IR_WIDTH) 
    ) ir_high (
        .clk(clk),
        .rst_n(rst_n),
        .cl(cl_reg[IR_HIGH]),
        .ld(ld_reg[IR_HIGH]),
        .in(mem_in),
        .inc(inc_reg[IR_HIGH]),
        .dec(dec_reg[IR_HIGH]),
        .sr(sr_reg[IR_HIGH]),
        .ir(ir_reg[IR_HIGH]),
        .sl(sl_reg[IR_HIGH]),
        .il(il_reg[IR_HIGH]),
        .out(ir_high_out)
    );

    wire [IR_WIDTH -1:0] ir_low_out;
    register #(
       .DATA_WIDTH(IR_WIDTH) 
    ) ir_low (
        .clk(clk),
        .rst_n(rst_n),
        .cl(cl_reg[IR_LOW]),
        .ld(ld_reg[IR_LOW]),
        .in(mem_in),
        .inc(inc_reg[IR_LOW]),
        .dec(dec_reg[IR_LOW]),
        .sr(sr_reg[IR_LOW]),
        .ir(ir_reg[IR_LOW]),
        .sl(sl_reg[IR_LOW]),
        .il(il_reg[IR_LOW]),
        .out(ir_low_out)
    );

    // reg, next needed?
    wire [DATA_WIDTH - 1:0] a_out;
    reg [2:0] alu_oc_reg, alu_oc_next;
    wire [DATA_WIDTH - 1:0] alu_out;
    alu #(
        .DATA_WIDTH(DATA_WIDTH)
    )cpu_alu (
        .oc(alu_oc_reg),
        .a(a_out),
        .b(ir_low_out),
        .f(alu_out)
    );


    register #(
       .DATA_WIDTH(DATA_WIDTH) 
    ) a_reg (
        .clk(clk),
        .rst_n(rst_n),
        .cl(cl_reg[ACC]),
        .ld(ld_reg[ACC]),
        .in(alu_out),
        .inc(inc_reg[ACC]),
        .dec(dec_reg[ACC]),
        .sr(sr_reg[ACC]),
        .ir(ir_reg[ACC]),
        .sl(sl_reg[ACC]),
        .il(il_reg[ACC]),
        .out(a_out)
    );

    // maybe only for state stuff, other things i can handle inside of the states
    always @(posedge clk, negedge rst_n) begin
        if(!rst_n) begin
            // init all to zeroes, INIT will init pc, sp etc.?
            cl_reg <= {REG_NUM{1'b0}};
            // load only into SP and PC
            ld_reg[ACC:IR_HIGH] <= {(REG_NUM - SP){1'b0}};
            ld_reg[SP:PC] <= 2'b11;
            inc_reg <= {REG_NUM{1'b0}};
            dec_reg <= {REG_NUM{1'b0}};
            sr_reg <= {REG_NUM{1'b0}};
            ir_reg <= {REG_NUM{1'b0}};
            sl_reg <= {REG_NUM{1'b0}};
            il_reg <= {REG_NUM{1'b0}};
            // values to load 
            pc_in_reg <= 8;
            sp_in_reg <= (2 ** ADDR_WIDTH) - 1;
            alu_oc_reg <= 3'b000;
            // memory signals
            mem_we_reg <= 1'b0;
            mem_addr_reg <= {ADDR_WIDTH{1'b0}};
            mem_data_reg <= {DATA_WIDTH{1'b0}};
            // init state
            state_reg <= INIT;
        end else begin
            cl_reg <= cl_next;
            ld_reg <= ld_next;
            inc_reg <= inc_next;
            dec_reg <= dec_next;
            sr_reg <= sr_next;
            ir_reg <= ir_next;
            sl_reg <= sl_next;
            il_reg <= il_next;
            pc_in_reg <= pc_in_next;
            sp_in_reg <= sp_in_next;
            alu_oc_reg <= alu_oc_next;
            // memory signals
            mem_we_reg <= mem_we_next;
            mem_addr_reg <= mem_addr_next;
            mem_data_reg <= mem_data_next;
            // state
            state_reg <= state_next;
        end
    end

    always @(*) begin
        cl_next = {REG_NUM{1'b0}};
        ld_next = {REG_NUM{1'b0}};
        inc_next = {REG_NUM{1'b0}};
        dec_next = {REG_NUM{1'b0}};
        sr_next = {REG_NUM{1'b0}};
        ir_next = {REG_NUM{1'b0}};
        sl_next = {REG_NUM{1'b0}};
        il_next = {REG_NUM{1'b0}};
        pc_in_next = {ADDR_WIDTH{1'b0}};
        sp_in_next = {ADDR_WIDTH{1'b0}};
        alu_oc_next = alu_oc_reg;
        state_next = state_reg;
        // also memory stuff
        mem_we_next = 1'b0;
        mem_addr_next = {ADDR_WIDTH{1'b0}};
        mem_data_next = {DATA_WIDTH{1'b0}};

        case (state_reg)
            INIT: begin
                // init pc
                state_next = FETCH_0;
            end 
            FETCH_0: begin
                mem_addr_next = pc;
                pc_in_next = pc + 1;
                state_next = STOP;
                
            end
            STOP: begin
            end
            default: begin
                state_next = STOP;
            end
        endcase
    end

endmodule