module In_Service(
  
  // Inputs
    input      [2:0]   priority_rotate,
    input      [7:0]   interrupt_special_mask,
    input      [7:0]   interrupt,
    input              latch_in_service,
    input      [7:0]   end_of_interrupt,  

    // Outputs
    output  reg     [7:0]   in_service_register,
    output  reg     [7:0]   highest_level_in_service
  
  );
  
    wire    [7:0]   next_highest_level_in_service_wire1;
    
  //
  // In service register
  //                           
  always @(*) begin
            in_service_register = (in_service_register & ~end_of_interrupt) 
                                     | (latch_in_service == 1'b1 ? interrupt : 8'b00000000);
  end
  
  rotate_right rotate_R1(
      .source(next_highest_level_in_service),
      .rotate(priority_rotate),
      .rotated_R_output(next_highest_level_in_service)
  );
  
  rotate_left rotate_L1(
      .source(next_highest_level_in_service),
      .rotate(priority_rotate),
      .rotated_L_output(next_highest_level_in_service)
  );  


assign next_highest_level_in_service_wire1 = in_service_register & ~interrupt_special_mask;

wire [7:0] next_highest_level_in_service_wire2;
  resolve_priority RP(
    .source(next_highest_level_in_service_wire1),
    .resolved_priority(next_highest_level_in_service_wire2)
  );

  always @(*) begin
          highest_level_in_service <= next_highest_level_in_service_wire2;
  end

endmodule
