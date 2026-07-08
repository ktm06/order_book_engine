`timescale 1ns/1ps

module MessageParser 
#(
	parameter CLK_RATE_HZ = 50000000,
	parameter DATA_BITS = 8, // should be 8
	parameter MESSAGE_LENGTH = 10
) 
(
	input byteready,
	input  [DATA_BITS-1:0] inbits,
	output logic messageready,
	output logic [MESSAGE_LENGTH * DATA_BITS -1:0] parsed_message,
	input CLK,
	input RESET
);

// COUNTER
logic [3:0] count;

logic [MESSAGE_LENGTH * DATA_BITS -1:0] output_reg;

always_ff @(posedge CLK or posedge RESET) begin
	if (RESET) begin
		count <= 1'b0;
		output_reg <= '0;
		messageready <= 1'b0;
	end else if (byteready) begin
		if (count < MESSAGE_LENGTH) begin
			output_reg <= {output_reg[MESSAGE_LENGTH*DATA_BITS -9:0], inbits}; // concat to shift
			messageready <= 1'b0;
			if (count == MESSAGE_LENGTH-1) begin
				messageready <= 1'b1;
				count <= 1'b0;
			end else begin
				count <= count + 1'b1;
				messageready <= 1'b0;
			end
			end
		end
	end	

always_ff @(posedge CLK) begin
	if (messageready) begin
		parsed_message <= output_reg;
	end
end

endmodule


