`timescale 1ns/1ps
module TF_Message_Decoder();
	localparam CLK_RATE_HZ = 50000000;
	localparam CLK_RATE_PER = ((1.0 / CLK_RATE_HZ) * 1000000000.0)/ 2;
	logic RESET;
	logic CLK;
	initial 
	begin
		CLK = 1'b0;
		forever #(CLK_RATE_PER) CLK = ~CLK;
	end
	
	initial
	begin
		RESET = 1'b1;
		#500;
		@(posedge CLK) RESET = 1'b0;
	end

	//UUT
	logic [79:0] inbits;
	logic messageready;
	logic [7:0] msgtype;
	logic [31:0] price;
	logic [7:0] side;
	logic [31:0] size;
	logic msgdecoded;

	Message_Decoder #(
		.CLK_RATE_HZ(CLK_RATE_HZ),
		.DATA_BITS(8),
		.MESSAGE_LENGTH(10)
	) uut (
		.inbits(inbits),
		.message_ready(messageready),
		.msgtype(msgtype),
		.price(price),
		.side(side),
		.size(size),
		.CLK(CLK),
		.RESET(RESET),
		.msg_decoded(msgdecoded)
	);
	initial begin
		messageready = 1'b0;
		inbits = '0;
		wait(~RESET);
		#500;
		messageready = 1'b1;
		inbits = 80'hA0A1A2A3A4A5A6A7A8A9;
		@(posedge CLK);
		@(posedge CLK);
		if (size === 80'hA6A7A8A9 & price === 80'hA2A3A4A5 & side === 80'hA1 & msgtype ===80'hA0)
			$display("PASS");
		else
			$display("FAIL: SIZE-%h, PRICE-%h, SIDE-%h, MSGTYPE-%h", size, price, side, msgtype);	
		$finish;
	end
endmodule
		
