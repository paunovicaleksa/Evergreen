module bcd (
    input [5:0] in,
    output [3:0] ones,
    output [3:0] tens
);

    assign tens = in / 10;
    assign ones = in % 10;
    
endmodule