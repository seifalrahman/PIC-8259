module Control_Logic(

  //  REMOVE ALL RESETS -------------------------------------------------------------------------------
  // REMEMBER THE FUNCTIONS ------------------------------------------------------------------------------
    

    // Read_writeLogic***********************************************
    input wire  [7:0]   ReadWriteinputData,
    input wire  [2:0]   FlagFromRW ,
    input wire  [2:0]   read2controlRW,
    //***************************************************************
    //Data Buffer ***************************************************
    output reg [7:0]  DataBufferOutput ,
    //***************************************************************
    //IRR************************************************************
    input wire [7:0]  IRRinput ,
    //***************************************************************
    //ISR************************************************************
    input wire [7:0]  ISRinput ,
    //***************************************************************
    //CASCADEMODULE**************************************************
    output reg SP_ENCascade ,
    output reg [7:0] ICW3Cascade ,
    output reg [7:0] ICW2Cascade ,
    output reg SNGL ,
    output wire [7:0] IRRCascade  ,
    //***************************************************************
    //Priority Resolver *********************************************
    input wire [7:0] InterruptID ,  // it has only one bit set
    //***************************************************************	 
    // Interrupt control signals
    output  reg   [7:0]   interrupt_mask,//IMR
    output  logic   [7:0]   interrupt_special_mask,//---------??????
    output  logic   [7:0]   end_of_interrupt,
    output  logic   [2:0]   priority_rotate,
    output  logic           freeze,
    output  logic           latch_in_service,//---------???????
    output  logic   [7:0]   clear_interrupt_request
    
);
reg [7:0] CWregFile [6:0] ; //ICW .....OCW  
reg ICW1,ICW2,ICW3,ICW4,OCW1,OCW2,OCW3 ;
reg AEOI ;
//This Block Stores The ICWs and OCWs in our register File and sets their Flags to indicate that we stored them 

always @ (FlagFromRW or ReadWriteinputData)begin
	if(FlagFromRW==0)begin
		CWregFile[0]=ReadWriteinputData ;
		ICW1=1;
		interrupt_mask = 8'b11111111;
		SP_ENCascade=0;
		SNGL=CWregFile[0][1] ;
		AEOI=0;
		
end
	else if (FlagFromRW==1)begin
		CWregFile[1]=ReadWriteinputData ;
		ICW2=1;
		ICW2Cascade=CWregFile[1] ;
		
end
	else if (FlagFromRW==2)begin
		CWregFile[2]=ReadWriteinputData ;
		ICW3=1;
	        ICW3Cascade=CWregFile[1] ;
		
end
	else if (FlagFromRW==3)begin
		CWregFile[3]=ReadWriteinputData ;
		ICW4=1;
		
		if(CWregFile[3][3]==1)
			SP_ENCascade=CWregFile[3][2];
		if(SP_ENCascade==1&& SNGL==0)//MASTER----CASCADE
			AEOI=CWregFile[3][1];
		else if(SP_ENCascade==0&& SNGL==0)//Slave ------ CASCADE
			AEOI=0;
		else if(SNGL==1) //SINGLE 
			AEOI=CWregFile[3][1];
		
end
	else if (FlagFromRW==4)begin
		CWregFile[4]=ReadWriteinputData ;
		OCW1=1;
		interrupt_mask=ReadWriteinputData ;
end
	else if (FlagFromRW==5)begin
		CWregFile[5]=ReadWriteinputData ;
		OCW2=1 ;
end
	else if (FlagFromRW==6)begin
		CWregFile[6]=ReadWriteinputData ;
		OCW3=1 ;
end
				
    end


// WRITE IMR-------ISR-----IRR onto the data buffer
always @ (read2controlRW)begin
if(read2controlRW==3'b011)begin//IMR
	DataBufferOutput=CWregFile[4] ;
end
else if (read2controlRW==3'b001)begin  //IRR
	DataBufferOutput=IRRinput ;
	
end
else if (read2controlRW==3'b101)begin  //ISR
        DataBufferOutput=ISRinput ;
end
else if (read2controlRW==3'b111)begin  //IRR
        DataBufferOutput=IRRinput ;
end

end

assign IRRCascade = InterruptID ;


    
  // Auto rotate mode
    always @(*) begin
        if (reset)
            auto_rotate_mode <= 1'b0;
            
        //  while intiializing deactivate rotate mode (init phase)
        else if (write_initial_command_word_1 == 1'b1)
            auto_rotate_mode <= 1'b0;
        
        // in case of OCW2 (where it's initialized) if R bit is set -> rotate mode
        else if (write_operation_control_word_2 == 1'b1) begin
            casez (internal_data_bus[7:5])
                3'b000:  auto_rotate_mode <= 1'b0;  // disable auto rotate mode
                3'b100:  auto_rotate_mode <= 1'b1;  // enable  auto rotate mode
                default: auto_rotate_mode <= auto_rotate_mode;
            endcase
        end
        else
            auto_rotate_mode <= auto_rotate_mode;
    end




    // Rotate (Determine priority rotate values)
    // which is used in Priority Resolver
    
    // 0 indicates 1 rotation
    // 2 indicated 3 rotations
    // 6 indicates 7 rotations
    // 7 indicates no rotation
    always @(*) begin
        if (reset)
            priority_rotate <= 3'b111;
            
        //  while intiializing set priority to 7 (no rotation) (init phase)
        else if (write_initial_command_word_1 == 1'b1)
            priority_rotate <= 3'b111;
        
        // in case of auto rotate mode enabled , and an EOI is received then 
        // rotate priorities (checking R bit + EOI are set or not)
        else if ((auto_rotate_mode == 1'b1) && (end_of_acknowledge_sequence == 1'b1))
            // in Case of just finished IS4 -> acknowledge interrupt = 4 (now turned into binary)
            // then rotate by 4 steps (4 indicates 5)
            priority_rotate <= bit2num(acknowledge_interrupt);
        
        // in case of currently writing OCW2:
        else if (write_operation_control_word_2 == 1'b1) begin
            //check R , SL , EOI bits
            casez (internal_data_bus[7:5])
                // 101 -> rotate on non specific EOI
                // sends EOI to show that interrupt is finished
                // now need to have the info about the interrupt that just finished (highest_level_in_service)
                // so that we clear the ISR correctly and rotate for the next interrupt 
                3'b101:  priority_rotate <= bit2num(highest_level_in_service);  // non specific EOI -> highest_level_in_service
                
                // Take priority from L2~L0 ( in case of specific rotation )
                3'b11x:  priority_rotate <= internal_data_bus[2:0];
                default: priority_rotate <= priority_rotate;
            endcase
        end
        else
            priority_rotate <= priority_rotate;
    end
    
    
    
    // clear_interrupt_request
    always @(*) begin
        if (write_initial_command_word_1 == 1'b1)
            clear_interrupt_request = 8'b11111111;
        else if (latch_in_service == 1'b0)
            clear_interrupt_request = 8'b00000000;
        else
            clear_interrupt_request = interrupt;
    end
endmodule
