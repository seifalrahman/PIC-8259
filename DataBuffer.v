module DataBuffer (
  inout wire [7:0] D, InternalD,
  input wire R , W ,
  input Flag_From_Cascade 
);
    assign D = ((R == 0 && W == 1) || Flag_From_Cascade == 1) ? InternalD : 8'bzzzzzzzz;//CPU read
    assign InternalD = (R == 1 && W == 0) ? D : 8'bzzzzzzzz;//CPU write
endmodule
