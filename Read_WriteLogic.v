module Read_WriteLogic (
			input wire RD,WR,A0,CS,[7:0]inputData,
                        output reg [7:0] control_output_Register,
                        output reg [2:0]Flag,	
                        output reg [2:0]read2control 
			);


reg [7:0] regFile [6:0] ; //ICW .....OCW ;
reg ICW1 ,ICW2,ICW3,ICW4,OCW1,OCW2,OCW3 ;//flags for ICW ...... OCW
reg [1:0] LastOCW ;//TO KNOW LAST OCW CREATED 
reg [3:0]counter =0 ;

always @ (WR or inputData)
begin : Write_Logic
 	
	if(WR==0 && RD==1&& CS==0)
	begin
		ICW1=(~A0) &  inputData[4] ;/*Detecting whether the recieved data is ICW1 or ICW2 , Current InputData is ICW1*/
		ICW2 =A0 ;
		
		if(counter==2)
		begin
	   	 	/*Before proceeding in code we had to know whether we will use ICW3 and ICW4 or not and if not so we will start recieving OCWs*/
	   	 	ICW3=A0 &(~regFile[0][1]) ;/*SNGL Bit in ICW1*/ 
	   	 	ICW4=regFile[0][0] ;/*IC4 Bit in ICW1*/
			if(ICW3==0 && ICW4==0)
			  	counter=5 ;//start recieving the OCWs
		end
		
		if(ICW1==1 && ICW2==0 &&counter==0)
		begin
	    		regFile[0]=inputData ; 
	    		/*it happens to be ICW1 , so store it in the register file and increment the counter to keep track of the sequence of the recieved data*/
	    		counter=counter+1 ;
	    		/*we say that lastOCW =0 because we had not sent any OCWs till now 
	    		and we need to keep track of that in case we had a read signal so we should make the control logic output the IRR*/
	    		LastOCW=0 ;
	    		Flag=0;/*we send the control logic flag=0 to know that it is ICW1 */
		end
		else if (ICW2==1 && ICW1==0 &&counter==1)
		begin
	    		regFile[1]=inputData;
	    		counter=counter+1 ;
	    		Flag=1;
	    		LastOCW=0 ;
		end
		else if(counter==2 && ICW3==1)
		begin
			regFile[2]=inputData ; //if it is ICW3 
			LastOCW=0;
			if(ICW4==0)
			begin
    				counter=5 ;//start recieving the OCWs
				Flag=2 ;
			end
			else
			    counter=counter+1 ;
		end
		
		else if((counter==3 &&ICW4==1&&ICW3==1)||(counter==2 &&ICW4==1&& ICW3==0))
		begin 
		    /*we noticed that ICW3 is not obligatory to send before ICW2 so we had the different values of counter into consideration while detecting ICW4*/
    			LastOCW=0 ;
    			regFile[3]=inputData ;
    			Flag=3;
    			counter=5;//start recieving the OCWs
		end
			
		else if(counter==5 && A0)
		begin// Detecting if it is OCW1
			regFile[4]=inputData;  
			Flag=4;
			LastOCW=1;//we keep track whether it is OCW1 or OCW2 or OCW3
		end
	
		else if(counter==5 && ~A0 && ~inputData[3] &&~inputData[4] )
		begin // Detecting if it is OCW2
		    regFile[5]=inputData;
		    Flag=5 ;
		    LastOCW=2;//we keep track whether it is OCW1 or OCW2 or OCW3
		end
		else if(counter==5 && ~A0 && inputData[3] &&~inputData[4] )
		begin// Detecting if it is OCW3 
		    regFile[6]=inputData;
		    Flag=6;
		    LastOCW=3; //we keep track whether it is OCW1 or OCW2 or OCW3
		end 
		control_output_Register=inputData;

	end 
	else
	begin
    
	end        
end
always @(RD) 
begin : Read_Logic
	if(WR==1 && RD==0&& CS==0)
	begin
            	//IMR-----IRR-----ISR
            	/*we want to know which register to read */
		if(A0==1)  //Page.17 ---> right column       (DataSheet)
                read2control=3'b011;//read IMR

            	else if(LastOCW==0) //Page.17 ---> right column  (DataSheet)
                read2control=3'b001; //read IRR  (Default)

            	else if(LastOCW==3)
		begin 
		 //Page.17 ---> left column  (DataSheet)
                if((regFile[6]&8'b00000011) ==8'b00000011)
                    read2control=3'b101 ; //read ISR
                else if ((regFile[6]&8'b00000011) ==8'b00000010)
                    read2control=3'b111 ; //read IRR
            	end

    	end
end

endmodule
