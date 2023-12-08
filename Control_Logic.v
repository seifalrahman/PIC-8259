module Control_Logic(

  //  REMOVE ALL RESETS -------------------------------------------------------------------------------
  // REMEMBER THE FUNCTIONS ------------------------------------------------------------------------------
    // Internal bus
    input   logic   [7:0]   internal_data_bus,
    input   logic           write_initial_command_word_1,
    input   logic           write_initial_command_word_2_4,
    input   logic           write_operation_control_word_1,
    input   logic           write_operation_control_word_2,
    input   logic           write_operation_control_word_3,
  
    // Interrupt control signals
    output  logic   [7:0]   interrupt_mask,
    output  logic   [7:0]   interrupt_special_mask,
    output  logic   [7:0]   end_of_interrupt,
    output  logic   [2:0]   priority_rotate,
    output  logic           freeze,
    output  logic           latch_in_service,
    output  logic   [7:0]   clear_interrupt_request
    
);
  
  
  
  
    // Operation control word 1 
    // IMR
    always @(*) begin
        
        //in case of reset disable all interrupts (to re-init)
        // RECALL THERE IS NO RESET (MUST INIT interrupt_mask to 111111111111)
        if (reset)
            interrupt_mask <= 8'b11111111;
            
        // in case of still writing on ICW1 disable all interrupts (init phase)
        else if (write_initial_command_word_1 == 1'b1)
            interrupt_mask <= 8'b11111111;
        
        // in case of writing on OCW1 and special mask = 0 then put data on data line into IMR
        else if ((write_operation_control_word_1_registers == 1'b1) && (special_mask_mode == 1'b0))
            interrupt_mask <= internal_data_bus;
        
        else
            interrupt_mask <= interrupt_mask;
    end

    // Special mask
    always @(*) begin
        
        // due to functionality of interrupt_special_mask it should initially start with zeros
        // as it's different from interrupt mask (temporarily change enabled/disabled interrupts)
        if (reset)
            interrupt_special_mask <= 8'b00000000;
        
        // in case of still writing on ICW1 set interrupt special mask to initial state
        else if (write_initial_command_word_1 == 1'b1)
            interrupt_special_mask <= 8'b00000000;
        
        // special mask mode is diabled
        else if (special_mask_mode == 1'b0)
            interrupt_special_mask <= 8'b00000000;
       
        // in case of writing on OCW1 while special mask mode is enabled -> put data on data line 
        // into interrupt special mask reg
        else if ((write_operation_control_word_1_registers  == 1'b1) && (special_mask_mode == 1'b1))
            interrupt_special_mask <= internal_data_bus;
        
        else
            interrupt_special_mask <= interrupt_special_mask;
    end
    
    
    
  // Auto rotate mode
    always @(*) begin
        if (reset)
            auto_rotate_mode <= 1'b0;
            
        //  while intiializing deactivate rotate mode (init phase)
        else if (write_initial_command_word_1 == 1'b1)
            auto_rotate_mode <= 1'b0;
        
        // in case of OCW2 (where it's initialized) if R bit is set -> rotate mode
        else if (write_operation_control_word_2 == 1'b1) begin
            casez (internal_data_bus[7:5])
                3'b000:  auto_rotate_mode <= 1'b0;  // disable auto rotate mode
                3'b100:  auto_rotate_mode <= 1'b1;  // enable  auto rotate mode
                default: auto_rotate_mode <= auto_rotate_mode;
            endcase
        end
        else
            auto_rotate_mode <= auto_rotate_mode;
    end




    // Rotate (Determine priority rotate values)
    // which is used in Priority Resolver
    
    // 0 indicates 1 rotation
    // 2 indicated 3 rotations
    // 6 indicates 7 rotations
    // 7 indicates no rotation
    always @(*) begin
        if (reset)
            priority_rotate <= 3'b111;
            
        //  while intiializing set priority to 7 (no rotation) (init phase)
        else if (write_initial_command_word_1 == 1'b1)
            priority_rotate <= 3'b111;
        
        // in case of auto rotate mode enabled , and an EOI is received then 
        // rotate priorities (checking R bit + EOI are set or not)
        else if ((auto_rotate_mode == 1'b1) && (end_of_acknowledge_sequence == 1'b1))
            // in Case of just finished IS4 -> acknowledge interrupt = 4 (now turned into binary)
            // then rotate by 4 steps (4 indicates 5)
            priority_rotate <= bit2num(acknowledge_interrupt);
        
        // in case of currently writing OCW2:
        else if (write_operation_control_word_2 == 1'b1) begin
            //check R , SL , EOI bits
            casez (internal_data_bus[7:5])
                // 101 -> rotate on non specific EOI
                // sends EOI to show that interrupt is finished
                // now need to have the info about the interrupt that just finished (highest_level_in_service)
                // so that we clear the ISR correctly and rotate for the next interrupt 
                3'b101:  priority_rotate <= bit2num(highest_level_in_service);  // non specific EOI -> highest_level_in_service
                
                // Take priority from L2~L0 ( in case of specific rotation )
                3'b11x:  priority_rotate <= internal_data_bus[2:0];
                default: priority_rotate <= priority_rotate;
            endcase
        end
        else
            priority_rotate <= priority_rotate;
    end