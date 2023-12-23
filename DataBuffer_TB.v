`timescale 1ns /100ps
module DataBuffer_TB;
  wire [7:0] CPU_IN_Data , CPU_OUT_Data , IN_InternalD , OUT_InternalD;
  reg R, W;
  reg [7:0] CPU_IN_Data_reg , IN_InternalD_reg ;

  DataBuffer Buff (
    .CPU_IN_Data(CPU_IN_Data),
    .CPU_OUT_Data(CPU_OUT_Data),
    .IN_InternalD(IN_InternalD),
    .OUT_InternalD(OUT_InternalD),
    .R(R)            ,
    .W(W)            ,
    .Flag_From_Cascade()
  );
  assign IN_InternalD = IN_InternalD_reg;
  assign CPU_IN_Data = CPU_IN_Data_reg;
  initial begin    
    #10 R = 0; W = 1; IN_InternalD_reg = 8'b10101010; //READ
    #10 R = 1; W = 0; CPU_IN_Data_reg  = 8'b11111111; //WRITE
    #10 R = 1; W = 1;
    #10 R = 0; W = 0;
  end
 
  always @* $monitor("At time %t: CPU_OUT_Data = %b, OUT_InternalD = %b, IN_InternalD = %b, CPU_IN_Data = %b, R = %b, W = %b ",
                    $time, CPU_OUT_Data , OUT_InternalD , IN_InternalD  ,CPU_IN_Data,  R , W );
endmodule
