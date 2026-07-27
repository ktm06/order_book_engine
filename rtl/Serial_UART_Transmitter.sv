module Serial_UART_Transmitter #(
    parameter DATA_BITS = 8
) (
    input logic tx_send,
    input logic [DATA_BITS-1:0] tx_data,
    output logic tx_busy,
    output logic uart_tx,
    output logic tx_done,
    input logic baud_pulse,
    input logic CLK,
    input logic RESET
);

logic [DATA_BITS:0]frame_bits;
logic [3:0] frame_cnt;

typedef enum logic [3:0] {
    IDLE= 4'b0001,
    START=4'b0010,
    DATA=4'b0100,
    STOP= 4'b1000
} State_t;



State_t State;

assign tx_busy = (State != IDLE);
always_ff @(posedge CLK, posedge RESET) begin
    if (RESET) begin
        uart_tx <= 1'b1;
        tx_done <= 1'b0;
        State <= IDLE;
        frame_bits <= '1;
        frame_cnt <= '0;
    end else begin
        tx_done <= 1'b0;
        if (baud_pulse) begin
            case (State)
                IDLE: begin
                    tx_done <= 1'b0;
                    if (tx_send) State <= START;
                end
                START: begin
                    frame_bits <= {tx_data, 1'b0};
                    frame_cnt <= DATA_BITS;
                    State <= DATA;
                end
                DATA: begin
                    uart_tx <= frame_bits[0];
                    frame_bits <= {1'b1, frame_bits[DATA_BITS:1]};
                    if (frame_cnt == 0) State <= STOP;
                    else frame_cnt <= frame_cnt - 1'b1;
                end
                STOP: begin
                    uart_tx <= 1'b1;
                    tx_done <= 1'b1;
                    State <= IDLE;
                end
            endcase 
        end
    end

end


endmodule