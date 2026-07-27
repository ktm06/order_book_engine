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
    if (RESET) begin
        State <= IDLE;
        samp_count <= '0;
        rx_data <= 'b0;
        rx_ready <= 1'b0;
        bit_count <= '0;
        rx_shift <= '0;
    end else begin
        rx_ready <=1'b0;
        if (baud_pulse) begin
            if (samp_count != 4'b0) begin // decrement
            samp_count <= samp_count - 1'b1;
            end
            case (State)
                IDLE: begin
                    if (~uart_rx) begin
                        samp_count <= HALF_BIT - 1;
                        State <= START;
                    end
                end
                START: begin
                    if (samp_at_center) begin
                        if (~uart_rx) begin
                        samp_count <= TICKS_PER_BIT - 1;
                        bit_count <= '0;
                        State <= DATA;
                        end else begin
                            State <= IDLE;
                        end
                    end
                end
                DATA: begin
                    if (samp_at_center) begin
                        rx_shift <= {uart_rx, rx_shift[DATA_BITS-1:1]};
                        samp_count <= TICKS_PER_BIT - 1;
                        if (bit_count == DATA_BITS-1) State <= STOP;
                        else bit_count <= bit_count + 1'b1;
                    end
                    end
                STOP:
                    if (samp_at_center) begin
                        if (uart_rx) begin
                            rx_data <= rx_shift;
                            rx_ready <= 1'b1;
                        end
                        State <= IDLE;
                    end
                default: State <= IDLE;

            endcase

    end
end
end

endmodule