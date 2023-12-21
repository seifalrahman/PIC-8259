module Cascademodule (inout wire [2:0]CAS , 
              input wire SP_EN, //Master or Slave ---->Control Logic ICW4,
              input wire [7:0]ICW3,IRR,ICW2,
              input wire SNGL     , 
              input wire INTA ,
		/*The cascade bus lines are normally low and 
                  will contain the slave address code from the trailing edge of
                  the first INTA pulse to the trailing edge of the third
                  pulse*/
              output wire [7:0] codeAddress
		);

reg [2:0] ID ;
reg [3:0]IRRtemp;
reg [7:0] hasSlave ;
reg flagCodeAddress;
reg [2:0] CASBUFFER ;
reg [7:0] CODEADDRESS;

//For IRR------>IRRtemp
/*
*Note : We send the highest priority IRR from Priority resolver and we have to edit this in control unit
*i will convert it to switc case 
*/
always @(IRR)begin
	if(IRR == 8'b00000001)
		IRRtemp = 4'b0000;
	else if(IRR == 8'b00000010)
		IRRtemp = 4'b0001;
	else if (IRR == 8'b00000100)
		IRRtemp = 4'b0010;
	else if (IRR == 8'b00001000)
		IRRtemp = 4'b0011;
	else if (IRR == 8'b00010000)
		IRRtemp = 4'b0100;
	else if (IRR == 8'b00100000)
		IRRtemp = 4'b0101;
	else if (IRR == 8'b01000000)
		IRRtemp = 4'b0110;
	else if (IRR == 8'b10000000)
		IRRtemp = 4'b0111;
	else
		IRRtemp = 4'b1000;		
end

always @ (*)begin
    if(0==SNGL)begin
        if(0==SP_EN) begin
            ID<=ICW3[2:0] ;//Slave ID

            hasSlave<=8'b00000000 ;//in order not to infer latches
            end                
        else if(1==SP_EN)
	begin
            hasSlave<=ICW3 ;    

            ID<=3'b000;//in order not to infer latches
        
    	end
	end
    else 
	begin
        	ID<=3'b000;//in order not to infer latches
        	hasSlave<=8'b00000000 ;//in order not to infer latches
        end

end
always@(posedge INTA)begin// the positive edge is the trailing edge 
    
        if(SP_EN==1) //MASTER
            CASBUFFER<=IRRtemp[2:0];
/*I assumed that the priority resolver will send me the highest priority so i don't need
any further check on the priority 
*/           
        else 
            if(CAS==ID || SNGL==1)begin  
/* in case it is in single mode so we put the address on the data buffer anyways
*in case it is in cascade mode we have to check whether the slave is enabled or not 
*/                CODEADDRESS<={ICW2[7:3],IRRtemp[2:0]} ;//Assumed Code Address
		flagCodeAddress = 1; 
                end  
end

always@(negedge INTA)begin
	 flagCodeAddress = 0;
end

assign CAS = CASBUFFER ;

assign codeAddress = (flagCodeAddress == 1 && SP_EN ==0 ) ? CODEADDRESS : 8'bzzzzzzzz;

endmodule