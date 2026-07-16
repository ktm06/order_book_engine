`timescale 1ns/1ps

module TF_Bid_Comparator();
    logic v0, v1, v2, v3;
    logic [31:0] p0, p1, p2, p3;
    logic [1:0] best_bid_num;
    logic [31:0] best_bid_price;
    logic valid_best_bid;
    
    Bid_Comparator uut (
        .v0(v0),
        .v1(v1),
        .v2(v2),
        .v3(v3),
        .p0(p0),
        .p1(p1),
        .p2(p2),
        .p3(p3),
        .best_bid_num(best_bid_num),
        .best_bid_price(best_bid_price),
        .valid_best_bid(valid_best_bid)
    );

    initial begin
        // all valid test
        v0 = 1'b1;
        v1 = 1'b1;
        v2 = 1'b1;
        v3 = 1'b1;
        p0 = 32'h0000000A;
        p1 = 32'h0000000B;
        p2 = 32'h0000000C;
        p3 = 32'h0000000D;

        #50;
        if (best_bid_num === 2'b11 && best_bid_price === 32'h0000000D && valid_best_bid === 1'b1) begin
            $display("PASS: All valid test");
        end else begin
            $display("FAIL: best_bid_num- %h, best_bid_price: %h, valid_best_bid: %h", best_bid_num, best_bid_price, valid_best_bid);
        end

        v0 = 1'b1;
        v1 = 1'b1;
        v2 = 1'b1;
        v3 = 1'b0;
        p0 = 32'h0000000A;
        p1 = 32'h0000000B;
        p2 = 32'h0000000C;
        p3 = 32'h0000000D;
        #50;
        if (best_bid_num === 2'b10 && best_bid_price === 32'h0000000C && valid_best_bid === 1'b1) begin
            $display("PASS: v3 invalid test");
        end else begin
            $display("FAIL: best_bid_num- %h, best_bid_price: %h, valid_best_bid: %h", best_bid_num, best_bid_price, valid_best_bid);
        end

        v0 = 1'b0;
        v1 = 1'b0;
        v2 = 1'b0;
        v3 = 1'b0;

        p0 = 32'h0000000A;
        p1 = 32'h0000000B;
        p2 = 32'h0000000C;
        p3 = 32'h0000000D;
        #50;

        if (best_bid_num === 2'b00 && best_bid_price === 32'h00000000 && valid_best_bid === 1'b0) begin
            $display("PASS: all invalid test");
        end else begin
            $display("FAIL: best_bid_num- %h, best_bid_price: %h, valid_best_bid: %h", best_bid_num, best_bid_price, valid_best_bid);
        end
    end
endmodule
