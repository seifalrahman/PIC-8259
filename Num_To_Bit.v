module Num_To_Bit (
    input [2:0] source,
    output wire [7:0] num2bit
);

    assign num2bit = (source == 3'b000) ? 8'b00000001:
                    (source == 3'b001) ? 8'b00000010 :
                    (source == 3'b010) ? 8'b00000100 :
                    (source == 3'b011) ? 8'b00001000 :
                    (source == 3'b100) ? 8'b00010000 :
                    (source == 3'b101) ? 8'b00100000 :
                    (source == 3'b110) ? 8'b01000000 :
                    (source == 3'b111) ? 8'b10000000 : 8'b00000000;

endmodule
