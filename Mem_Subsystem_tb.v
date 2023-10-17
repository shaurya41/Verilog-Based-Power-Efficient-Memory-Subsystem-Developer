`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 17.10.2023 17:19:50
// Design Name: 
// Module Name: Mem_Subsystem_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module Mem_Subsystem_tb;

    // Parameters
    reg [31:0] tb_input_address;
    reg tb_LOAD;
    reg tb_STORE;
    reg tb_CLK;
    wire [31:0] tb_data;

    // Instantiate the Mem_Subsystem
    Mem_Subsystem uut (
        .input_address(tb_input_address),
        .LOAD(tb_LOAD),
        .STORE(tb_STORE),
        .data(tb_data),
        .CLK(tb_CLK)
    );

    initial begin
        // Testbench Initialization
        tb_LOAD = 0;
        tb_STORE = 0;
        tb_CLK = 0;

        // Wait for few clock cycles
        #100;

        // Test Load Operation
        tb_input_address = 32'h9c263203;  // Sample address
        tb_LOAD = 1;
        #100; // Simulate 10 clock cycles
        
        // Observe the data output
        $display("Data for address %h: %h", tb_input_address, tb_data);

        tb_LOAD = 0;
        #100;

//        // Test another Load Operation
//        tb_input_address = 32'h0000_0010;  // Another sample address
//        tb_LOAD = 1;
//        #10;
        
//        // Observe the data output
//        $display("Data for address %h: %h", tb_input_address, tb_data);

//        tb_LOAD = 0;
//        #10;

//        // Add more test scenarios as needed

        $stop; // Stop the simulation
    end

    // Clock Generation
    always begin
        #5 tb_CLK = ~tb_CLK;
    end

endmodule