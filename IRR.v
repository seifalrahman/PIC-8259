module Interrupt_Request(
    //1 is for level , 0 is for edge
    input wire edge_level_config,
    
    input wire freeze,
    input wire [7:0] clear_interrupt_req,

    // External inputs
    input wire [7:0] interrupt_req_pin,

    // Outputs
    output reg [7:0] interrupt_req_register
);

    genvar ir_bit_no;
    
    generate for (ir_bit_no = 0; ir_bit_no <= 7; ir_bit_no = ir_bit_no + 1) begin: Request_Latch
      
      if(!edge_level_config) begin
        always @(posedge interrupt_req_pin[ir_bit_no],clear_interrupt_req[ir_bit_no])  begin
        
            if(clear_interrupt_req[ir_bit_no])  
                interrupt_req_register[ir_bit_no] <= 1'b0;
            else if(freeze) 
                interrupt_req_register[ir_bit_no]=interrupt_req_register[ir_bit_no];
            else 
                interrupt_req_register[ir_bit_no] <= 1'b1;
             
        end
      end
    endgenerate

endmodule
