`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Case Western Reserve University
// Engineer: Matt McConnell
// 
// Create Date:    12:36:00 02/18/2017 
// Project Name:   EECS301 Digital Design
// Design Name:    Serial UART Project
// Module Name:    Serial_UART_Transceiver
// Target Devices: Altera Cyclone V
// Tool versions:  Quartus v15.0
// Description:    Serial UART Transceiver Module
//                 
// Dependencies:   
//
//////////////////////////////////////////////////////////////////////////////////

module Serial_UART_Transceiver
#(
	parameter CLK_RATE_HZ = 50000000, // Hz
	parameter BAUD_RATE = 115200, // Baud (bits/s)
	parameter DATA_BITS = 8,
	parameter STOP_BITS_TX = 1,
	parameter STOP_BITS_RX = 1
)
(
	// UART Bus Signals
	input    UART_RX,
	output   UART_TX,

	// UART Receiver Signals
	output                     RX_READY,
	output     [DATA_BITS-1:0] RX_DATA,

	// UART Transmitter Signals
	input                      TX_SEND,
	input      [DATA_BITS-1:0] TX_DATA,
	output                     TX_BUSY,
	output                     TX_DONE,

	// System Signals
	input CLK,
	input RESET
);

	//
	// Synchronize UART Receiver Signal to System Clock
	//
	wire uart_rx_sync;

	CDC_Input_Synchronizer
	#(
		.SYNC_REG_LEN( 2 )
	)
	uart_rx_synchronizer
	(
		// Input Signal
		.ASYNC_IN( UART_RX ),
		
		// Output Signal
		.SYNC_OUT( uart_rx_sync ),
		
		// System Signals
		.CLK( CLK )
	);

		
	//
	// Baud Rate Generator
	//
	//  Transmiter outputs at 1x baud rate
	//  Receiver oversamples at 16x baud rate
	//
	
	wire  tx_baud_tick;
	wire  rx_baud_tick;
	
	Serial_UART_Baud_Generator
	#(
		.CLK_RATE_HZ( CLK_RATE_HZ ),
		.BAUD_RATE( BAUD_RATE )
	)
	baud_generator
	(
		// Baud Clock Signals
		.BAUD_RATE_TICK( tx_baud_tick ),
		.BAUD_SAMPLE_TICK( rx_baud_tick ),
		
		// System Signals
		.CLK( CLK ),
		.RESET( RESET )
	);
	
	
	//
	// UART Receiver
	//
	Serial_UART_Receiver
	#(
		.DATA_BITS( DATA_BITS ),
		.STOP_BITS( STOP_BITS_RX )
	)
	uart_rx
	(
		// UART Receiver Signals
		.RX_READY( RX_READY ),
		.RX_DATA( RX_DATA ),

		// UART Bus Signals
		.UART_RX( uart_rx_sync ),

		// Baud Clock Signals
		.BAUD_TICK( rx_baud_tick ),

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
		.TX_BUSY( TX_BUSY ),
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
