module DataBuffer_TB;
  wire [7:0] D , ID;
  reg R , W , Flag_From_Cascade;
  reg [7:0] D_buffer , ID_buffer;

  assign D = ((R == 0 && W == 1) || Flag_From_Cascade == 1)  ? ID_buffer : 8'bzzzzzzzz;//CPU read
  //assign ID = (R == 1 && W == 0) ? D_buffer : 8'bzzzzzzzz;//CPU write
  DataBuffer Buff (
    .D(D),
    .InternalData_out(InternalData_out),
    .R(R),
    .W(W),
    .Flag_From_Cascade(Flag_From_Cascade)
  );
  initial begin    
    #10 R = 0; W = 1; ID_buffer = 8'b11111111;
   // #10 Flag_From_Cascade = 1; ID_buffer = 8'b10101010;
  //  #10 R = 1; W = 0;Flag_From_Cascade = 0; D_buffer = 8'b00000000;
  end
 
  always @* $monitor("At time %t: D = %b, InternalD = %b, R = %b, W = %b ,Flag_From_Cascade = %b",
                    $time, D, ID , R, W,Flag_From_Cascade);
endmodule
