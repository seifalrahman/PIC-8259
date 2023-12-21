module Control_Logic(   

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
    input wire INTA  ,
    output reg INT   ,
    // Interrupt control signals
    output  reg   [7:0]   interrupt_mask,//IMR
    output  reg   [7:0]   interrupt_special_mask,
    output  reg   [7:0]   end_of_interrupt,
    output  reg   [2:0]   priority_rotate,
    output  reg           freeze,
    output  wire           latch_in_service,//---------???????
    output  wire   [7:0]   clear_interrupt_request
    
);
    reg [7:0] CWregFile [6:0] ; //ICW .....OCW
    reg auto_rotate_mode = 1'b0;
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
		interrupt_mask = 8'b11111111;
                end_of_interrupt = 8'b11111111;
                clear_interrupt_request = 8'b11111111;
        
                priority_rotate <= 3'b111;  //  while intiializing set priority to 7 (no rotation) (init phase)
                auto_rotate_mode = 1'b0;    //  while intiializing deactivate rotate mode (init phase)
		
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


//register to hold result of Num_To_Bit(value data bus) in case of specific EOI
    reg [7:0] Specific_EOI = 8'b00000000;
    
    Num_To_Bit n1(
        .source(internal_data_bus[2:0]),
        .num2bit(Specific_EOI)
    );



reg cnt=0 ;
always @(posedge INTA)begin
	
	cnt=cnt+1;
	if(cnt==1)
		end_of_acknowledge_sequence=0 ;
	else if(cnt==2)begin
		cnt=0;
		end_of_acknowledge_sequence=1 ;
		freeze=0;
	end
	
end
always @ (negedge INTA)begin
freeze=1;
end


always @ (InterruptID)begin
	if(InterruptID!=0)
		INT=1 ;
	else
		INT=0 ;

end

// Special mask
always @(*) begin
        
        // due to functionality of interrupt_special_mask it should initially start with zeros
        // as it's different from interrupt mask (temporarily change enabled/disabled interrupts)
        if (reset)
            interrupt_special_mask <= 8'b00000000;
        
        // in case of still writing on ICW1 set interrupt special mask to initial state
        else if (write_initial_command_word_1 == 1'b1)
            interrupt_special_mask <= 8'b00000000;
        
        // special mask mode is diabled
        else if (special_mask_mode == 1'b0)
            interrupt_special_mask <= 8'b00000000;
       
        // in case of writing on OCW1 while special mask mode is enabled -> put data on data line 
        // into interrupt special mask reg
        else if ((write_operation_control_word_1_registers  == 1'b1) && (special_mask_mode == 1'b1))
            interrupt_special_mask <= internal_data_bus;
        
        else
            interrupt_special_mask <= interrupt_special_mask;
end
    
    
    // End of interrupt
always @(*) begin
        
        if ((AEOI == 1'b1) && (end_of_acknowledge_sequence == 1'b1))
            end_of_interrupt = acknowledge_interrupt;
        else if (OCW2) begin
            case (internal_data_bus[6:5])
                2'b01:   end_of_interrupt = highest_level_in_service;
                2'b11:   end_of_interrupt = Specific_EOI;
                default: end_of_interrupt = 8'b00000000;
            endcase
        end
        else
            end_of_interrupt = 8'b00000000;
end
    
    
    // Auto rotate mode
always @(*) begin
        // in case of OCW2 (where it's initialized) if R bit is set -> rotate mode
        if (OCW2 == 1'b1 && AEOI== 1'b1) begin
            case(internal_data_bus[7:5])
                3'b000:  auto_rotate_mode <= 1'b0;  // disable auto rotate mode (AEOI)
                3'b100:  auto_rotate_mode <= 1'b1;  // enable  auto rotate mode (AEOI)
                default: auto_rotate_mode <= auto_rotate_mode;
            endcase
        end
        else
            auto_rotate_mode <= auto_rotate_mode;
end


    // Rotate (Determine priority rotate values)
    // which is used in Priority Resolver
    
    // Used to hold results after changing Bits to a Number
    reg [2:0] Non_spec_EOI_rotation = 3'b000;
    reg [2:0] AEOI_Rotation = 3'b000;
    
    Bit_To_Num b1( 
        .source(highest_level_in_service), 
        .bit2num(Non_spec_EOI_rotation)
    );
    Bit_To_Num b2( 
        .source(acknowledge_interrupt), 
        .bit2num(AEOI_Rotation)
    );
    
    // Rotate (Determine priority rotate values)
    // which is used in Priority Resolver
always @(*) begin

        // in case of (AEOI mode only) auto rotate mode enabled , and an AEOI is received then 
        // rotate priorities (checking R bit + EOI are set or not)
        if ((auto_rotate_mode == 1'b1) && (end_of_acknowledge_sequence == 1'b1))
            // in Case of just finished IS4 -> acknowledge interrupt = 4 (now turned into binary)
            // then rotate by 4 steps (4 indicates 5)
            priority_rotate <= AEOI_Rotation;
        
        // in case of currently writing OCW2:
        else if (OCW2) begin
            //check R , SL , EOI bits
            case (internal_data_bus[7:5])
                // 101 -> rotate on non specific EOI
                // sends EOI to show that interrupt is finished
                // now need to have the info about the interrupt that just finished (highest_level_in_service)
                // so that we clear the ISR correctly and rotate for the next interrupt 
                3'b101:  priority_rotate <= Non_spec_EOI_rotation;  // non specific EOI -> clear highest_level_in_service
                
                // Take priority rotation from L2~L0 ( in case of specific rotation )
                3'b110:  priority_rotate <= internal_data_bus[2:0];
                3'b111:  priority_rotate <= internal_data_bus[2:0];
                default: priority_rotate <= priority_rotate;
            endcase
        end
        else
            priority_rotate <= priority_rotate;
end
    
    
    // clear_interrupt_request
always @(*) begin
        if (latch_in_service == 1'b0)
            clear_interrupt_request = 8'b00000000;
        else
            clear_interrupt_request = interrupt;
end
   

 
endmodule
