`timescale 1ns/1ps

module Bid_Comparator 
 (
	// v is for the validity of the bit
	input logic v0,
	input logic v1,
	input logic v2, 
	input logic v3,
	input logic [31:0] p0,
	input logic [31:0] p1,
	input logic [31:0] p2,
	input logic [31:0] p3,
	output logic [1:0] best_bid_num,
	output logic [31:0] best_bid_price,
	output logic valid_best_bid
);
logic [31:0] price1;
logic [31:0] price2;
always_comb begin
	if (v0 & v1) begin
		price1 = (p0 > p1) ? p0 : p1;
	end else if (v0) begin
		price1 = p0;
	end else if (v1) begin
		price1 = p1;
	end else begin
		price1 = 32'b0;
	end
	if (v2 & v3) begin
		price2 = (p2 > p3) ? p2 : p3;
	end else if (v2) begin
		price2 = p2;
	end else if (v3) begin
		price2 = p3;
	end else begin
		price2 = 32'b0;
	end
	best_bid_price = (price1 > price2) ? price1 : price2;
	if (v0 && best_bid_price == p0) begin
	best_bid_num = 2'b00;
	end else if (v1 && best_bid_price == p1) begin
		best_bid_num = 2'b01;
	end else if (v2 && best_bid_price == p2) begin
		best_bid_num = 2'b10;
	end else if (v3 && best_bid_price == p3) begin
		best_bid_num = 2'b11;
	end else begin
		best_bid_num = 2'b00;
	end
    valid_best_bid = v0 | v1 | v2 | v3;
end

endmodule