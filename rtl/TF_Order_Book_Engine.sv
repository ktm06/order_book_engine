`timescale 1ns/1ps

module TF_Order_Book_Engine();
     
    localparam CLK_RATE_HZ = 50000000;
    localparam CLK_HALF_PER = ((1.0 / CLK_RATE_HZ) * 1000000000.0) / 2.0; // ns
	
	logic CLK;
    initial begin
        CLK = 1'b0;
        forever #(CLK_HALF_PER) CLK = ~CLK;
    end
    logic RESET;

    logic [31:0] price;
    logic [31:0] size;
    logic [7:0] side;
    logic [7:0] msgtype;
    logic inready;
    logic [31:0] best_spread;

    initial begin
        RESET = 1'b1;
        #500
        @(posedge CLK) RESET = 1'b0;
    end


    Order_Book_Engine #(
        .CLK_RATE_HZ(CLK_RATE_HZ)
    ) uut (
        .price(price),
        .size(size),
        .side(side),
        .msgtype(msgtype),
        .inready(inready),
        .best_spread(best_spread),
        .CLK(CLK),
        .RESET(RESET)
    );
    localparam [7:0]
    ASK = 8'd0,
    BID = 8'd1;

    localparam[7:0]
    ADD = 8'h01,
    DEL = 8'h02,
    MOD = 8'h03;

    task send_msg(input [7:0] mt, input [7:0] sd, input [31:0] pr, input [31:0] sz);
    begin
        @(posedge CLK);
        msgtype = mt; 
        side = sd; 
        price = pr; 
        size = sz;
        inready = 1'b1;
        @(posedge CLK);
        inready = 1'b0;
        repeat (3) @(posedge CLK); // 3 clk cyle to gor through states
    end
    endtask

    initial begin
        #1000;
        send_msg(ADD, ASK, 32'd50, 32'd10);
        $display("%t ADD ask 50 spread=%0d (expect 0, no bids)", $time, best_spread);

        send_msg(ADD, ASK, 32'd55, 32'd10);
        send_msg(ADD, ASK, 32'd60, 32'd10);
        $display("%t 3 asks spread=%0d (expect 0)", $time, best_spread);

        send_msg(ADD, BID, 32'd40, 32'd10);
        $display("%t ADD bid 40 spread=%0d (expect 10)", $time, best_spread);

        send_msg(ADD, BID, 32'd45, 32'd10);
        $display("%t ADD bid 45 spread=%0d (expect 5)", $time, best_spread);

        send_msg(ADD, BID, 32'd45, 32'd20);
        $display("%t aggregate 45 spread=%0d (expect 5)", $time, best_spread);

        send_msg(DEL, BID, 32'd45, 32'd30);
        $display("%t DEL bid 45 spread=%0d (expect 10)", $time, best_spread);

        send_msg(DEL, ASK, 32'd50, 32'd10);
        $display("%t DEL ask 50 spread=%0d (expect 15)", $time, best_spread);

        send_msg(MOD, ASK, 32'd55, 32'd99);
        $display("%t MOD ask 55 spread=%0d (expect 15)", $time, best_spread);

        send_msg(DEL, ASK, 32'd12345, 32'd5);
        $display("%t DEL missing spread=%0d (expect 15, no-op)", $time, best_spread);

        send_msg(ADD, BID, 32'd41, 32'd10);
        send_msg(ADD, BID, 32'd42, 32'd10);
        send_msg(ADD, BID, 32'd43, 32'd10);
        $display("%t 4 bids full spread=%0d (expect 12)", $time, best_spread);

        send_msg(ADD, BID, 32'd44, 32'd10);
        $display("%t evict worst spread=%0d (expect 11)", $time, best_spread);

        send_msg(ADD, BID, 32'd1, 32'd10);
        $display("%t reject worse spread=%0d (expect 11)", $time, best_spread);

        $finish;
    end
endmodule