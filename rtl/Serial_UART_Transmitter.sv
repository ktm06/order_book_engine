`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Case Western Reserve University
// Engineer: Matt McConnell
// 
// Create Date:    12:36:00 02/18/2017 
// Project Name:   EECS301 Digital Design
// Design Name:    Lab #5 Project
// Module Name:    Serial_UART_Transmitter
// Target Devices: Altera Cyclone V
// Tool versions:  Quartus v15.0
// Description:    Serial UART Transmitter Module
//                 
// Dependencies:   
//
//////////////////////////////////////////////////////////////////////////////////

module Serial_UART_Transmitter
#(
	parameter DATA_BITS = 8,
	parameter STOP_BITS = 1
)
(
	// UART Transmitter Signals
	input                      TX_SEND,
	input      [DATA_BITS-1:0] TX_DATA,
	output reg                 TX_DONE,

	// UART Bus Signals
	output reg  UART_TX,
	
	// Baud Clock Signals
	input BAUD_TICK,
	
	// System Signals
	input CLK,
	input RESET
);	

	// Include Standard Functions header file (needed for bit_index())
	`include "StdFunctions.vh"

	
	//
	// Compute the Packet and Bit Counter Widths
	//
	localparam START_BITS = 1;  // Always One Start Bit
	localparam PARITY_BITS = 0; // No Parity Bit Support (yet)
	
	localparam FRAME_BITS = START_BITS + DATA_BITS + PARITY_BITS + STOP_BITS;
	
	// Remove the Stop Bits from the Frame Register width because
	// the Stop Bits will be implicity set by filling the shift
	// register with 1's so any number of Stop Bits can be output
	// without adding more registers.
	localparam FRAME_WIDTH = FRAME_BITS - STOP_BITS;
	
	localparam BIT_COUNT_WIDTH = bit_index(FRAME_BITS);
	localparam [BIT_COUNT_WIDTH:0] BIT_COUNT_LOADVAL = {1'b1, {BIT_COUNT_WIDTH{1'b0}}} - FRAME_BITS[BIT_COUNT_WIDTH:0];

	reg    [FRAME_WIDTH-1:0] tx_frame_data_reg;
	reg  [BIT_COUNT_WIDTH:0] tx_bit_counter;
	
	wire tx_bit_counter_done = tx_bit_counter[BIT_COUNT_WIDTH];
	
	
	//
	// Serial UART Transmitter State Machine
	//

	// !! Lab 5: Add the Serial UART Transmitter State Machine here !!
	
	reg [5:0] State;
	localparam [5:0]
	S0 = 6'b000001,
	S1 = 6'b000010,
	S2 = 6'b000100,
	S3 = 6'b001000,
	S4 = 6'b010000,
	S5 = 6'b100000;
	
	always @(posedge CLK, posedge RESET)
	begin
		if (RESET)
			begin
			State <= S0;
			TX_DONE <= 1'b0;
			UART_TX <= 1'b1;
			tx_frame_data_reg <= {FRAME_WIDTH{1'b0}};
			tx_bit_counter <= BIT_COUNT_LOADVAL;
			end
		else begin
			case (State)
				S0:
					begin
						TX_DONE <=1'b0;
						
						if (TX_SEND)
							begin
								State <= S1;
							end
						else begin
							State <= S0;
						end
					end
				S1: 
					begin 
						tx_frame_data_reg <= {TX_DATA, {START_BITS{1'b0}} };
						State <= S2;
						
					end
				S2:
					begin
						if (BAUD_TICK)
							begin
								State <= S3;
							end
						else begin
							State <= S2;
						end
					end
				S3: 
					begin
	
						UART_TX <= tx_frame_data_reg[0];
							if (tx_bit_counter_done)
								begin
									State <= S5;
								end
							else begin
								State <= S4;
							end
					end
				S4:
					begin
						tx_frame_data_reg <= {1'b1, tx_frame_data_reg[FRAME_WIDTH-1:1] };
						State <= S2;
					end
				S5:
					begin
						TX_DONE <=1'b1;
						State <=S0;
					end
				endcase
end
end
	
	
endmodule
