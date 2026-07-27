module Serial_UART_Baud_Generator #(
    parameter CLK_RATE_HZ = 50000000,
    parameter BAUD_RATE = 115200,
    parameter OVERSAMPLE = 16
) (
    output logic tx_tick, // 1x bit rate
    output logic rx_tick, // 16x bit rate
    input CLK,
    input RESET
);

localparam integer OVERSAMPLE_TICKS = ((1.0 * CLK_RATE_HZ) / (BAUD_RATE * OVERSAMPLE));

logic [4:0] samp_div;
logic [4:0] bit_div;

always_ff @(posedge CLK, posedge RESET) begin
        if (RESET) begin
            samp_div <= '0;
            bit_div  <= '0;
            rx_tick  <= 1'b0;
            tx_tick  <= 1'b0;
        end else begin
            rx_tick <= 1'b0;
            tx_tick <= 1'b0;

            if (samp_div == OVERSAMPLE_TICKS - 1) begin
                samp_div <= '0;
                rx_tick  <= 1'b1;

                if (bit_div == OVERSAMPLE - 1) begin
                    bit_div <= '0;
                    tx_tick <= 1'b1;   
                end else
                    bit_div <= bit_div + 1'b1;
            end else
                samp_div <= samp_div + 1'b1;
        end
end

endmodule