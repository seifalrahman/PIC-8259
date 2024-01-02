`timescale 1ns / 1ps

module Cascademodule_tb;

    // Inputs
    reg SP_EN;
    reg [7:0] ICW3;
    reg [7:0] IRR;
    reg [7:0] ICW2;
    reg SNGL;
    reg INTA;

    // Bidirectional
    wire [2:0] CAS;

    // Outputs
    wire [7:0] CODEADDRESS;

    // Instantiate the Unit Under Test (UUT)
    Cascademodule uut (
        .CAS(CAS),
        .SP_EN(SP_EN),
        .ICW3(ICW3),
        .IRR(IRR),
        .ICW2(ICW2),
        .SNGL(SNGL),
        .INTA(INTA),
        .CODEADDRESS(CODEADDRESS)
    );

    // Testbench variables
    reg [2:0] CAS_line;

    // Assign bidirectional line
    assign CAS = CAS_line;

    initial begin
        // Initialize Inputs
        SP_EN = 0;
        ICW3 = 0;
        IRR = 0;
        ICW2 = 0;
        SNGL = 0;
        INTA = 0;
        CAS_line = 3'bzzz;

        // Wait for global reset
        #100;

        // Test Master configuration
        SP_EN = 1; // Set as Master
        SNGL = 0; // Cascade mode
        ICW3 = 8'b00000101; // Slave configuration
        ICW2 = 8'b01000000; // Interrupt vector
        IRR = 8'b00000001; // Request from IR0

        // Simulate INTA sequence
        #10 INTA = 1;
        #10 INTA = 0;
        #10 INTA = 1;
        #10 INTA = 0;

        // Test Slave configuration
        SP_EN = 0; // Set as Slave
        SNGL = 0; // Cascade mode
        ICW3 = 8'b00000000; // Not used in Slave mode
        ICW2 = 8'b01000000; // Interrupt vector
        IRR = 8'b00000010; // Request from IR1

        // Simulate INTA sequence
        #10 INTA = 1;
        #10 INTA = 0;
        #10 INTA = 1;
        #10 INTA = 0;

	// Test Single Mode Operation
	SP_EN = 0;
	SNGL = 1; // Single mode
	ICW3 = 8'bxxxxxx; // Not relevant in single mode
	ICW2 = 8'b01000000; // Interrupt vector
	IRR = 8'b00000100; // Request from IR2

	// Simulate INTA sequence
	#10 INTA = 1;
	#10 INTA = 0;
	#10 INTA = 1;
	#10 INTA = 0;

	// Test with no interrupt requests pending
	SP_EN = 1; // Master
	SNGL = 0; // Cascade mode
	ICW3 = 8'b00000101; // Slave configuration
	ICW2 = 8'b01000000; // Interrupt vector
	IRR = 8'b00000000; // No requests

	// Simulate INTA sequence
	#10 INTA = 1;
	#10 INTA = 0;
	#10 INTA = 1;
	#10 INTA = 0;

        // Finish simulation
        #100;
        $finish;
    end

    // Monitor changes
    initial begin
	    $monitor("Time = %d, SP_EN = %b, SNGL = %b, ICW3 = %b, IRR = %b, ICW2 = %b, INTA = %b, CAS = %b, CODEADDRESS = %b",
                 $time, SP_EN, SNGL, ICW3, IRR, ICW2, INTA, CAS, CODEADDRESS);
    end

endmodule
