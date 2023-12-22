module DataBuffer (
             input wire     [7:0]     CPU_IN_Data    ,
           output wire     [7:0]    CPU_OUT_Data    ,
           input wire     [7:0]    IN_InternalD    ,
           output wire    [7:0]    OUT_InternalD    ,     
             input wire         R        ,
           input wire         W        ,
           input wire        Flag_From_Cascade 
);
reg [7:0] CPU_OUT_Data_reg , OUT_InternalD_reg;
always @(*)
begin
    if((R == 0 && W == 1) || Flag_From_Cascade == 1)
        CPU_OUT_Data_reg =IN_InternalD ;//read
    else if (R == 1 && W == 0)
        OUT_InternalD_reg = CPU_IN_Data ;//write
    else begin // saty in the same value
        CPU_OUT_Data_reg = CPU_OUT_Data_reg;
        OUT_InternalD_reg = OUT_InternalD_reg;
         end
end
  assign CPU_OUT_Data = CPU_OUT_Data_reg;
  assign OUT_InternalD = OUT_InternalD_reg;
endmodule
