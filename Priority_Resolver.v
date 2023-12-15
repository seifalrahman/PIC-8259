module Priority_Resolver(
    
    // FIX MODULE INSTANTIATION ----------------------------------------------------------------------------
    
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
    
    // rotation only changes the priority ... after picking the right interrupt and identify its device, 
    // we should rotate back in the opposite direction as each device has its ISR at a certain unchanged location marked by its initial location
    // rotate right -> rotate left
    
    reg   [7:0]   masked_interrupt_request,masked_in_service;
    
    always @* begin
      //check masking
      masked_interrupt_req = interrupt_request_register & ~interrupt_mask;
      //check masking in case of special masking
      masked_in_service    = in_service_register & ~interrupt_special_mask;
    end
    
  
    // Resolve priority 
    reg    [7:0]   rotated_in_service , priority_mask;
    wire   [7:0]   rotated_request , rotated_interrupt;
    //wire   [7:0]   rotated_highest_level_in_service
    
    always @* begin
      // ADD AN ALWAYS
      // rotate register (after checking masking)
      rotated_request = rotate_right(masked_interrupt_request, priority_rotate);
      
      // we get highest level from In service , to be cleared in case of non specific EOI (L0~L2)
      //rotated_highest_level_in_service = rotate_right(highest_level_in_service, priority_rotate);
      
      rotated_in_service = rotate_right(masked_in_service, priority_rotate);
       
    end

    //disable interrupts of lower priority while allowing all interrupts of higher priority
    always begin
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
    
    
    always @* begin
      // resolve priority then add with mask(which allows only higher priorities in case of currently executing an interrupt)
      rotated_interrupt = resolv_priority(rotated_request) & priority_mask;
      
      // rotate the result back into its rightful position as each device 
      // has its ISR at a certain unchanged location marked by its initial location
      interrupt = rotate_left(rotated_interrupt, priority_rotate);
    end
    
    // interrupt goes to the control unit which enables the INT pin as a result
  
endmodule



// rotate_right_module rotate_inst (.source(interrupt_request_register),.rotate(priority_rotate),.rotated_output(masked_interrupt_request));



// instantiate from it
module rotate_right_module (
    input [7:0] source,
    input [2:0] rotate,
    output reg [7:0] rotated_output
);

    always @*
        case (rotate)
            3'b000:  rotated_output = { source[0],   source[7:1] };
            3'b001:  rotated_output = { source[1:0], source[7:2] };
            3'b010:  rotated_output = { source[2:0], source[7:3] };
            3'b011:  rotated_output = { source[3:0], source[7:4] };
            3'b100:  rotated_output = { source[4:0], source[7:5] };
            3'b101:  rotated_output = { source[5:0], source[7:6] };
            3'b110:  rotated_output = { source[6:0], source[7]   };
            3'b111:  rotated_output = source;
            default: rotated_output = source;
        endcase
endmodule
