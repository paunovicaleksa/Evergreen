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
    output [ADDR_WIDTH - 1 : 0] sp
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
    parameter INIT = 0, FETCH_0 = 1, FETCH_1 = 2, FETCH_2 = 3, FETCH_3 = 4;
    parameter ADDR_0 = 5, ADDR_1 = 6, ADDR_2 = 7, ADDR_3 = 8;
    parameter EXEC_0 = 9, EXEC_1 = 10, EXEC_2 = 11;
    parameter WB = 12;
    parameter STOP_STATE = 13, STOP_STATE_OUT1 = 14, STOP_STATE_OUT2 = 15;
    parameter START_PC = 8;
    integer state_next, state_reg;
    assign state = state_reg;

    // opcodes
    parameter MOV = 4'b0000, ADD = 4'b0001, SUB = 4'b0010, MUL = 4'b0011, DIV = 4'b0100, IN = 4'b0111, OUT = 4'b1000, STOP_INST = 4'b1111;
    // output
    reg [DATA_WIDTH - 1:0] out_next, out_reg;
    assign out = out_reg;

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
        .b(mem_in),
        .f(alu_out)
    );

    wire MOV32;
    assign MOV32 = (ir_high_out[15:12] == MOV && ir_high_out[3:0] == 4'b1000)? 1 : 0;
    wire [DATA_WIDTH -1:0] a_in;
    assign a_in = (state_reg == EXEC_1)? alu_out : mem_in;

    register #(
       .DATA_WIDTH(DATA_WIDTH) 
    ) a_reg (
        .clk(clk),
        .rst_n(rst_n),
        .cl(cl_reg[ACC]),
        .ld(ld_reg[ACC]),
        .in(a_in),
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
            pc_in_reg <= START_PC;
            sp_in_reg <= (2 ** ADDR_WIDTH) - 1;
            alu_oc_reg <= 3'b000;
            // memory signals
            mem_we_reg <= 1'b0;
            mem_addr_reg <= {ADDR_WIDTH{1'b0}};
            mem_data_reg <= {DATA_WIDTH{1'b0}};
            // output
            out_reg <= {DATA_WIDTH{1'b0}};
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
            // output
            out_reg <= out_next;
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
        // output
        out_next = out_reg;

        case (state_reg)
            INIT: begin
                // init pc and sp

                state_next = FETCH_0;
            end FETCH_0: begin
                // pc points to the next instruction, load it!
                ld_next[PC] = 1'b1;
                pc_in_next = pc + 1;
                mem_addr_next = pc;

                state_next = FETCH_1;
            end FETCH_1: begin
                // mem data ready next clock cycle, load
                ld_next[IR_HIGH] = 1'b1;
                mem_addr_next = pc + 1;

                state_next = FETCH_2;
            end FETCH_2: begin
                // ir_out ready next clock cycle, check mem_in instead
                if(mem_in[15:12] == STOP_INST) begin
                    state_next = STOP_STATE;
                end else if(mem_in[15:12] == MOV && mem_in[3:0] == 4'b1000) begin
                    // load next
                    ld_next[IR_LOW] = 1'b1;
                    // inc pc
                    ld_next[PC] = 1'b1;
                    pc_in_next = pc + 1;
                    ld_next[ACC] = 1'b1;

                    state_next = FETCH_3;
                end else begin
                    // load second operand into the acc
                    if(mem_in[15:12] != IN && mem_in[15:12] != OUT) begin
                        mem_addr_next = {3'b000, mem_in[6:4]};
                    end else if(mem_in[15:12] == OUT) begin
                        mem_addr_next = {3'b000, mem_in[10:8]};
                    end
                    state_next = FETCH_3;
                end
            end FETCH_3: begin
                if(!MOV32 && ir_high_out[15:12] != IN && ir_high_out[15:12] != OUT) begin
                    ld_next[ACC] = 1'b1;
                    if(ir_high_out[7] == 1'b1) begin
                        state_next = ADDR_0;
                    end else begin
                    // get second operand, maybe.
                        if(ir_high_out[15:12] == MOV) begin
                            state_next = EXEC_0;
                        end else begin
                            mem_addr_next = {3'b000, ir_high_out[2:0]};
                            if(ir_high_out[3] == 1'b1) begin
                                state_next = ADDR_2;
                            end else begin
                                state_next = EXEC_0;
                            end
                        end
                    end
                end else if(ir_high_out[15:12] == OUT) begin
                    ld_next[ACC] = 1'b1;
                    if(ir_high_out[11] == 1'b1) begin
                        state_next = ADDR_0;
                    end else begin
                        state_next = EXEC_0;
                    end
                end else if(ir_high_out[15:12] == IN) begin
                    state_next = EXEC_1;
                end else begin
                    state_next = EXEC_1;
                end
            // states for indirect addressing and other stuff i dont know.
            end ADDR_0: begin
                mem_addr_next = mem_in;

                state_next = ADDR_1;
            end ADDR_1: begin
                mem_addr_next = {3'b000, ir_high_out[2:0]};
                ld_next[ACC] = 1'b1;

                if(ir_high_out[3] == 1'b1 && ir_high_out[15:12] != MOV) begin
                    state_next = ADDR_2;
                end else begin
                    state_next = EXEC_0;
                end
            // third operand, indirect
            end ADDR_2: begin
                state_next = ADDR_3;
            end ADDR_3: begin
                mem_addr_next = mem_in;   
                state_next = EXEC_0;
            end EXEC_0: begin
                if(ir_high_out[15:12] != MOV && ir_high_out[15:12] != OUT) begin
                    alu_oc_next = ir_high_out[15:12] - 1;
                    ld_next[ACC] = 1'b1;
                end                 
                state_next = EXEC_1;
            end EXEC_1: begin
                // data in acc for out 
                if(ir_high_out[15:12] == OUT) begin
                    out_next = a_out;
                    state_next = FETCH_0;
                end else if(ir_high_out[15:12] == IN) begin
                    if(ir_high_out[11] == 1'b1) begin
                        // indirect
                        mem_addr_next = {3'b000, ir_high_out[10:8]};
                        state_next = EXEC_2;
                    end else begin
                        mem_addr_next = {3'b000, ir_high_out[10:8]};
                        mem_data_next = in;
                        mem_we_next = 1'b1;
                        state_next = FETCH_0;
                    end
                end else begin
                    mem_addr_next = {3'b000, ir_high_out[10:8]};
                    if(ir_high_out[11] == 1'b1) begin
                        state_next = EXEC_2;
                    end else begin
                        if(ir_high_out[15:12] != MOV) begin
                            mem_data_next = alu_out;
                            mem_we_next = 1'b1;
                            state_next = FETCH_0;
                        end else begin
                            mem_data_next = a_out;
                            mem_we_next = 1'b1;
                            state_next = FETCH_0;
                        end
                    end
                end
            end EXEC_2: begin
                state_next = WB;
            end WB: begin
                mem_addr_next = mem_in;
                mem_data_next = ir_high_out[15:12] == IN? in : a_out;
                mem_we_next = 1'b1;

                state_next = FETCH_0;
            // handle separately, idc.
            end STOP_STATE: begin
            end STOP_STATE_OUT1: begin
            end default: begin
            end
        endcase
    end

endmodule