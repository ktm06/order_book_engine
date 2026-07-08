`timescale 1ns/1ps

module TF_Bid_Comparator();
    logic v0, v1, v2, v3;
    logic p0, p1, p2, p3;
    logic [1:0] best_bid_num;
    logic [31:0] best_bid_price;
    logic valid_best_bid;
    
    module Bid_Comparator uut (
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

