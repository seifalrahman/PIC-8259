`timescale 1ns /100ps
module PIC_8259A (
		  input wire [7:0]  	D_IN 	,
		  output wire [7:0]	D_OUT	,
		  inout wire [2:0]	CAS	,
		  inout wire 		SP_EN_n	,
		  input wire		RD_n 	, 
		  input wire		WR_n 	,
		  input wire		A0 	,
		  input wire		CS_n	,
		  input wire [7:0]	IR 	,
		  input wire		INTA_n	,
		  output wire		INT	
		);
//internal_Bus
wire [7:0] InternalData_IN , InternalData_OUT;

//Cascade-->DataBuffer
wire Flag_From_Cascade;

DataBuffer DataBusBuffer(
	.CPU_IN_Data(D_IN)			,
	.CPU_OUT_Data(D_OUT)			,
	.IN_InternalD(InternalData_IN)		,
	.OUT_InternalD(InternalData_OUT)	,
	.R(RD_n)				,
	.W(WR_n)				,
	.Flag_From_Cascade(Flag_From_Cascade)
	);


//ReadWrite-->Control
wire [7:0] W_Data_2Control;//ICWs and OCWs
wire [2:0] W_Flag_2Control;//flags from 0 to 6
wire [2:0] R_Flag_2Control;//flag to identifi read register
	
Read_WriteLogic ReadWriteLogic(
	.RD(RD_n)					,
	.WR(WR_n)					,
	.A0(A0)						,
	.CS(CS_n)					,
	.inputRegister(InternalData_OUT)		,
	.control_output_Register(W_Data_2Control)	,
	.Flag(W_Flag_2Control)				,
	.read2control(R_Flag_2Control)					
	);


//Control-->Cascade
wire [7:0] ICW3Cascade	;
wire [7:0] IRRCascade	; //it has only one bit set from ISR
wire [7:0] ICW2Cascade	; 
wire SP_ENCascade;	
wire SNGL;//to check singlr or cascade mode
 
Cascademodule Cascade_Buffer_Comparator(
	.CAS(CAS)					,
	.SP_EN(SP_ENCascade)				,
	.ICW3(ICW3Cascade)				,
	.IRR(IRRCascade)				,
	.ICW2(ICW2Cascade)				,	
	.SNGL(SNGL)					,
	.INTA(INTA_n)					,
	.codeAddress(InternalData_IN)			,
	.flagCodeAddress(Flag_From_Cascade)
	);


//Control-->IRR
wire edge_level_config;
wire freeze;
wire [7:0] clear_interrupt_request;

//IRR-->(Priority & Control)
wire [7:0] IRQs_2Pri_Resolver;

Interrupt_Request IRR(
	.edge_level_config(edge_level_config)		,
	.freeze(freeze)					,
	.clear_interrupt_req(clear_interrupt_request)	,
	.interrupt_req_pin(IR)				,
	.interrupt_req_register(IRQs_2Pri_Resolver)			
	);


//Control-->(Priority & ISR)
wire [2:0] priority_rotate;
wire [7:0] interrupt_mask;
wire [7:0] interrupt_special_mask;

//ISR-->Priority
wire [7:0] ISR_2Pri_Control;

//Priority -->(Control & ISR)
wire [7:0] InterruptID;

Priority_Resolver Pri_Res(
	.priority_rotate(priority_rotate)		,
	.interrupt_mask(interrupt_mask)			,
	.interrupt_special_mask(interrupt_special_mask)	,
	.interrupt_request_register(IRQs_2Pri_Resolver)	,
	.in_service_register(ISR_2Pri_Control)		,
	.interrupt(InterruptID)					
	);


//Control-->ISR
wire Latch;
wire [7:0] end_of_interrupt;

//ISR-->Control
wire [7:0] highest_IS;

In_Service ISR (
	.priority_rotate(priority_rotate)		,
	.interrupt_special_mask(interrupt_special_mask)	,
	.interrupt(InterruptID)				,
	.latch_in_service(Latch)			,
	.end_of_interrupt(end_of_interrupt)		,
	.in_service_register(ISR_2Pri_Control)		,
	.highest_level_in_service(highest_IS)			
	);




Control_Logic CONTROL_LOGIC(
	//ReadWrite-->Control
	.ReadWriteinputData(W_Data_2Control)		,		 
	.FlagFromRW(W_Flag_2Control)			,		
	.read2controlRW(R_Flag_2Control)		,		
	//internal_Bus
	.DataBufferOutput(InternalData_IN)		,
	//IRR-->Control
	.IRRinput(IRQs_2Pri_Resolver)			,
	//Control-->IRR
	.edge_level_config(edge_level_config)		,
	//ISR-->Control
	.ISRinput(ISR_2Pri_Control)			,
	.highest_level_in_service(highest_IS)		,
	//Control-->Cascade
	.SP_ENCascade(SP_ENCascade)			,
	.ICW3Cascade(ICW3Cascade)			,
	.ICW2Cascade(ICW2Cascade)			,
	.SNGL(SNGL)					,
	.IRRCascade(IRRCascade)				,
	//Priority-->Control
	.InterruptID(InterruptID)			,
	//Top_Module
	.INTA(INTA_n)					,
	.INT(INT)					,
	//Control-->(Priority & ISR)
	.interrupt_mask(interrupt_mask)			,
	.interrupt_special_mask(interrupt_special_mask)	,
	.priority_rotate(priority_rotate)		,
	//Control-->ISR
	.end_of_interrupt(end_of_interrupt)		,
	.latch_in_service(Latch)			,
	//Control-->IRR
	.freeze(freeze)					,
	.clear_interrupt_request(clear_interrupt_request)			
	);

endmodule
		
module PIC_8259_TestBench ( );

reg           chip_select;
reg           read_enable;
reg            write_enable;
reg            A0;
reg   [7:0]    data_bus_in;
reg   [2:0]   	  CAS;
reg             SP_EN;
reg           	  INTA;
reg           	  INT;
reg   [7:0]      IRR ;

wire 	  chip_select_wire;
wire	read_enable_wire;
wire	write_enable_wire;
wire	 A0_wire;
wire	[7:0]    data_bus_wire_in;
wire	[7:0]	 data_bus_wire_out;
wire	[2:0]   	  CAS_wire;
wire	SP_EN_wire;
wire	INTA_wire;
wire	INT_wire;
wire	[7:0]      IRR_wire;

assign  chip_select_wire = chip_select;
assign 	read_enable_wire = read_enable;
assign 	write_enable_wire = write_enable;
assign   A0_wire =  A0;
assign 	data_bus_wire_in = data_bus_in;
assign 	CAS_wire = CAS;
assign SP_EN_wire = SP_EN;
assign INTA_wire = INTA;
assign INT_wire = INT;
assign IRR_wire = IRR;


PIC_8259A pic (
    .CS_n(chip_select_wire),
    .RD_n(read_enable_wire),
    .WR_n(write_enable_wire),
    .A0(A0_wire),
    .CAS(CAS_wire),
    .SP_EN_n(SP_EN_wire),
    .D_IN(data_bus_wire_in),
    .D_OUT(data_bus_wire_out),
    .INTA_n(INTA_wire),
    .INT(INT_wire),
    .IR(IRR_wire)
  );


task TASK_INIT;
begin
    #10 ;
    CAS                     = 1'b1;
    read_enable             = 1'b1;
    write_enable            = 1'b1;
    A0                      = 1'b0;
    data_bus_in                = 8'b00000000;
    CAS                     = 3'b000;
    SP_EN                   = 1'b0;
    INTA                    = 1'b1;
    IRR                     = 8'b00000000;
    
end
endtask


// Task : Write data
task TASK_WRITE_DATA;
  input  addr;
  input [7:0] data;
begin
    #10; // Assuming no delay for this step
	 A0            = addr;
    data_bus_in      = data;
	#5
    chip_select   = 1'b0;
    write_enable  = 1'b0;
    read_enable   = 1'b1;
   
end
endtask




// Task : Read data
task TASK_READ_DATA;
  input  addr;
begin
    #10; // Assuming no delay for this step
    chip_select   = 1'b0;
    read_enable   = 1'b0;
    write_enable  = 1'b1;
    A0        = addr;
    
end

endtask


// Task : Interrupt request
task TASK_INTERRUPT_REQUEST;
  input [7:0] request;
begin
    #10; // Assuming no delay for this step
    IRR = request;
    #10; // Assuming a delay of 1 time unit
    IRR = 8'b00000000;
end
endtask




// Task : Send specific EOI
task TASK_SEND_SPECIFIC_EOI;
  input [2:0] int_no;
begin
    TASK_WRITE_DATA(1'b0, {8'b01100, int_no});
end
endtask







// Task : Send non-specific EOI
task TASK_SEND_NON_SPECIFIC_EOI;
begin
    TASK_WRITE_DATA(1'b0, 8'b00100000);
end
endtask


//-------------------

//----------------------------

//---------------------------

task TASK_SEND_ACK_TO_8086;
begin
    INTA = 1'b1;
    #10;
    INTA = 1'b0;
    #10;
    INTA = 1'b1;
    #10;
    INTA = 1'b0;
    #10;
    INTA = 1'b1;
end
endtask

/***************************************************
task TASK_SEND_ACK_TO_8086_SLAVE;
  input [2:0] slave_id;
begin
    INTA = 1'b1;
    CAS = 3'b000;
    #1;
    INTA = 1'b0;
    #0.5;
    CAS = slave_id;
    #0.5;
    INTA = 1'b1;
    #1;
    INTA = 1'b0;
    #1;
    INTA = 1'b1;
    CAS = 3'b000;
end
endtask;
********************************************************/
task TASK_8086_NORMAL_INTERRUPT_TEST();
    begin
        #10;
 
        // ICW1
        TASK_WRITE_DATA(1'b0, 8'b00010111);//EDGE_TRIGGERED---SINGLE----ICW4->allowed
        // ICW2
        TASK_WRITE_DATA(1'b1, 8'b10101000);//Vector Address={10101,IRR}
        // ICW4
        TASK_WRITE_DATA(1'b1, 8'b00000001);//NORMAL EOI---NON_BUFFERED
        // OCW1
        TASK_WRITE_DATA(1'b1, 8'b00000000);//all interrupts are unmasked 
        // OCW3
        TASK_WRITE_DATA(1'b0, 8'b00001000);

        // Interrupt
        TASK_INTERRUPT_REQUEST(8'b00000001);
        TASK_SEND_ACK_TO_8086();
        TASK_SEND_SPECIFIC_EOI(3'b000);

        TASK_INTERRUPT_REQUEST(8'b00000010);
        TASK_SEND_ACK_TO_8086();
        TASK_SEND_SPECIFIC_EOI(3'b001);

        TASK_INTERRUPT_REQUEST(8'b00000100);
        TASK_SEND_ACK_TO_8086();
        TASK_SEND_SPECIFIC_EOI(3'b010);

        TASK_INTERRUPT_REQUEST(8'b00001000);
        TASK_SEND_ACK_TO_8086();
        TASK_SEND_SPECIFIC_EOI(3'b011);

        TASK_INTERRUPT_REQUEST(8'b00010000);
        TASK_SEND_ACK_TO_8086();
        TASK_SEND_SPECIFIC_EOI(3'b100);

        TASK_INTERRUPT_REQUEST(8'b00100000);
        TASK_SEND_ACK_TO_8086();
        TASK_SEND_SPECIFIC_EOI(3'b101);

        TASK_INTERRUPT_REQUEST(8'b01000000);
        TASK_SEND_ACK_TO_8086();
        TASK_SEND_SPECIFIC_EOI(3'b110);

        TASK_INTERRUPT_REQUEST(8'b10000000);
        TASK_SEND_ACK_TO_8086();
        TASK_SEND_SPECIFIC_EOI(3'b111);
//**********************************************************************************//
        
        // ICW1
        TASK_WRITE_DATA(1'b0, 8'b00011111);
        // ICW2
        TASK_WRITE_DATA(1'b1, 8'b11101000);
        // ICW4
        TASK_WRITE_DATA(1'b1, 8'b00000011);//AEOI
        // OCW1
        TASK_WRITE_DATA(1'b1, 8'b00000000);
        // OCW3
        TASK_WRITE_DATA(1'b0, 8'b00001000);

        // Interrupt
        TASK_INTERRUPT_REQUEST(8'b00000001);
        TASK_SEND_ACK_TO_8086();
        

//*********************************************************************************//        
        //4
        #10;
    end
    endtask
///////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////
task TASK_READING_STATUS_TEST();
    begin
        #10;
        // ICW1
        TASK_WRITE_DATA(1'b0, 8'b00011111);
        // ICW2
        TASK_WRITE_DATA(1'b1, 8'b00000000);
        // ICW4
        TASK_WRITE_DATA(1'b1, 8'b00000001);
        // OCW1
        TASK_WRITE_DATA(1'b1, 8'b00000000);
        // OCW3
        TASK_WRITE_DATA(1'b0, 8'b00001000);

        
        // OCW3
        TASK_WRITE_DATA(1'b0, 8'b00001010);
        TASK_READ_DATA(1'b0);//IRR will be sent 

        TASK_INTERRUPT_REQUEST(8'b00000001);
        TASK_SEND_ACK_TO_8086();
        #10;

        TASK_INTERRUPT_REQUEST(8'b00000001);
        TASK_READ_DATA(1'b0);//IRR will be sent 

        TASK_INTERRUPT_REQUEST(8'b00000010);
        TASK_READ_DATA(1'b0);//IRR will be sent 

        TASK_INTERRUPT_REQUEST(8'b00000100);
        TASK_READ_DATA(1'b0);//IRR will be sent 

        TASK_INTERRUPT_REQUEST(8'b00001000);
        TASK_READ_DATA(1'b0);//IRR will be sent 

        TASK_INTERRUPT_REQUEST(8'b00010000);
        TASK_READ_DATA(1'b0);//IRR will be sent 

        TASK_INTERRUPT_REQUEST(8'b00100000);
        TASK_READ_DATA(1'b0);//IRR will be sent 

        TASK_INTERRUPT_REQUEST(8'b01000000);
        TASK_READ_DATA(1'b0);//IRR will be sent 

        TASK_INTERRUPT_REQUEST(8'b10000000);
        TASK_READ_DATA(1'b0);//IRR will be sent 

        
        TASK_WRITE_DATA(1'b0, 8'b00001011);

        TASK_READ_DATA(1'b0);//ISR will be sent

        TASK_SEND_NON_SPECIFIC_EOI();
        TASK_SEND_ACK_TO_8086();
        #10;
        TASK_READ_DATA(1'b0);//ISR will be sent

        TASK_SEND_NON_SPECIFIC_EOI();
        TASK_SEND_ACK_TO_8086();
        #10;
        TASK_READ_DATA(1'b0);//ISR will be sent

        TASK_SEND_NON_SPECIFIC_EOI();
        TASK_SEND_ACK_TO_8086();
        #10;
        TASK_READ_DATA(1'b0);//ISR will be sent

        TASK_SEND_NON_SPECIFIC_EOI();
        TASK_SEND_ACK_TO_8086();
        #10;
        TASK_READ_DATA(1'b0);//ISR will be sent

        TASK_SEND_NON_SPECIFIC_EOI();
        TASK_SEND_ACK_TO_8086();
        #10;
        TASK_READ_DATA(1'b0);//ISR will be sent

        TASK_SEND_NON_SPECIFIC_EOI();
        TASK_SEND_ACK_TO_8086();
        #10;
        TASK_READ_DATA(1'b0);//ISR will be sent

        TASK_SEND_NON_SPECIFIC_EOI();
        TASK_SEND_ACK_TO_8086();
        #10;
        TASK_READ_DATA(1'b0);//ISR will be sent

        TASK_SEND_NON_SPECIFIC_EOI();
        TASK_SEND_ACK_TO_8086();
        #10;
        TASK_READ_DATA(1'b0);//ISR will be sent

        TASK_SEND_NON_SPECIFIC_EOI();
        TASK_READ_DATA(1'b0);//ISR will be sent

        
        // OCW1
        TASK_WRITE_DATA(1'b1, 8'b00000000);
        TASK_READ_DATA(1'b1);//IMR will be sent

        // OCW1
        TASK_WRITE_DATA(1'b1, 8'b00000001);
        TASK_READ_DATA(1'b1);//IMR will be sent

        // OCW1
        TASK_WRITE_DATA(1'b1, 8'b00000010);
        TASK_READ_DATA(1'b1);//IMR will be sent

        // OCW1
        TASK_WRITE_DATA(1'b1, 8'b00000100);
        TASK_READ_DATA(1'b1);//IMR will be sent

        // OCW1
        TASK_WRITE_DATA(1'b1, 8'b00001000);
        TASK_READ_DATA(1'b1);//IMR will be sent

        // OCW1
        TASK_WRITE_DATA(1'b1, 8'b00010000);
        TASK_READ_DATA(1'b1);//IMR will be sent

        // OCW1
        TASK_WRITE_DATA(1'b1, 8'b00100000);
        TASK_READ_DATA(1'b1);//IMR will be sent

        // OCW1
        TASK_WRITE_DATA(1'b1, 8'b01000000);
        TASK_READ_DATA(1'b1);//IMR will be sent

        // OCW1
        TASK_WRITE_DATA(1'b1, 8'b10000000);
        TASK_READ_DATA(1'b1);//IMR will be sent

        // OCW1
        //TASK_WRITE_DATA(1'b1, 8'b00000000);

        #10;
    end
    endtask

task TASK_NON_SPECTAL_FULLY_NESTED_TEST();
    begin
        #10;
        // ICW1
        TASK_WRITE_DATA(1'b0, 8'b00011111);
        // ICW2
        TASK_WRITE_DATA(1'b1, 8'b00000000);
        // ICW4
        TASK_WRITE_DATA(1'b1, 8'b00001101);
        // OCW1
        TASK_WRITE_DATA(1'b1, 8'b00000000);
        // OCW3
        TASK_WRITE_DATA(1'b0, 8'b00001000);

        // Interrupt
        TASK_INTERRUPT_REQUEST(8'b00010000);    // 4<------------		|
        TASK_SEND_ACK_TO_8086();//				|
        #10;//							|
        TASK_INTERRUPT_REQUEST(8'b00100000);    // 5		|
        TASK_INTERRUPT_REQUEST(8'b00010000);    // 4		|
        TASK_INTERRUPT_REQUEST(8'b00001000);    // 3		|
        TASK_SEND_ACK_TO_8086();	//			|
        TASK_SEND_SPECIFIC_EOI(3'b011); //                      |
        TASK_SEND_SPECIFIC_EOI(3'b100);//first one--------------
        TASK_SEND_ACK_TO_8086();//for the second one 
        TASK_SEND_SPECIFIC_EOI(3'b100);//for the second one 
        TASK_SEND_ACK_TO_8086();//5
        TASK_SEND_SPECIFIC_EOI(3'b101);//5
        #10;
    end
    endtask

task TASK_AUTO_EOI_TEST();
    begin
        #10;
        // ICW1
        TASK_WRITE_DATA(1'b0, 8'b00011111);
        // ICW2
        TASK_WRITE_DATA(1'b1, 8'b00000000);
        // ICW4
        TASK_WRITE_DATA(1'b1, 8'b00001111);
        // OCW1
        TASK_WRITE_DATA(1'b1, 8'b00000000);
        // OCW3
        TASK_WRITE_DATA(1'b0, 8'b00001000);

        // Interrupt
        TASK_INTERRUPT_REQUEST(8'b11111111);

        // ACK
        TASK_SEND_ACK_TO_8086();
        #10;

        TASK_SEND_ACK_TO_8086();
        #10;

        TASK_SEND_ACK_TO_8086();
        #10;

        TASK_SEND_ACK_TO_8086();
        #10;

        TASK_SEND_ACK_TO_8086();
        #10;

        TASK_SEND_ACK_TO_8086();
        #10;

        TASK_SEND_ACK_TO_8086();
        #10;

        TASK_SEND_ACK_TO_8086();
        #10;
    end
    endtask





 task TASK_INTERRUPT_MASK_TEST();
    begin
        #10;
        // ICW1
        TASK_WRITE_DATA(1'b0, 8'b00010111);
        // ICW2
        TASK_WRITE_DATA(1'b1, 8'b00000000);
        // ICW4
        TASK_WRITE_DATA(1'b1, 8'b00001101);
        // OCW1
        TASK_WRITE_DATA(1'b1, 8'b11111111);//MASK all Interrupts 
        // OCW3
        TASK_WRITE_DATA(1'b0, 8'b00001000);

        // Can't interrupt
        TASK_INTERRUPT_REQUEST(8'b11111111);
        #10;

        // OCW1
        TASK_WRITE_DATA(1'b1, 8'b11111110);
        // Interrupt
        TASK_INTERRUPT_REQUEST(8'b11111111);
        TASK_SEND_ACK_TO_8086();
        TASK_SEND_SPECIFIC_EOI(3'b000);

        // OCW1
        TASK_WRITE_DATA(1'b1, 8'b11111101);
        // Interrupt
        TASK_INTERRUPT_REQUEST(8'b11111111);
        TASK_SEND_ACK_TO_8086();
        TASK_SEND_SPECIFIC_EOI(3'b001);

        // OCW1
        TASK_WRITE_DATA(1'b1, 8'b11111011);
        // Interrupt
        TASK_INTERRUPT_REQUEST(8'b11111111);
        TASK_SEND_ACK_TO_8086();
        TASK_SEND_SPECIFIC_EOI(3'b010);

        // OCW1
        TASK_WRITE_DATA(1'b1, 8'b11110111);
        // Interrupt
        TASK_INTERRUPT_REQUEST(8'b11111111);
        TASK_SEND_ACK_TO_8086();
        TASK_SEND_SPECIFIC_EOI(3'b011);

        // OCW1
        TASK_WRITE_DATA(1'b1, 8'b11101111);
        // Interrupt
        TASK_INTERRUPT_REQUEST(8'b11111111);
        TASK_SEND_ACK_TO_8086();
        TASK_SEND_SPECIFIC_EOI(3'b100);

        // OCW1
        TASK_WRITE_DATA(1'b1, 8'b11011111);
        // Interrupt
        TASK_INTERRUPT_REQUEST(8'b11111111);
        TASK_SEND_ACK_TO_8086();
        TASK_SEND_SPECIFIC_EOI(3'b101);

        // OCW1
        TASK_WRITE_DATA(1'b1, 8'b10111111);
        // Interrupt
        TASK_INTERRUPT_REQUEST(8'b11111111);
        TASK_SEND_ACK_TO_8086();
        TASK_SEND_SPECIFIC_EOI(3'b110);

        // OCW1
        TASK_WRITE_DATA(1'b1, 8'b01111111);
        // Interrupt
        TASK_INTERRUPT_REQUEST(8'b11111111);
        TASK_SEND_ACK_TO_8086();
        TASK_SEND_SPECIFIC_EOI(3'b111);
        #10;
    end
    endtask



task TASK_NON_SPECIFIC_EOI_TEST();
    begin
        #10;
        // ICW1
        TASK_WRITE_DATA(1'b0, 8'b00011111);
        // ICW2
        TASK_WRITE_DATA(1'b1, 8'b00000000);
        // ICW4
        TASK_WRITE_DATA(1'b1, 8'b00001101);
        // OCW1
        TASK_WRITE_DATA(1'b1, 8'b00000000);
        // OCW3
        TASK_WRITE_DATA(1'b0, 8'b00001000);

        // Interrupt
        TASK_INTERRUPT_REQUEST(8'b11111111);

        TASK_SEND_ACK_TO_8086();
        TASK_SEND_NON_SPECIFIC_EOI();

        TASK_SEND_ACK_TO_8086();
        TASK_SEND_NON_SPECIFIC_EOI();

        TASK_SEND_ACK_TO_8086();
        TASK_SEND_NON_SPECIFIC_EOI();

        TASK_SEND_ACK_TO_8086();
        TASK_SEND_NON_SPECIFIC_EOI();

        TASK_SEND_ACK_TO_8086();
        TASK_SEND_NON_SPECIFIC_EOI();

        TASK_SEND_ACK_TO_8086();
        TASK_SEND_NON_SPECIFIC_EOI();

        TASK_SEND_ACK_TO_8086();
        TASK_SEND_NON_SPECIFIC_EOI();

        TASK_SEND_ACK_TO_8086();
        TASK_SEND_NON_SPECIFIC_EOI();
        #10;
    end
    endtask

    //
    // TASK : non specific test
    //

task TASK_ROTATE_TEST();
    begin
        #10;
        // ICW1
        TASK_WRITE_DATA(1'b0, 8'b00011111);
        // ICW2
        TASK_WRITE_DATA(1'b1, 8'b00000000);
        // ICW4
        TASK_WRITE_DATA(1'b1, 8'b00001101);
        // OCW1
        TASK_WRITE_DATA(1'b1, 8'b00000000);
        // OCW3
        TASK_WRITE_DATA(1'b0, 8'b00001000);

        
        // OCW2*************
        TASK_WRITE_DATA(1'b0, 8'b11000100);//SET PRIORITY COMMAND ///{L2,L1,L0}=4

        // Interrupt
        TASK_INTERRUPT_REQUEST(8'b11111111);

        TASK_SEND_ACK_TO_8086();
        TASK_SEND_NON_SPECIFIC_EOI();

        TASK_SEND_ACK_TO_8086();
        TASK_SEND_NON_SPECIFIC_EOI();

        TASK_SEND_ACK_TO_8086();
        TASK_SEND_NON_SPECIFIC_EOI();

        TASK_SEND_ACK_TO_8086();
        TASK_SEND_NON_SPECIFIC_EOI();

        TASK_SEND_ACK_TO_8086();
        TASK_SEND_NON_SPECIFIC_EOI();

        TASK_SEND_ACK_TO_8086();
        TASK_SEND_NON_SPECIFIC_EOI();

        TASK_SEND_ACK_TO_8086();
        TASK_SEND_NON_SPECIFIC_EOI();

        TASK_SEND_ACK_TO_8086();
        TASK_SEND_NON_SPECIFIC_EOI();

        
        // OCW2*************************
        TASK_WRITE_DATA(1'b0, 8'b11000111);//SET PRIORITY COMMAND ///{L2,L1,L0}=7

        // Interrupt
        TASK_INTERRUPT_REQUEST(8'b00001000);
        TASK_SEND_ACK_TO_8086();
        TASK_WRITE_DATA(1'b0, 8'b10100000);
        TASK_INTERRUPT_REQUEST(8'b11111111);

        TASK_SEND_ACK_TO_8086();
        TASK_SEND_NON_SPECIFIC_EOI();

        TASK_SEND_ACK_TO_8086();
        TASK_SEND_NON_SPECIFIC_EOI();

        TASK_SEND_ACK_TO_8086();
        TASK_SEND_NON_SPECIFIC_EOI();

        TASK_SEND_ACK_TO_8086();
        TASK_SEND_NON_SPECIFIC_EOI();

        TASK_SEND_ACK_TO_8086();
        TASK_SEND_NON_SPECIFIC_EOI();

        TASK_SEND_ACK_TO_8086();
        TASK_SEND_NON_SPECIFIC_EOI();

        TASK_SEND_ACK_TO_8086();
        TASK_SEND_NON_SPECIFIC_EOI();

        TASK_SEND_ACK_TO_8086();
        TASK_SEND_NON_SPECIFIC_EOI();

	/*    
        // OCW3
        TASK_WRITE_DATA(1'b0, 8'b11000111);//SET PRIORITY COMMAND ///{L2,L1,L0}=7
        TASK_WRITE_DATA(1'b0, 8'b10000000);

        // Interrupt
        TASK_INTERRUPT_REQUEST(8'b00000100);
        TASK_SEND_ACK_TO_8086();
        TASK_SEND_NON_SPECIFIC_EOI();

        TASK_WRITE_DATA(1'b0, 8'b00000000);

        TASK_INTERRUPT_REQUEST(8'b11111111);

        TASK_SEND_ACK_TO_8086();
        TASK_SEND_NON_SPECIFIC_EOI();

        TASK_SEND_ACK_TO_8086();
        TASK_SEND_NON_SPECIFIC_EOI();

        TASK_SEND_ACK_TO_8086();
        TASK_SEND_NON_SPECIFIC_EOI();

        TASK_SEND_ACK_TO_8086();
        TASK_SEND_NON_SPECIFIC_EOI();

        TASK_SEND_ACK_TO_8086();
        TASK_SEND_NON_SPECIFIC_EOI();

        TASK_SEND_ACK_TO_8086();
        TASK_SEND_NON_SPECIFIC_EOI();

        TASK_SEND_ACK_TO_8086();
        TASK_SEND_NON_SPECIFIC_EOI();

        TASK_SEND_ACK_TO_8086();
        TASK_SEND_NON_SPECIFIC_EOI();

        // OCW3
        TASK_WRITE_DATA(1'b0, 8'b11000111);  */
        #10;
    end
    endtask
initial begin
        TASK_INIT();
 	$display("******************************** ");
        $display("***** TEST 8086 INTERRUPT  ***** ");
        $display("******************************** ");
        TASK_8086_NORMAL_INTERRUPT_TEST();
	$display("******************************** ");
        $display("***** TEST INTERRUPT MASK ***** ") ;
        $display("******************************** ");
        TASK_INTERRUPT_MASK_TEST();
	$display("******************************** ");
        $display("***** TEST AUTO EOI        ***** ");
        $display("******************************** ");
        TASK_AUTO_EOI_TEST();
	$display("***************************************** ");
        $display("***** TEST NON SPECIAL FULLY NESTED ***** ");
        $display("***************************************** ");
        TASK_NON_SPECTAL_FULLY_NESTED_TEST();
	$display("******************************** ");
        $display("***** TEST NON SPECIFIC EOI*****");
        $display("******************************** ");
        TASK_NON_SPECIFIC_EOI_TEST();
	$display("******************************** ");
        $display("***** TEST ROTATION       ***** ");
        $display("******************************** ");
        TASK_ROTATE_TEST();
	$display("******************************** ");
        $display("***** READING STATUS       *****" );
        $display("******************************** ");
        TASK_READING_STATUS_TEST();
end

 always @* $monitor("At time %t: CS_n = %b, RD_n = %b, WR_n = %b, A0 = %b, CAS = %b , SP_EN_n = %b , D_IN = %b ,D_OUT = %b ,INT = %b,IR = %b",
                    $time, chip_select_wire , read_enable_wire , write_enable_wire  , A0_wire ,  CAS_wire , SP_EN_wire , data_bus_wire_in ,data_bus_wire_out ,INT_wire,IRR_wire);
endmodule



