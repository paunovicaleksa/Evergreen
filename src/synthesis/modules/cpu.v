module cpu #(
    parameter ADDR_WIDTH = 6,
    parameter DATA_WIDTH = 16
) (
    input clk,
    input rst_n,
    input [DATA_WIDTH - 1 : 0] mem_in,
    input [DATA_WIDTH - 1 : 0] in,
    output reg mem_we,
    output reg [ADDR_WIDTH - 1 : 0] mem_addr,
    output reg [DATA_WIDTH - 1 : 0] mem_data,
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
    parameter INIT = 0, FETCH_0 = 1, FETCH_1 = 2, FETCH_2 = 3, FETCH_3 = 4;
    parameter ADDR_0 = 5, ADDR_1 = 6, ADDR_2 = 7, ADDR_3 = 8;
    parameter EXEC_0 = 9, EXEC_1 = 10, EXEC_2 = 11;
    parameter WB = 12;
    parameter STOP_STATE = 13, STOP_STATE_OUT1 = 14, STOP_STATE_OUT2 = 15, STOP_STATE_OUT1_IND = 16, STOP_STATE_OUT2_IND = 17;
    parameter STOP_STATE_OUT3 = 18, STOP_STATE_OUT3_IND = 19, IDLE_STATE = 20;
    parameter START_PC = 8;
    integer state_next, state_reg;
    assign state = state_reg;

    // opcodes
    parameter MOV = 4'b0000, ADD = 4'b0001, SUB = 4'b0010, MUL = 4'b0011, DIV = 4'b0100, IN = 4'b0111, OUT = 4'b1000, STOP_INST = 4'b1111;
    // output
    reg [DATA_WIDTH - 1:0] out_next, out_reg;
    assign out = out_reg;

    // register control signals
    reg [REG_NUM - 1:0] cl_reg, ld_reg, inc_reg, dec_reg, sr_reg, ir_reg, sl_reg, il_reg;

    reg [PC_WIDTH - 1:0] pc_in;
    register #(
       .DATA_WIDTH(PC_WIDTH) 
    ) pc_reg (
        .clk(clk),
        .rst_n(rst_n),
        .cl(cl_reg[PC]),
        .ld(ld_reg[PC]),
        .in(pc_in),
        .inc(inc_reg[PC]),
        .dec(dec_reg[PC]),
        .sr(sr_reg[PC]),
        .ir(ir_reg[PC]),
        .sl(sl_reg[PC]),
        .il(il_reg[PC]),
        .out(pc)
    );

    reg[SP_WIDTH - 1:0] sp_in;
    register #(
       .DATA_WIDTH(SP_WIDTH) 
    ) sp_reg (
        .clk(clk),
        .rst_n(rst_n),
        .cl(cl_reg[SP]),
        .ld(ld_reg[SP]),
        .in(sp_in),
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
    reg [2:0] alu_oc_reg;
    wire [DATA_WIDTH - 1:0] alu_out;
    alu #(
        .DATA_WIDTH(DATA_WIDTH)
    )cpu_alu (
        .oc(alu_oc_reg),
        .a(a_out),
        .b(mem_in),
        .f(alu_out)
    );

    wire [DATA_WIDTH -1:0] a_in;
    wire ARITHMETIC;
    assign a_in = (state_reg == EXEC_0 && ARITHMETIC == 1'b1)? alu_out : mem_in;
    assign ARITHMETIC = ((ir_high_out[15:12] == ADD) || (ir_high_out[15:12] == SUB) ||
    (ir_high_out[15:12] == MUL) || (ir_high_out[15:12] == DIV))? 1 : 0;

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
            out_reg <= {DATA_WIDTH{1'b0}};
            state_reg <= INIT;
        end else begin
            // output
            out_reg <= out_next;
            // state
            state_reg <= state_next;
        end
    end

    // TODO: vezati na ALU direktno ir_high - 1
    always @(*) begin
        ld_reg = {(REG_NUM){1'b0}};
        cl_reg = {(REG_NUM){1'b0}};
        inc_reg = {(REG_NUM){1'b0}};
        dec_reg = {(REG_NUM){1'b0}};
        sr_reg = {(REG_NUM){1'b0}};
        ir_reg = {(REG_NUM){1'b0}};
        sl_reg = {(REG_NUM){1'b0}};
        il_reg = {(REG_NUM){1'b0}};
        mem_addr = {(ADDR_WIDTH){1'b0}};
        mem_data = {(DATA_WIDTH){1'b0}};
        mem_we = 1'b0;
        pc_in = {(PC_WIDTH){1'b0}};
        sp_in = {(PC_WIDTH){1'b0}};

        out_next = out_reg;
        state_next = state_reg;
        alu_oc_reg = 3'b0;

        case (state_reg)
            INIT: begin
                // init pc and sp
                state_next = FETCH_0;
                ld_reg[PC] = 1'b1;
                ld_reg[SP] = 1'b1;
                pc_in = START_PC;
                sp_in = 63;
            end FETCH_0: begin
                // pc points to the next instruction, load it!
                ld_reg[PC] = 1'b1;
                pc_in = pc + 1;
                mem_addr = pc;

                state_next = FETCH_1;
            end FETCH_1: begin
                ld_reg[IR_HIGH] = 1'b1; 
                case (mem_in[15:12])
                    STOP_INST: begin
                        state_next = STOP_STATE;
                    end 
                    IN: begin
                        // indirect 
                        if(mem_in[11] == 1'b1) begin
                            mem_addr = mem_in[10:8];
                            state_next = EXEC_0;
                        end else begin
                            mem_addr = mem_in[10:8];
                            mem_data = in;
                            mem_we = 1'b1;
                            state_next = FETCH_0;
                        end
                    end
                    OUT: begin
                        // load anyway?
                        mem_addr = mem_in[10:8];
                        if(mem_in[11] == 1'b1) begin
                            state_next = FETCH_2;
                        end else begin
                            state_next = EXEC_0;
                        end
                    end
                    MOV: begin
                        if(mem_in[3:0] == 4'b1000) begin
                            ld_reg[PC] = 1'b1;
                            pc_in = pc + 1;
                            mem_addr = pc;
                            state_next = EXEC_0;
                        end else begin
                            mem_addr = mem_in[6:4];
                            if(mem_in[7] == 1'b1) begin
                                state_next = FETCH_2;
                            end else begin
                                state_next = EXEC_0;
                            end
                        end
                    end
                    default: begin
                        mem_addr = mem_in[6:4];
                        if(mem_in[7] == 1'b1) begin
                            state_next = FETCH_2;   
                        end else begin
                            state_next = FETCH_3;   
                        end
                    end
                endcase
            end FETCH_2: begin
                mem_addr = mem_in;
                if(ARITHMETIC == 1'b1) begin
                    state_next = FETCH_3;
                end else begin
                    state_next = EXEC_0;
                end
            end FETCH_3: begin
                ld_reg[ACC] = 1'b1;
                mem_addr = ir_high_out[2:0];
                if(ir_high_out[3] == 1'b1) begin
                    state_next = ADDR_0;
                end else begin
                    state_next = EXEC_0;
                end
            end ADDR_0: begin
                mem_addr = mem_in;
                state_next = EXEC_0;
            end EXEC_0: begin
                alu_oc_reg = (ir_high_out[15:12] - 1);
                case (ir_high_out[15:12])
                    IN: begin
                        mem_addr = mem_in;
                        mem_data = in;
                        mem_we = 1'b1;
                        state_next = FETCH_0;
                    end
                    OUT: begin
                        out_next = mem_in;
                        state_next = FETCH_0;
                    end
                    MOV: begin
                        mem_addr = ir_high_out[10:8];
                        if(ir_high_out[11] == 1'b1) begin
                            ld_reg[ACC] = 1'b1;
                            state_next = EXEC_1;
                        end else begin
                            mem_data = mem_in;
                            mem_we = 1'b1;
                            state_next = FETCH_0;
                        end
                    end
                    default: begin
                        // mem_in + acc
                        ld_reg[ACC] = 1'b1;
                        mem_addr = ir_high_out[10:8];
                        if(ir_high_out[11]) begin
                            state_next = EXEC_1;
                        end else begin
                            mem_data = alu_out;
                            mem_we = 1'b1;
                            state_next = FETCH_0;
                        end
                    end
                endcase
            end EXEC_1: begin
                mem_addr = mem_in;
                mem_we = 1'b1;
                mem_data = a_out;
                state_next = FETCH_0;
            end STOP_STATE: begin
                if(ir_high_out[11:8] != 4'b0000) begin
                    mem_addr = ir_high_out[10:8];
                    if(ir_high_out[11] == 1'b1) begin
                        state_next = STOP_STATE_OUT1_IND;
                    end else begin
                        state_next = STOP_STATE_OUT1;
                    end
                end else if(ir_high_out[7:4] != 4'b000) begin
                    mem_addr = ir_high_out[6:4];
                    if(ir_high_out[7] == 1'b1) begin
                        state_next = STOP_STATE_OUT2_IND;
                    end else begin
                        state_next = STOP_STATE_OUT2;
                    end
                end else if(ir_high_out[3:0] != 4'b0000) begin
                    mem_addr = ir_high_out[2:0];
                    if(ir_high_out[3] == 1'b1) begin
                        state_next = STOP_STATE_OUT3_IND;
                    end else begin
                        state_next = STOP_STATE_OUT3;
                    end
                end else begin
                    state_next = IDLE_STATE;
                end
            end STOP_STATE_OUT1_IND: begin
                mem_addr = mem_in;
                state_next = STOP_STATE_OUT1;
            end STOP_STATE_OUT1: begin
                out_next = mem_in;
                if(ir_high_out[7:4] != 4'b000) begin
                    mem_addr = ir_high_out[6:4];
                    if(ir_high_out[7] == 1'b1) begin
                        state_next = STOP_STATE_OUT2_IND;
                    end else begin
                        state_next = STOP_STATE_OUT2;
                    end
                end else if(ir_high_out[3:0] != 4'b0000) begin
                    mem_addr = ir_high_out[2:0];
                    if(ir_high_out[3] == 1'b1) begin
                        state_next = STOP_STATE_OUT3_IND;
                    end else begin
                        state_next = STOP_STATE_OUT3;
                    end
                end else begin
                    state_next = IDLE_STATE;
                end
            end STOP_STATE_OUT2_IND: begin
                mem_addr = mem_in;
                state_next = STOP_STATE_OUT2;
            end STOP_STATE_OUT2: begin
                out_next = mem_in;
                if(ir_high_out[3:0] != 4'b0000) begin
                    mem_addr = ir_high_out[2:0];
                    if(ir_high_out[3] == 1'b1) begin
                        state_next = STOP_STATE_OUT3_IND;
                    end else begin
                        state_next = STOP_STATE_OUT3;
                    end
                end else begin
                    state_next = IDLE_STATE;
                end
            end STOP_STATE_OUT3_IND: begin
                mem_addr = mem_in;
                state_next = STOP_STATE_OUT3;
            end STOP_STATE_OUT3: begin
                out_next = mem_in;
                state_next = IDLE_STATE;
            end IDLE_STATE: begin
                
            end default: begin
            end
        endcase
    end

endmodule