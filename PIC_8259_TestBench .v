module PIC_8259_TestBench (
 
    				input   wire            chip_select,
    				input   wire            read_enable,
  				input   wire            write_enable,
   				input   wire            A0,
    				inout   wire   [7:0]    data_bus,
    				inout   wire   [2:0]   	  CAS,
    				inout                     SP_EN,
    				input   wire           	  INTA,
    				output  wire           	  INT,
				input   wire   [7:0]      IRR
			   )

PIC_8259A pic (
    .chip_select(chip_select),
    .read_enable(reset),
    .write_enable(write_enable),
    .A0(A0),
    .CAS(CAS),
    .SP_EN(SP_EN),
    .data_bus_in( data_bus_in),
    .INTA(INTA),
    .INT(INT),
    .IRR(IRR)
	
  );


task TASK_INIT;
begin
    #10 ;
    CAS                     = 1'b1;
    read_enable             = 1'b1;
    write_enable            = 1'b1;
    A0                      = 1'b0;
    data_bus                = 8'b00000000;
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
    CAS   = 1'b0;
    write_enable  = 1'b0;
    A0         = addr;
    data_bus     = data;
    #10; // Assuming a delay of 1 time unit
    CAS   = 1'b1;
    write_enable  = 1'b1;
    A0         = 1'b0;
    data_bus     = 8'b00000000;
    #10; // Assuming a delay of 1 time unit
end
endtask


















// Task : Read data
task TASK_READ_DATA;
  input [7:0] addr;
begin
    #10; // Assuming no delay for this step
    chip_select   = 1'b0;
    read_enable   = 1'b0;
    address         = A0;
    #10; // Assuming a delay of 1 time unit
    chip_select   = 1'b1;
    read_enable   = 1'b1;
    #10; // Assuming a delay of 1 time unit
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
    #1;
    INTA = 1'b0;
    #1;
    INTA = 1'b1;
    #1;
    INTA = 1'b0;
    #1;
    INTA = 1'b1;
end
endtask;

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


task TASK_8086_NORMAL_INTERRUPT_TEST();
    begin
        #10;
 
        // ICW1
        TASK_WRITE_DATA(1'b0, 8'b00011111);//EDGE_TRIGGERED---SINGLE----ICW4->allowed
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
    endtask;

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
    endtask;

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
        TASK_WRITE_DATA(1'b1, 8'b00000000);

        #10;
    end
    endtask;
