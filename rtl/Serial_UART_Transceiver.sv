module Serial_UART_Transceiver #(
    parameter BAUD_RATE = 115200,
    parameter CLK_RATE_HZ = 50000000,
    parameter DATA_BITS = 8,
    parameter OVERSAMPLE = 16

) (
	input logic UART_RX,
	output logic UART_TX,
	output logic RX_READY,
	output logic [DATA_BITS-1:0] RX_DATA,
	input logic TX_SEND,
	input logic [DATA_BITS-1:0] TX_DATA,
	output logic TX_BUSY,
	output logic TX_DONE,
	input CLK,
	input RESET
);

logic uart_rx_sync;

CDC_Input_Synchronizer #(
	.SYNC_REG_LEN( 2 ) 
) uart_rx_synchronizer (
    .ASYNC_IN( UART_RX ),
    .SYNC_OUT( uart_rx_sync ),
    .CLK( CLK ) 
);

logic tx_baud_tick;
logic rx_baud_tick;
	
Serial_UART_Baud_Generator #(
    .CLK_RATE_HZ( CLK_RATE_HZ ),
    .BAUD_RATE( BAUD_RATE ),
    .OVERSAMPLE(OVERSAMPLE)
) baud_generator (
    .tx_tick( tx_baud_tick ),
    .rx_tick( rx_baud_tick ),
    .CLK( CLK ),
    .RESET( RESET )
);

Serial_UART_Receiver #(
    .DATA_BITS( DATA_BITS ),
    .TICKS_PER_BIT(OVERSAMPLE)
) reciever (
    .rx_ready( RX_READY ),
    .rx_data( RX_DATA ),
    .uart_rx( uart_rx_sync ),
    .baud_pulse( rx_baud_tick ),
    .CLK( CLK ),
    .RESET( RESET )
);

Serial_UART_Transmitter #(
    .DATA_BITS( DATA_BITS )
) transmitter (
    .tx_send( TX_SEND ),
    .tx_data( TX_DATA ),
    .tx_busy( TX_BUSY ),
    .tx_done( TX_DONE ),
    .uart_tx( UART_TX ),
    .baud_pulse( tx_baud_tick ),
    .CLK( CLK ),
    .RESET( RESET )
);	

endmodule

