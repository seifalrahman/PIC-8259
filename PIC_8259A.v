module PIC_8259A (
          inout wire [7:0]      D     ,
          inout wire [2:0]    CAS    ,
          inout wire         SP_EN_n    ,
          input wire        RD_n     , 
          input wire        WR_n     ,
          input wire        A0     ,
          input wire        CS_n    ,
          input wire [7:0]    IR     ,
          input wire        INTA_n    ,
          output wire        INT    
        );
//internal_Bus
wire [7:0] InternalData;

//Cascade-->DataBuffer
wire Flag_From_Cascade;

DataBuffer DataBusBuffer(
    .Data(D)                ,
    .InternalD(InternalData)        ,
    .R(RD_n)                ,
    .W(WR_n)                ,
    .Flag_From_Cascade(Flag_From_Cascade)
    );


//ReadWrite-->Control
wire [7:0] W_Data_2Control;//ICWs and OCWs
wire [2:0] W_Flag_2Control;//flags from 0 to 6
wire [2:0] R_Flag_2Control;//flag to identifi read register
    
Read_WriteLogic ReadWriteLogic(
    .RD(RD_n)                    ,
    .WR(WR_n)                    ,
    .A0(A0)                        ,
    .CS(CS_n)                    ,
    .inputRegister(InternalData)            ,
    .control_output_Register(W_Data_2Control)    ,
    .Flag(W_Flag_2Control)                ,
    .read2control(R_Flag_2Control)                    
    );

//Control-->Cascade
wire [7:0] ICW3Cascade    ;
wire [7:0] IRRCascade    ; //it has only one bit set from ISR
wire [7:0] ICW2Cascade    ;     
wire SNGL;//to check singlr or cascade mode
 
Cascademodule Cascade_Buffer_Comparator(
    .CAS(CAS)                    ,
    .SP_EN(SP_EN_n)                    ,
    .ICW3(ICW3Cascade)                ,
    .IRR(IRRCascade)                ,
    .ICW2(ICW2Cascade)                ,    
    .SNGL(SNGL)                    ,
    .INTA(INTA_n)                    ,
    .codeAddress(InternalData)            ,
    .flagCodeAddress(Flag_From_Cascade)
    );







endmodule