module PIC_8259_TestBench (
 
    				input   wire            chip_select,
    				input   wire            read_enable,
  				input   wire            write_enable,
   				input   wire            A0,
    				inout   wire   [7:0]    data_bus_in,
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
    CAS           = 1'b1;
    read_enable_n           = 1'b1;
    write_enable_n          = 1'b1;
    address                 = 1'b0;
    data_bus_in             = 8'b00000000;
    cascade_in              = 3'b000;
    slave_program_n         = 1'b0;
    interrupt_acknowledge_n = 1'b1;
    interrupt_request       = 8'b00000000;
    
end
endtask


// Task : Write data
task TASK_WRITE_DATA;
  input [7:0] addr;
  input [7:0] data;
begin
    #10; // Assuming no delay for this step
    CAS   = 1'b0;
    write_enable_n  = 1'b0;
    address         = addr;
    data_bus_in     = data;
    #10; // Assuming a delay of 1 time unit
    CAS   = 1'b1;
    write_enable_n  = 1'b1;
    address         = 1'b0;
    data_bus_in     = 8'b00000000;
    #10; // Assuming a delay of 1 time unit
end
endtask

















// Task : Read data
task TASK_READ_DATA;
  input [7:0] addr;
begin
    #10; // Assuming no delay for this step
    chip_select_n   = 1'b0;
    read_enable_n   = 1'b0;
    address         = addr;
    #10; // Assuming a delay of 1 time unit
    chip_select_n   = 1'b1;
    read_enable_n   = 1'b1;
    #10; // Assuming a delay of 1 time unit
end
endtask

// Task : Interrupt request
task TASK_INTERRUPT_REQUEST;
  input [7:0] request;
begin
    #10; // Assuming no delay for this step
    interrupt_request = request;
    #10; // Assuming a delay of 1 time unit
    interrupt_request = 8'b00000000;
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
    interrupt_acknowledge_n = 1'b1;
    #1;
    interrupt_acknowledge_n = 1'b0;
    #1;
    interrupt_acknowledge_n = 1'b1;
    #1;
    interrupt_acknowledge_n = 1'b0;
    #1;
    interrupt_acknowledge_n = 1'b1;
end
endtask;

task TASK_SEND_ACK_TO_8086_SLAVE;
  input [2:0] slave_id;
begin
    interrupt_acknowledge_n = 1'b1;
    cascade_in = 3'b000;
    #1;
    interrupt_acknowledge_n = 1'b0;
    #0.5;
    cascade_in = slave_id;
    #0.5;
    interrupt_acknowledge_n = 1'b1;
    #1;
    interrupt_acknowledge_n = 1'b0;
    #1;
    interrupt_acknowledge_n = 1'b1;
    cascade_in = 3'b000;
end
endtask;

