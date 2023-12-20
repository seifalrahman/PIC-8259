module rotate_right(
    input [7:0] source, //input reg
    input [2:0] rotate, //amount of rotation ... 0 -> 1  rotate
                                               //2 -> 3  rotates
                                               //7 -> no rotates
    output reg [7:0] rotated_R_output
);

    always @*
        case (rotate)
            3'b000:  rotated_R_output = { source[0],   source[7:1] };
            3'b001:  rotated_R_output = { source[1:0], source[7:2] };
            3'b010:  rotated_R_output = { source[2:0], source[7:3] };
            3'b011:  rotated_R_output = { source[3:0], source[7:4] };
            3'b100:  rotated_R_output = { source[4:0], source[7:5] };
            3'b101:  rotated_R_output = { source[5:0], source[7:6] };
            3'b110:  rotated_R_output = { source[6:0], source[7]   };
            3'b111:  rotated_R_output = source;
            default: rotated_R_output = source;
        endcase
endmodule