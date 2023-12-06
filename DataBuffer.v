module DataBuffer (
  inout wire [7:0] D, InternalD,
  input wire R, W
  ,output reg [7:0] buffer
);
always @(*)
begin
	buffer = (R == 0 && W == 1) ? InternalD : buffer;//read
	buffer = (R == 1 && W == 0) ? D : buffer;//write
end
	assign D = (R == 0 && W == 1) ? buffer : 8'bzzzzzzzz;//CPU read
	assign InternalD = (R == 1 && W == 0) ? buffer : 8'bzzzzzzzz;//CPU write
endmodule
