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

