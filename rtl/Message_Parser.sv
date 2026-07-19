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


logic [3:0] count;

logic [MESSAGE_LENGTH * DATA_BITS -1:0] output_reg;

logic [15:0] idle_count;

assign parsed_message = output_reg;

always_ff @(posedge CLK or posedge RESET) begin
	if (RESET) idle_count <= '0;
	else if (byteready) idle_count <= '0;
	else if (!idle_count[15]) idle_count <= idle_count + 1'b1;
end

always_ff @(posedge CLK or posedge RESET) begin
	if (RESET) begin
		count <= 1'b0;
		output_reg <= '0;
		messageready <= 1'b0;
	end else begin
		messageready <= 1'b0;
		if (byteready) begin
			if (idle_count[15]) begin
				output_reg <= {{(MESSAGE_LENGTH*DATA_BITS-8){1'b0}}, inbits};
				count <= 4'd1;
			end else if (count < MESSAGE_LENGTH) begin
				output_reg <= {output_reg[MESSAGE_LENGTH*DATA_BITS -9:0], inbits}; 
				if (count == MESSAGE_LENGTH-1) begin
					messageready <= 1'b1;
					count <= 1'b0;
				end else begin
					count <= count + 1'b1;
				end
			end
		end
	end
end


endmodule