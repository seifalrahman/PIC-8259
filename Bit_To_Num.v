module Bit_To_Num (
    input [7:0] source,
    output reg [2:0] bit2num
);

    always @(*)
        if      (source[0] == 1'b1) bit2num = 3'b000;
        else if (source[1] == 1'b1) bit2num = 3'b001;
        else if (source[2] == 1'b1) bit2num = 3'b010;
        else if (source[3] == 1'b1) bit2num = 3'b011;
        else if (source[4] == 1'b1) bit2num = 3'b100;
        else if (source[5] == 1'b1) bit2num = 3'b101;
        else if (source[6] == 1'b1) bit2num = 3'b110;
        else if (source[7] == 1'b1) bit2num = 3'b111;
        else                        bit2num = 3'b111;

endmodule
