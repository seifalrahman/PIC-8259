module Interrupt_Request(

    // Inputs from control logic
    
    //1 is for level , 0 is for edge
    input wire edge_level_config,
    
    input wire freeze,
    input wire [7:0] clear_interrupt_req,

    // External inputs
    input wire [7:0] interrupt_req_pin,

    // Outputs
    output reg [7:0] interrupt_req_register = 8'b00000000
);
    
    genvar ir_bit_no;
        
    generate for (ir_bit_no = 0; ir_bit_no <= 7; ir_bit_no = ir_bit_no + 1) begin: generate_8bit_IRR_processing
        
        always @(*)  begin
          if(!edge_level_config) begin
              if(clear_interrupt_req[ir_bit_no])  
                  interrupt_req_register[ir_bit_no] <= 1'b0;
              else if(freeze) 
                  interrupt_req_register[ir_bit_no]=interrupt_req_register[ir_bit_no];
              else if(interrupt_req_pin[ir_bit_no]==1)
                  interrupt_req_register[ir_bit_no] <= 1'b1;
              else 
                  interrupt_req_register[ir_bit_no]=interrupt_req_register[ir_bit_no];
          end
          
          else begin
         if(clear_interrupt_req[ir_bit_no])
            interrupt_req_register[ir_bit_no] <= 1'b0;
         else
                      interrupt_req_register[ir_bit_no] <= interrupt_req_pin[ir_bit_no];
          end   
        end
         
    end
    endgenerate

endmodule
