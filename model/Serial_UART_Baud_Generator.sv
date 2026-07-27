`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Case Western Reserve University
// Engineer: Matt McConnell
// 
// Create Date:    12:36:00 02/18/2017 
// Project Name:   EECS301 Digital Design
// Design Name:    Lab #5 Project
// Module Name:    Serial_UART_Baud_Generator
// Target Devices: Altera Cyclone V
// Tool versions:  Quartus v17.0
// Description:    Serial UART Baud Generator Module
//                 
// Dependencies:   
//
//////////////////////////////////////////////////////////////////////////////////

module Serial_UART_Baud_Generator
#(
	parameter CLK_RATE_HZ = 50000000, // Hz
	parameter BAUD_RATE = 115200      // Baud (bits/s)
)
(
	// Baud Clock Signals
	output reg BAUD_RATE_TICK,
	output reg BAUD_SAMPLE_TICK,
	
	// System Signals
	input CLK,
	input RESET
);

	// Include Standard Functions header file (needed for pow2())
	`include "StdFunctions.vh"
	
	//
	// This function computes the accumulator width N by finding the
	// minimial register size to meet the specified error parameter for
	// the given system clock rate and requested baud rate.
	// NOTE: 'real' variables were not used due to Quartus limitations.
	//
	// Truncating the Tuning Word to the accumulator width will lose the
	// fractional frequency component causing a small error.  The following
	// formula is used to compute the error which is used to pick N such
	// that the resulting error is less than the requested error.
	//
	// Error = abs(m_real - m_int) / m_real;
	//
	function integer Find_N;
		input integer clk_rate;  // Hz
		input integer baud_rate; // Hz
		input integer req_err_ppm;
		integer n, m_int;
		reg done;
	begin
		`define m_func ((1.0 * baud_rate * pow2(n)) / clk_rate)
		done = 0;
		n = 0;
		while (!done && n<32)
		begin
			n = n + 1;
			m_int = `m_func;
			if ((`m_func - m_int) < 0.0)
			begin
				if ( ((m_int - `m_func) / `m_func) < (req_err_ppm / 1000000.0) )
					done = 1;
			end
			else
			begin
				if ( ((`m_func - m_int) / `m_func) < (req_err_ppm / 1000000.0) )
					done = 1;
			end
		end
		Find_N = n;
	end
	endfunction

	//
	// Set the Max Error for Accumulator Width Computation
	//
	localparam NCO_MAX_ERROR = 0.001;
	
	//
	// Compute the NCO Accumulator Width Automatically
	//
	localparam integer NCO_N = Find_N(CLK_RATE_HZ, BAUD_RATE, (NCO_MAX_ERROR * 1000000.0));

	//
	// Compute the Tuning Word M
	//
	localparam integer NCO_M_INT = (1.0 * BAUD_RATE * pow2(NCO_N)) / (1.0 * CLK_RATE_HZ);
	localparam [NCO_N-1:0] NCO_M = NCO_M_INT[NCO_N-1:0];
	
	//
	// Calculate the Baud Rate Error (for verification)
	//
	localparam real NCO_M_ACT = (1.0 * BAUD_RATE * pow2(NCO_N)) / (1.0 * CLK_RATE_HZ);
	localparam real NCO_M_ERR = ((NCO_M_ACT - NCO_M_INT) < 0.0) ? (NCO_M_INT - NCO_M_ACT) / NCO_M_ACT : (NCO_M_ACT - NCO_M_INT) / NCO_M_ACT;
	
	//
	// NCO Accumulator Register
	//
	reg  [NCO_N-1:0] nco_accumulator_reg;
	wire [NCO_N-1:0] nco_accumulator_sum;
	
	// Accumulator Summation
	assign nco_accumulator_sum = nco_accumulator_reg + NCO_M;
	
	always @(posedge CLK, posedge RESET)
	begin
		if (RESET)
			nco_accumulator_reg <= {NCO_N{1'b0}};
		else			
			nco_accumulator_reg <= nco_accumulator_sum;
	end

	//
	// Accumulator Rollover Taps
	//
	wire full_rate_rollover = nco_accumulator_reg[NCO_N-1];     //  x1 rate
	wire sample_rate_rollover = nco_accumulator_reg[NCO_N-1-4]; // x16 rate
	

	//
	// Full Cycle Output Tick
	//
	reg prev_full_rate_rollover;
	
	initial
	begin
		prev_full_rate_rollover = 1'b0;
		BAUD_RATE_TICK = 1'b0;
	end
	
	always @(posedge CLK)
	begin
		prev_full_rate_rollover <= full_rate_rollover;
	end
	
	always @(posedge CLK)
	begin
		BAUD_RATE_TICK <= full_rate_rollover & ~prev_full_rate_rollover; // Rising-Edge
	end
	
	
	//
	// Sample Interval Output Tick
	//
	reg prev_sample_rate_rollover;
	
	initial
	begin
		prev_sample_rate_rollover = 1'b0;
		BAUD_SAMPLE_TICK = 1'b0;
	end
	
	always @(posedge CLK)
	begin
		prev_sample_rate_rollover <= sample_rate_rollover;
	end
	
	always @(posedge CLK)
	begin
		BAUD_SAMPLE_TICK <= ~sample_rate_rollover & prev_sample_rate_rollover; // Falling-Edge
	end
	
	
//
// NOTE: If the Baud Samping Rate is an exact multiple of the system clock then
//       the following code with simple rollover counters can be more efficent
//       but the clock requirements make it less flexible.
//	//
//	// Baud Rate Generator
//	//
//	//  Transmiter outputs at 1x baud rate
//	//  Receiver oversamples at 16x baud rate
//	//
//	// NOTE: Baud rate may be slightly off depending whether or not it
//	//       is a multiple of the system clock.
//	//
//
//	// Include Standard Functions header file (needed for bit_index())
//	`include "StdFunctions.vh"
//	
//	localparam BAUD_OVERSAMPLE = 16;
//	
//	localparam integer BAUD_OVERSAMPLE_TICKS = ((1.0 * CLK_RATE) / (BAUD_RATE * BAUD_OVERSAMPLE));
//	
//	localparam BAUD_RX_REG_WIDTH = bit_index(BAUD_OVERSAMPLE_TICKS);
//	localparam [BAUD_RX_REG_WIDTH:0] BAUD_RX_REG_LOADVAL = {1'b1, {(BAUD_RX_REG_WIDTH){1'b0}}} - BAUD_OVERSAMPLE_TICKS[BAUD_RX_REG_WIDTH:0] + 1'b1;
//	
//	localparam BAUD_TX_REG_WIDTH = bit_index(BAUD_OVERSAMPLE-1);
//	localparam [BAUD_TX_REG_WIDTH:0] BAUD_TX_REG_LOADVAL = {1'b1, {(BAUD_TX_REG_WIDTH){1'b0}}} - BAUD_OVERSAMPLE[BAUD_TX_REG_WIDTH:0];
//
//	reg [BAUD_RX_REG_WIDTH:0] rx_baud_reg;
//	wire                      rx_baud_tick;
//
//	reg [BAUD_TX_REG_WIDTH:0] tx_baud_reg;
//	wire                      tx_baud_tick;
//	
//	assign tx_baud_tick = tx_baud_reg[BAUD_TX_REG_WIDTH]; //  1x Baud Rate
//	assign rx_baud_tick = rx_baud_reg[BAUD_RX_REG_WIDTH]; // 16x Baud Rate
//
//	initial
//	begin
//		rx_baud_reg <= BAUD_RX_REG_LOADVAL;
//		tx_baud_reg <= BAUD_TX_REG_LOADVAL;
//	end
//	
//	always @(posedge CLK)
//	begin
//		if (rx_baud_tick)
//			rx_baud_reg <= BAUD_RX_REG_LOADVAL;
//		else
//			rx_baud_reg <= rx_baud_reg + 1'b1;
//	end
//	
//	always @(posedge CLK)
//	begin
//		if (tx_baud_tick)
//			tx_baud_reg <= BAUD_TX_REG_LOADVAL;
//		else if (rx_baud_tick)
//			tx_baud_reg <= tx_baud_reg + 1'b1;
//	end	
	
endmodule
