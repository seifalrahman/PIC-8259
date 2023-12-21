module DataBuffer (
             inout wire     [7:0]     Data    ,     
           inout wire     [7:0]    InternalD,
             input wire         R    ,
           input wire         W        
);
reg [7:0] buffer;
always @(*)
begin
    buffer = (R == 0 && W == 1) ? InternalD : buffer;//read
    buffer = (R == 1 && W == 0) ? Data : buffer;//write
end
  assign Data = (R == 0 && W == 1) ? buffer : 8'bzzzzzzzz;//read
  assign InternalD = (R == 1 && W == 0) ? buffer : 8'bzzzzzzzz;//write
endmodule