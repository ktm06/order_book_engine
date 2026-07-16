`timescale 1ns/1ps

module TF_Results_Serializer();
    localparam CLK_RATE_HZ = 50000000;
    localparam BAUD_RATE = 115200;
    localparam CLK_HALF_PER = ((1.0 / CLK_RATE_HZ) * 1000000000.0) / 2.0; // ns
    localparam BIT_TIME_NS = 1000000000 / BAUD_RATE;
	logic CLK;
    logic RESET;
    initial begin
        CLK = 1'b0;
        forever #(CLK_HALF_PER) CLK = ~CLK;
    end

    initial begin
        RESET = 1'b1;
        #500;
        @(posedge CLK) RESET = 1'b0;
    end
   
    logic [31:0] spread_in;
    logic inready;
    logic [7:0] TX_DATA;
    logic TX_SEND;
    logic TX_DONE;
    logic tx_baud_tick;
    logic rx_baud_tick;
    logic UART_TX;
    Serial_UART_Baud_Generator #(
        .CLK_RATE_HZ(CLK_RATE_HZ),
        .BAUD_RATE(BAUD_RATE)
    ) baud_gen (
        .BAUD_RATE_TICK(tx_baud_tick),
        .BAUD_SAMPLE_TICK(rx_baud_tick),
        .CLK(CLK),
        .RESET(RESET)
    );

    Serial_UART_Transmitter #(
        .DATA_BITS(8),
        .STOP_BITS(1)
    ) uart_tx (
        .TX_SEND(TX_SEND),
        .TX_DATA(TX_DATA),
        .TX_BUSY(TX_BUSY),
        .TX_DONE(TX_DONE),
        .UART_TX(UART_TX),
        .BAUD_TICK(tx_baud_tick),
        .CLK(CLK),
        .RESET(RESET)
    );

    Result_Serializer #(
        .CLK_RATE_HZ(CLK_RATE_HZ)
    ) uut (
        .spread_in(spread_in),
        .inready(inready),
        .TX_DATA(TX_DATA),
        .TX_BUSY(TX_BUSY),
        .TX_SEND(TX_SEND),
        .TX_DONE(TX_DONE),
        .CLK(CLK),
        .RESET(RESET)
    );

    
    // UART output monitor
    initial begin
        forever begin
            @(negedge UART_TX);                  
            #(BIT_TIME_NS + BIT_TIME_NS/2);        
            begin
                logic [7:0] rx_byte;
                for (int i = 0; i < 8; i++) begin
                    rx_byte[i] = UART_TX;         
                    #(BIT_TIME_NS);
                end
                $display("%t  UART sent: %h", $time, rx_byte);
            end
        end
    end

    initial begin
        spread_in = '0;
        inready = 1'b0;
        wait (~RESET);
        #500;

        @(posedge CLK);
        spread_in = 32'hABCDEFBA;
        inready = 1'b1;
        @(posedge CLK);
        inready = 1'b0;
        #400000;
        $display("%t, should be AB CD EF BA", $time);

        @(posedge CLK);
        spread_in = 32'h00000005;
        inready   = 1'b1;
        @(posedge CLK);
        inready   = 1'b0;

        #500000;
        $display("%t, should be 00 00 00 05", $time);
        $finish;
    end
endmodule