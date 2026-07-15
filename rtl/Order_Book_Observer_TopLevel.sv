`timescale 1ns/1ps

module Order_Book_Observer_TopLevel #(
    parameter CLK_RATE_HZ = 50000000,
    parameter BAUD_RATE = 115200,
    parameter DATA_BITS = 8,
    parameter MESSAGE_LENGTH = 10
) (
    input CLK,
    input RESET_N,
    input UART_RX,
    output UART_TX
);

logic RX_READY;
logic [DATA_BITS-1:0] RX_DATA;
logic TX_SEND;
logic [DATA_BITS-1:0]TX_DATA;
logic TX_BUSY;
logic TX_DONE;
logic messageready;
logic [79:0] parsed_message;
logic [7:0] msgtype;
logic [7:0] side;
logic [31:0] price;
logic [31:0] size;
logic msgdecoded;
logic [31:0] best_spread;
logic outready;
logic orderbookbusy;

logic RESET;
assign RESET = ~RESET_N;

Serial_UART_Transceiver
#(
    .CLK_RATE_HZ(CLK_RATE_HZ), // Hz
	.BAUD_RATE(BAUD_RATE), // Baud (bits/s)
	.DATA_BITS(8),
	.STOP_BITS_TX(1),
	.STOP_BITS_RX(1)
) transceiver (
	// UART Bus Signals
	.UART_RX(UART_RX),
	.UART_TX(UART_TX),

	// UART Receiver Signals
	.RX_READY(RX_READY),
	.RX_DATA(RX_DATA),

	// UART Transmitter Signals
	.TX_SEND(TX_SEND),
	.TX_DATA(TX_DATA),
	.TX_BUSY(TX_BUSY),
	.TX_DONE(TX_DONE),

	// System Signals
	.CLK(CLK),
	.RESET(RESET)
);


MessageParser 
#(
	.CLK_RATE_HZ(CLK_RATE_HZ),
	.DATA_BITS(DATA_BITS), // should be 8
	.MESSAGE_LENGTH(10)
) parser (
	.byteready(RX_READY),
	.inbits(RX_DATA),
	.messageready(messageready),
	.parsed_message(parsed_message),
	.CLK(CLK),
	.RESET(RESET)
);

Message_Decoder 
#(
	.CLK_RATE_HZ(CLK_RATE_HZ),
	.DATA_BITS(DATA_BITS),
	.MESSAGE_LENGTH(MESSAGE_LENGTH)
) decoder (
	.inbits(parsed_message),

	.message_ready(messageready),
	.msgtype(msgtype),
	.price(price),
	.side(side),
	.size(size),
	.msg_decoded(msgdecoded),
	.CLK(CLK),
	.RESET(RESET)
);


Order_Book_Engine #(
	.CLK_RATE_HZ(CLK_RATE_HZ)
) engine (
    .price(price),
    .size(size),
    .side(side),
    .msgtype(msgtype),
    .inready(msgdecoded),
    .best_spread(best_spread),
    .outready(outready),
    .busy(orderbookbusy),
    .CLK(CLK),
    .RESET(RESET)
);
Result_Serializer #(
    .CLK_RATE_HZ(CLK_RATE_HZ)
) serializer (
    .spread_in(best_spread),
    .inready(outready),
    .TX_DATA(TX_DATA),
    .TX_SEND(TX_SEND),
    .TX_DONE(TX_DONE),
    .TX_BUSY(TX_BUSY),
    .CLK(CLK),
    .RESET(RESET)
);

endmodule

