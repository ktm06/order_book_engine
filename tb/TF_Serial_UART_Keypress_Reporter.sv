`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Case Western Reserve University
// Engineer: Matt McConnell
// 
// Create Date:    20:38:00 09/17/2017 
// Project Name:   EECS301 Digital Design
// Design Name:    Lab #5 Project
// Module Name:    TF_Serial_UART_Keypress_Reporter
// Target Devices: Altera Cyclone V
// Tool versions:  Quartus v17.0
// Description:    Serial UART Keypress Reporter Test Bench
//                 
// Dependencies:   
//
//////////////////////////////////////////////////////////////////////////////////

module TF_Serial_UART_Keypress_Reporter();


	//
	// System Clock Emulation
	//
	localparam CLK_RATE_HZ = 50000000; // 50 MHz
	localparam CLK_HALF_PER = ((1.0 / CLK_RATE_HZ) * 1000000000.0) / 2.0; // ns
	
	reg        CLK;
	
	initial
	begin
		CLK = 1'b0;
		forever #(CLK_HALF_PER) CLK = ~CLK;
	end

	
	//
	// System Reset Emulation
	//
	reg RESET;
	
	initial
	begin
		RESET = 1'b1;
		#500;
		@(posedge CLK) RESET = 1'b0;
	end
	

	//
	// Unit Under Test: Serial_UART_Keypress_Reporter
	//
	reg        TX_SEND;
	reg  [7:0] TX_DATA;
	wire       TX_DONE;
	wire       UART_TX;
	
	Serial_UART_Keypress_Reporter
	#(
		.CLK_RATE_HZ( CLK_RATE_HZ ),
		.BAUD_RATE( 115200 ), // Baud (bits/s)
		.DATA_BITS( 8 ),
		.STOP_BITS_TX( 1 )
	)
	uut
	(
		// UART Bus Signals
		.UART_TX( UART_TX ),

		// UART Transmitter Signals
		.TX_SEND( TX_SEND ),
		.TX_DATA( TX_DATA ),
		.TX_DONE( TX_DONE ),

		// System Signals
		.CLK( CLK ),
		.RESET( RESET )
	);


	//
	// Test Sequence
	//
	initial
	begin
		W
		// Initialize Signals
		TX_SEND = 1'b0;
		TX_DATA = 8'h00;
		
		// Wait for Reset release
		wait (~RESET);

		// Wait 500 ns before starting test
		#500;
		
		// Send Data (aligned to the rising clock edge)
		@(posedge CLK);
		TX_DATA = 8'hA5;
		TX_SEND = 1'b1;
		
		@(posedge CLK);
		TX_SEND = 1'b0;
		
		
		// Look at waveform to verify result
		
	end
	
endmodule