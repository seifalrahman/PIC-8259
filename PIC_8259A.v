module PIC_8259A (
		  input wire [7:0]  	D 	,
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
wire [7:0] InternalData;

//Cascade-->DataBuffer
wire Flag_From_Cascade;

DataBuffer Buff (
    .D(D)					,
    .InternalD(InternalData)			,
    .R(RD_n)					,
    .W(WR_n)					,
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
	.inputData(InternalData)		,
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
	.codeAddress(InternalData)			,
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

//ISR-->(Priority & Control)
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
	.DataBufferOutput(InternalData)			,
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
