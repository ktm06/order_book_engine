`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Case Western Reserve University
// Engineer: Matt McConnell
// 
// Create Date:    12:36:00 02/18/2017 
// Project Name:   EECS301 Digital Design
// Design Name:    Serial UART Project
// Module Name:    Serial_UART_Receiver
// Target Devices: Altera Cyclone V
// Tool versions:  Quartus v15.0
// Description:    Serial UART Receiver Module
//                 
// Dependencies:   
//
//////////////////////////////////////////////////////////////////////////////////

module Serial_UART_Receiver
#(
	parameter DATA_BITS = 8,
	parameter STOP_BITS = 1
)
(
	// UART Receiver Signals
	output reg                 RX_READY,
	output reg [DATA_BITS-1:0] RX_DATA,

	// UART Bus Signals
	input UART_RX,

	// Baud Clock Signals
	input BAUD_TICK,

	// System Signals
	input CLK,
	input RESET
);

	// Include Standard Functions header file (needed for bit_index())
	`include "StdFunctions.vh"

	
	//
	// Compute Bit Count Register Size
	//
	localparam BIT_COUNT_WIDTH = bit_index(DATA_BITS);
	localparam [BIT_COUNT_WIDTH:0] BIT_COUNT_LOADVAL = {1'b1, {BIT_COUNT_WIDTH{1'b0}}} - DATA_BITS[BIT_COUNT_WIDTH:0];

	reg [BIT_COUNT_WIDTH:0] bit_count_reg;
	wire                    bit_count_done = bit_count_reg[BIT_COUNT_WIDTH];
	
	
	//
	// Receiver Sample Counter
	//
	localparam SAMP_COUNT = 4;  // Power-of-2 factor, matching Baud Tick Rate Oversample (2^4=16)
	localparam [SAMP_COUNT-1:0] SAMP_COUNT_LOADVAL = {1'b1,{SAMP_COUNT-1{1'b0}}} + 2'h2; // Reset to half-count (adjusted for rollover)
	
	reg                  samp_count_reset;
	reg [SAMP_COUNT-1:0] samp_count_reg;
	reg                  samp_at_center;
	
	initial
	begin
		samp_count_reg <= SAMP_COUNT_LOADVAL;
		samp_at_center <= 1'b0;
	end
	
	// Sample Count Register
	always @(posedge CLK)
	begin
		if (samp_count_reset)
			samp_count_reg <= SAMP_COUNT_LOADVAL;
		else if (BAUD_TICK)
			samp_count_reg <= samp_count_reg + 1'b1;
	end
	
	// Sample At Bit Center Point Status Register
	always @(posedge CLK)
	begin
		samp_at_center <= (samp_count_reg == {SAMP_COUNT{1'b0}}) ? 1'b1 : 1'b0;
	end
	
	
	//
	// UART Receiver State Machine
	//
	reg  [DATA_BITS-1:0] rx_data_reg;

	// !! Lab 6: Implement the Serial UART Receiver State Machine here !!
	reg [4:0] State;
	localparam [4:0]
	S0 = 5'b00001,
	S1 = 5'b00010,
	S2 = 5'b00100,
	S3 = 5'b01000,
	S4 = 5'b10000;

	always @(posedge CLK, posedge RESET) begin
		if (RESET) begin
			State <= S0;
			RX_READY <= 1'b0;
			RX_DATA <= {DATA_BITS{1'b0}};
			rx_data_reg <= {DATA_BITS{1'b0}};
			bit_count_reg <= BIT_COUNT_LOADVAL;
			samp_count_reset <= 1'b1;
		end else begin
			case (State)
				S0: begin
					RX_READY <= 1'b0;
					samp_count_reset <= 1'b1;
					bit_count_reg <= BIT_COUNT_LOADVAL;
					if (BAUD_TICK & ~UART_RX) begin
						State <= S1;
					end else begin
						State <= S0;
					end
				end
				S1: begin
					samp_count_reset <= 1'b0;
					if (BAUD_TICK & samp_at_center) begin
						if (~UART_RX) begin
							State <= S2;
						end else begin
							State <= S0;
						end
					end else begin
						State <= S1;
					end
				end
				S2: begin
					if (BAUD_TICK & samp_at_center) begin
						if (bit_count_done) begin
							State <= S4;
						end else begin
							State <= S3;
						end
					end else begin
						State <= S2;
					end
				end
				S3: begin
					bit_count_reg <= bit_count_reg + 1'b1;
					rx_data_reg <= {UART_RX, rx_data_reg[DATA_BITS-1:1]};
					State <=S2;
				end
				S4: begin
					if (UART_RX) begin
						RX_DATA <= rx_data_reg;
						RX_READY <= 1'b1;
					end
					State <= S0;
				end
				default: State <= S0;
			endcase
		end
	end
endmodule
