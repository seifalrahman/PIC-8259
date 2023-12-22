module Priority_Resolver(
    
    // Inputs from control logic
    input   wire   [2:0]   priority_rotate,
    input   wire   [7:0]   interrupt_mask,
    input   wire   [7:0]   interrupt_special_mask,
    //input   wire         special_fully_nest_config,
    //input   wire   [7:0]   highest_level_in_service,

    // Inputs from interrupt request 
    input   wire   [7:0]   interrupt_request_register,
    
    // Inputs from interrupt service
    input   wire   [7:0]   in_service_register,

    // Outputs
    output  reg    [7:0]   interrupt

);
    
    // rotation only changes the priority ... after picking the correct interrupt and identify its device, 
    // we should rotate back in the opposite direction as each device has its ISR at a certain unchanged location marked by its initial location
    // rotate right -> rotate left
    
    reg   [7:0]   masked_interrupt_req,masked_in_service;
        
    always @* begin
      //check masking
      masked_interrupt_req = interrupt_request_register & ~interrupt_mask;
      //check masking in case of special masking
      masked_in_service    = in_service_register & ~interrupt_special_mask;
    end
    
  
    // Resolve priority 
    reg    [7:0]    priority_mask , rotated_interrupt;
    wire   [7:0]   rotated_in_service , rotated_request;
    //wire   [7:0]   rotated_highest_level_in_service
    
    
    // rotate register (after checking masking)
    rotate_right rotate_R1(
      .source(masked_interrupt_request),
      .rotate(priority_rotate),
      .rotated_R_output(rotated_request)
    );
    
    
    // we get highest level from In service , to be cleared in case of non specific EOI (L0~L2)
    //rotated_highest_level_in_service = rotate_right(highest_level_in_service, priority_rotate); 
    rotate_right rotate_R2(
      .source(masked_in_service),
      .rotate(priority_rotate),
      .rotated_R_output(rotated_in_service)
    );
    

    //disable interrupts of lower priority while allowing all interrupts of higher priority    
    always@(*) begin
        if      (rotated_in_service[0] == 1'b1) priority_mask = 8'b00000000;
        else if (rotated_in_service[1] == 1'b1) priority_mask = 8'b00000001;
        else if (rotated_in_service[2] == 1'b1) priority_mask = 8'b00000011;
        else if (rotated_in_service[3] == 1'b1) priority_mask = 8'b00000111;
        else if (rotated_in_service[4] == 1'b1) priority_mask = 8'b00001111;
        else if (rotated_in_service[5] == 1'b1) priority_mask = 8'b00011111;
        else if (rotated_in_service[6] == 1'b1) priority_mask = 8'b00111111;
        else if (rotated_in_service[7] == 1'b1) priority_mask = 8'b01111111;
        else                                    priority_mask = 8'b11111111;
    end
    
    wire resolved_priority;
    
    
    resolve_priority res_pri(
      .source(rotated_request),
      .resolved_priority(resolved_priority)
    );
wire [7:0] interrupt_wire;
assign interrupt_wire = interrupt;  
    
    // rotate the result back into its rightful position as each device 
    // has its ISR at a certain unchanged location marked by its initial location
    rotate_left rotate_L1(
      .source(rotated_interrupt),
      .rotate(priority_rotate),
      .rotated_L_output(interrupt_wire)
    );    
    // interrupt goes to the control unit which enables the INT pin as a result
    
    always @* begin
       // resolve priority then and with mask(which allows only higher priorities in case of currently executing an interrupt)
       rotated_interrupt = resolved_priority & priority_mask;
    end

endmodule
