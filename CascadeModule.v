//inputs from conrol logic to whether this device is slave or master 
module Cascademodule (inout wire [2:0]CAS , 
		      input wire SP_EN //Master or Slave ---->Control Logic ICW4,
		      input wire [7:0]ICW3 ,
		      input wire SNGL 	 
		      input wire INTA /*The cascade bus lines are normally low and 
					will contain the slave address code from the trailing edge of
					the first INTA pulse to the trailing edge of the third
					pulse*/
		      input wire [2:0] IRR
		      o);

reg [2:0] ID ;
reg [7:0] hasSlave ;
reg  cnt =0;
reg [2:0] CASBUFFER ;
always @ (*)begin
	if(0==SNGL)begin
		if(0==SP_EN)
			ID=ICW3[2:0] ;

		
		else if(1==SP_EN)
			hasSlave=ICW3 ;	
		
	end
	else begin
		SP_EN=0;
	     end

end
always@(posedge INTA)begin
	if(cnt==0)begin
		if(SP_EN==1)
			CASBUFFER=IRR ;
		else 
			C
		
			
	end
		
end
assign CAS =CASBUFFER ;






endmodule

