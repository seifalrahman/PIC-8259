module DataBuffer_TB;
  wire [7:0] D2 , ID;
  reg R2, W2;
  wire [7:0] buffer;

  DataBuffer Buff (
    .D(D2),
    .InternalD(ID),
    .R(R2),
    .W(W2),
    .buffer(buffer)
  );
  assign buffer = 8'b10101010;
  initial begin    
    #10 R2 = 0; W2 = 1;
    #10 R2 = 1; W2 = 0;
    #10 R2 = 1; W2 = 1;
    #10 R2 = 0; W2 = 0;
  end
 
  always @* $monitor("At time %t: D = %b, InternalD = %b, R = %b, W = %b",
                    $time, D2, ID, R2, W2);
endmodule