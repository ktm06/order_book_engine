`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Case Western Reserve University
// Engineer: Matt McConnell
// 
// Create Date:    20:38:00 09/17/2017 
// Project Name:   EECS301 Digital Design
// Design Name:    Lab #5 Project
// Module Name:    Serial_UART_Keypress_Reporter
// Target Devices: Altera Cyclone V
// Tool versions:  Quartus v17.0
// Description:    Serial UART Keypress Reporter
//                 
// Dependencies:   
//
//////////////////////////////////////////////////////////////////////////////////

module Serial_UART_Keypress_Reporter
#(
	parameter CLK_RATE_HZ = 50000000, // Hz
	parameter BAUD_RATE = 115200,     // Baud (bits/s)
	parameter DATA_BITS = 8,
	parameter STOP_BITS_TX = 1
)
(
	// UART Bus Signals
	output   UART_TX,

	// UART Transmitter Signals
	input                      TX_SEND,
	input      [DATA_BITS-1:0] TX_DATA,
	output                     TX_DONE,

	// System Signals
	input CLK,
	input RESET
);


	//
	// Baud Rate Generator
	//
	//  Transmiter outputs at 1x baud rate
	//  Receiver oversamples at 16x baud rate
	//
	wire  tx_baud_tick;
	
	Serial_UART_Baud_Generator
	#(
		.CLK_RATE_HZ( CLK_RATE_HZ ),
		.BAUD_RATE( BAUD_RATE )
	)
	baud_generator
	(
		// Baud Clock Signals
		.BAUD_RATE_TICK( tx_baud_tick ),
		.BAUD_SAMPLE_TICK(  ),
		
		// System Signals
		.CLK( CLK ),
		.RESET( RESET )
	);


	//
	// UART Transmitter
	//
	Serial_UART_Transmitter
	#(
		.DATA_BITS( DATA_BITS ),
		.STOP_BITS( STOP_BITS_TX )
	)
	uart_tx
	(
		// UART Transmitter Signals
		.TX_SEND( TX_SEND ),
		.TX_DATA( TX_DATA ),
		.TX_DONE( TX_DONE ),

		// UART Bus Signals
		.UART_TX( UART_TX ),
		
		// Baud Clock Signals
		.BAUD_TICK( tx_baud_tick ),
		
		// System Signals
		.CLK( CLK ),
		.RESET( RESET )
	);	

endmodule