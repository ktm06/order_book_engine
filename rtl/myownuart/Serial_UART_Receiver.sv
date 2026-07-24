module Serial_UART_Receiver #(
    parameter DATA_BITS = 8, // should be 8
    parameter TICKS_PER_BIT = 16 // oversample
) (
    input logic uart_rx,
    output logic [DATA_BITS - 1:0] rx_data,
    output logic rx_ready,

    input logic baud_pulse,
    input logic CLK,
    input logic RESET

);

localparam HALF_BIT = TICKS_PER_BIT / 2;

logic [3:0] samp_count;
logic [3:0] bit_count;
logic [DATA_BITS-1:0] rx_shift;

logic samp_at_center;

assign samp_at_center = (samp_count == 4'b0);

typedef enum logic [3:0] {
    IDLE = 4'b0001,
    START = 4'b0010,
    DATA = 4'b0100,
    STOP = 4'b1000
} State_t;

State_t State;

always_ff @(posedge CLK, posedge RESET) begin
    if (reset) begin
        State <= '0;
        samp_count <= '0;

        rx_data <= 'b0;
        rx_ready <= 1'b0;
    end else begin
        case (State)



        endcase

    end
end

endmodule