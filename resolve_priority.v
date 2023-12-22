module resolve_priority(
    input [7:0] source,
    output reg [7:0] resolved_priority
);

    always @* begin
        if (source[0] == 1'b1)      resolved_priority = 8'b00000001;
        else if (source[1] == 1'b1) resolved_priority = 8'b00000010;
        else if (source[2] == 1'b1) resolved_priority = 8'b00000100;
        else if (source[3] == 1'b1) resolved_priority = 8'b00001000;
        else if (source[4] == 1'b1) resolved_priority = 8'b00010000;
        else if (source[5] == 1'b1) resolved_priority = 8'b00100000;
        else if (source[6] == 1'b1) resolved_priority = 8'b01000000;
        else if (source[7] == 1'b1) resolved_priority = 8'b10000000;
        else resolved_priority = 8'b00000000;
    end

endmodule
