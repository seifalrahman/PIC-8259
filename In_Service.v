module In_Service(
  
  // Inputs
    input      [2:0]   priority_rotate,
    input      [7:0]   interrupt_special_mask,
    input      [7:0]   interrupt,
    input              latch_in_service,
    input      [7:0]   end_of_interrupt ,  

    // Outputs
    output  reg     [7:0]   in_service_register = 8'b00000000,
    output  reg     [7:0]   highest_level_in_service
  
  );
  
    reg    [7:0]   next_highest_level_in_service;
    
  //
  // In service register
  //                           
  always @(latch_in_service or end_of_interrupt) begin
            in_service_register = (in_service_register & ~end_of_interrupt) 
                                     | (latch_in_service == 1'b1 ? interrupt : 8'b00000000);
  end
  
  wire [7:0] final_next_highest_level_in_service;
  wire [7:0] rotated_next_highest_level_in_service, resolved_next_highest_level_in_service;
  
  wire [7:0] ISR_SpecialMasked;
  
  assign ISR_SpecialMasked = in_service_register & ~interrupt_special_mask;
  
  always @(*) begin
      // (ISR) & (special mask)
      //rotate right     (Implemented by module below)
      //Resolve Priority (Implemented by module below)
      //rotate left      (Implemented by module below)
      next_highest_level_in_service = final_next_highest_level_in_service;  
  end


  rotate_right rotate_R1(
      .source(ISR_SpecialMasked),
      .rotate(priority_rotate),
      .rotated_R_output(rotated_next_highest_level_in_service)
  );
  
  
  resolve_priority RP(
      .source(rotated_next_highest_level_in_service),
      .resolved_priority(resolved_next_highest_level_in_service)
  );
  
  rotate_left rotate_L1(
      .source(resolved_next_highest_level_in_service),
      .rotate(priority_rotate),
      .rotated_L_output(final_next_highest_level_in_service)
  );  

  always @(*) begin
          highest_level_in_service <= next_highest_level_in_service;
  end

endmodule
