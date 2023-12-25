module DataBuffer(
		inout wire     	[7:0]    Data   		,
        	output reg     	[7:0]    InternalD_out		,
		input wire	[7:0]	InternalD_in		,    
            	input wire       	 R        		,
          	input wire        	 W       		,
		input wire		flagFromControl		
);

always @ (*)
begin
	if(R==1 && W==0)//write
		InternalD_out = Data;
end

assign Data = ((R == 0 && W == 1) || flagFromControl == 1) ? InternalD_in : 8'bzzzzzzzz ;//read
endmodule
