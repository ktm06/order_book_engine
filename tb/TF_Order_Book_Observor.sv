`timescale 1ns/1ps

module TF_Order_Book_Observer_TopLevel();

    localparam CLK_RATE_HZ = 50000000;
    localparam BAUD_RATE = 115200;
    localparam DATA_BITS = 8;
    localparam MESSAGE_LENGTH = 10;
    
    // we calculate bit_time ns as inverse of baud rate in ns
    localparam BIT_TIME_NS = 1000000000 / BAUD_RATE; 

    localparam CLK_HALF_PER =(1.0/ CLK_RATE_HZ * 1000000000.0) / 2.0;

    localparam [7:0]
    ASK = 8'd0,
    BID = 8'd1;

    localparam[7:0]
    ADD = 8'h01,
    DEL = 8'h02,
    MOD = 8'h03;

    logic CLK;
    logic RESET_N;
    logic UART_RX;
    logic UART_TX;

    initial begin
        CLK = 1'b0;
        forever #(CLK_HALF_PER) CLK = ~CLK;
    end

    initial begin
        RESET_N = 1'b0;
        #500;
        @(posedge CLK) RESET_N = 1'b1;
    end

    Order_Book_Observer_TopLevel #(
        .CLK_RATE_HZ(CLK_RATE_HZ),
        .BAUD_RATE(BAUD_RATE),
        .DATA_BITS(DATA_BITS),
        .MESSAGE_LENGTH(MESSAGE_LENGTH)
    ) uut (
        .CLK(CLK),
        .RESET_N(RESET_N),
        .UART_RX(UART_RX),
        .UART_TX(UART_TX)
    );

    // task for sending uart single byte
    // begin with low, then send from least to most significant, and end high
    // total = BIT_TIME_NS * 10 ns.
    task automatic sendbyte (
        input [DATA_BITS-1:0] data
    ); 
        begin 
            UART_RX = 1'b0;
            #(BIT_TIME_NS);
            for (int i = 0; i < 8; i++) begin
                UART_RX = data[i];
                #(BIT_TIME_NS);
            end
            UART_RX = 1'b1;
            #(BIT_TIME_NS);

        end
    endtask

    // now we send 10 bytes per message
    // FORMAT: inbits[79:72]  is message type, [71:64] is side (ASK or BID), price is [63:32], and size is [31:0]
    // start w most significant
    task automatic send_msg (
        input[7:0] msgtype,
        input[7:0] side,
        input [31:0] price,
        input [31:0] size
    ); 
        begin
            sendbyte(msgtype);
            sendbyte(side);
            sendbyte(price[31:24]);
            sendbyte(price[23:16]);
            sendbyte(price[15:8]);
            sendbyte(price[7:0]);
            sendbyte(size[31:24]);
            sendbyte(size[23:16]);
            sendbyte(size[15:8]);
            sendbyte(size[7:0]);
        end
    endtask 

    initial begin 
        UART_RX = 1'b1; 
        wait (RESET_N);
        #1000;
        send_msg(ADD, ASK, 32'd50, 32'd10);
        $display("%t", $time); // spread = 0
        send_msg(ADD, ASK, 32'd55, 32'd10);
        $display("%t", $time); // spread = 0
        send_msg(ADD, ASK, 32'd60, 32'd10);
        $display("%t", $time); // spread = 0
        send_msg(ADD, BID, 32'd40, 32'd10);
        $display("%t", $time); // spread = 10
        send_msg(ADD, BID, 32'd45, 32'd10);
        $display("%t", $time); // spread = 5
        send_msg(ADD, BID, 32'd45, 32'd20);
        $display("%t", $time);// spread = 5
        send_msg(DEL, BID, 32'd45, 32'd30);
        $display("%t", $time); // spread =10 
        send_msg(DEL, ASK, 32'd50, 32'd10);
        $display("%t", $time); // spread = 15
        send_msg(MOD, ASK, 32'd55, 32'd99);
        $display("%t", $time); // spread = 15
        send_msg(DEL, ASK, 32'd12345, 32'd5);
        $display("%t", $time); // spread = 15
        send_msg(ADD, BID, 32'd41, 32'd10);
        $display("%t", $time); // spread = 14
        send_msg(ADD, BID, 32'd42, 32'd10);
        $display("%t", $time); // spread = 13
        send_msg(ADD, BID, 32'd43, 32'd10);
        $display("%t", $time); // spread = 12
        send_msg(ADD, BID, 32'd44, 32'd10);
        $display("%t", $time); // spread = 11
        send_msg(ADD, BID, 32'd1, 32'd10);
        #(BIT_TIME_NS * 10); 
        $display("%t", $time); // spread = 11
        $finish;
    end
endmodule