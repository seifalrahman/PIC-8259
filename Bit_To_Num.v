module Bit_To_Num (
    input wire [7:0] source,
    output wire [2:0] bit2num
);

    assign bit2num = (source[0]) ? 3'b000 :
                    (source[1]) ? 3'b001 :
                    (source[2]) ? 3'b010 :
                    (source[3]) ? 3'b011 :
                    (source[4]) ? 3'b100 :
                    (source[5]) ? 3'b101 :
                    (source[6]) ? 3'b110 :
                    (source[7]) ? 3'b111 : 3'b111;

endmodule
