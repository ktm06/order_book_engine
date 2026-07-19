`timescale 1ns/1ps

module Order_Book_Engine
#(
	parameter CLK_RATE_HZ = 50000000
) (
	input [31:0] price,
	input [31:0] size,
	input [7:0] side,
	input [7:0] msgtype,
	input inready,
	output logic [31:0] best_spread, 
	output logic outready,
	output logic busy,
	input CLK,
	input RESET
);

logic [63:0] ask_buffer [0:3]; // stores 4  8 byte messages. message format [63:32] price [31:0] size
logic [63:0] bid_buffer [0:3];
logic [2:0] ask_count;
logic [2:0] bid_count;

logic validask0, validask1, validask2, validask3;
logic validbid0, validbid1, validbid2, validbid3;
logic [1:0] best_bid_num, best_ask_num;
logic [31:0] best_bid_price, best_ask_price;
logic [31:0] highest_curr_ask, lowest_curr_bid;

logic bidready, askready;

logic [1:0] lowestbidpos, highestaskpos;

always_comb begin // check for valid stored based on contents of buffer
	validask0 = (ask_buffer[0] == 64'b0 ? 1'b0 : 1'b1);
	validask1 = (ask_buffer[1] == 64'b0 ? 1'b0 : 1'b1);
	validask2 = (ask_buffer[2] == 64'b0 ? 1'b0 : 1'b1);
	validask3 = (ask_buffer[3] == 64'b0 ? 1'b0 : 1'b1);
	validbid0 = (bid_buffer[0] == 64'b0 ? 1'b0 : 1'b1);
	validbid1 = (bid_buffer[1] == 64'b0 ? 1'b0 : 1'b1);
	validbid2 = (bid_buffer[2] == 64'b0 ? 1'b0 : 1'b1);
	validbid3 = (bid_buffer[3] == 64'b0 ? 1'b0 : 1'b1);
end

Bid_Comparator Bid_Compare  (
	.v0(validbid0),
	.v1(validbid1),
	.v2(validbid2),
	.v3(validbid3),
	.p0(bid_buffer[0][63:32]),
	.p1(bid_buffer[1][63:32]),
	.p2(bid_buffer[2][63:32]),
	.p3(bid_buffer[3][63:32]),
	.best_bid_num(best_bid_num),
	.best_bid_price(best_bid_price),
	.valid_best_bid(bidready)
);

Ask_Comparator Ask_Compare (
	.v0(validask0),
	.v1(validask1),
	.v2(validask2),
	.v3(validask3),
	.p0(ask_buffer[0][63:32]),
	.p1(ask_buffer[1][63:32]),
	.p2(ask_buffer[2][63:32]),
	.p3(ask_buffer[3][63:32]),
	.best_ask(best_ask_num),
	.ask_price(best_ask_price),
	.validout(askready)
);


// when the buffers r full we need a way to kick out the "worst" 
// contents so we can add new vals. we just reuse the comparators
// to achieve this
Ask_Comparator Lowest_Bid_Finder (
	.v0(validbid0),
	.v1(validbid1),
	.v2(validbid2),
	.v3(validbid3),
	.p0(bid_buffer[0][63:32]),
	.p1(bid_buffer[1][63:32]),
	.p2(bid_buffer[2][63:32]),
	.p3(bid_buffer[3][63:32]),
	.best_ask(lowestbidpos),
	.ask_price(lowest_curr_bid),
	.validout()
);

Bid_Comparator Highest_Ask_Finder (
	.v0(validask0),
	.v1(validask1),
	.v2(validask2),
	.v3(validask3),
	.p0(ask_buffer[0][63:32]),
	.p1(ask_buffer[1][63:32]),
	.p2(ask_buffer[2][63:32]),
	.p3(ask_buffer[3][63:32]),
	.best_bid_num(highestaskpos),
	.best_bid_price(highest_curr_ask),
	.valid_best_bid()

);

always_comb begin  // evaluate spread
	if (bidready & askready) begin
		if (best_ask_price >= best_bid_price)
			best_spread = best_ask_price - best_bid_price;
		else
			best_spread = best_bid_price - best_ask_price;
	end else begin
		best_spread = 32'b0;
	end
end

logic [31:0] curr_price;
logic [31:0] curr_size;
logic [7:0] curr_side;
logic [7:0] curr_msgtype;

typedef enum logic [4:0] {
	S0 = 5'b00001, // IDLE
	S1 = 5'b00010, // DECODING
	S2 = 5'b00100, //ADD
	S3 = 5'b01000, //DEL
	S4 = 5'b10000 //MOD
} State_t;



function automatic logic [2:0] find_price(
	input logic [31:0] inprice,
	input logic [63:0] buffer [0:3]
);
	// [2:0] return type. [1:0] will be the position where we found 
	// the type, and [2] will be 1 if found, 0 if not found
	for (int i = 0; i < 4; i++) begin
		if (buffer[i] != 64'b0 && buffer[i][63:32] == inprice) begin
			return {1'b1, i[1:0]};
		end 
	end
	return 3'b0;
endfunction

function automatic logic [2:0] find_total_valids(
	input logic [63:0] buffer [0:3]
);
	logic [2:0] count;
	count = 3'b0;
	for (int i = 0; i < 4; i++) begin
		if (buffer[i] != 64'b0) begin
			count = count + 1;
		end
	end
	return count;
endfunction

logic [2:0] bid_find, ask_find; 
logic [31:0] ask_size, bid_size;
logic [31:0] sumask, sumbid;
assign ask_find = find_price(curr_price, ask_buffer);
assign bid_find = find_price(curr_price, bid_buffer);
assign ask_size = (ask_find[2] == 1'b1 ? ask_buffer[ask_find[1:0]][31:0] : 32'b0);
assign bid_size = (bid_find[2] == 1'b1 ? bid_buffer[bid_find[1:0]][31:0] : 32'b0);
assign ask_count = find_total_valids(ask_buffer);
assign bid_count = find_total_valids(bid_buffer);

State_t State;

assign busy = (State != S0); //For TopLevel - do not input when busy
always_ff @(posedge CLK, posedge RESET) begin
	if (RESET) begin
		for (int i = 0; i < 4; i++) begin
			bid_buffer[i] <= '0;
			ask_buffer[i] <= '0;
		end
		State <= S0;
		curr_price <= '0;
		curr_size <= '0;
		curr_side <= '0;
		curr_msgtype <= '0;
		outready <= 1'b0;
	end else begin
		case (State)
			S0: begin
				if (inready) begin
					curr_price <= price;
					curr_size <= size;
					curr_side<=side;
					curr_msgtype<=msgtype;
					State <= S1;
				end else begin
					State <= S0;
				outready <= 1'b0;
				end
			end
			S1: begin
				if (curr_msgtype == 8'h01) begin
					State <= S2; // add
				end else if (curr_msgtype == 8'h02) begin
					State <= S3;
				end else if (curr_msgtype == 8'h03) begin
					State <= S4;
				end else begin
					State <= S0;
				end
			end
			S2: begin // add
				if (curr_side == 8'h0) begin // Ask
					if (ask_find[2] == 1'b0) begin // not found so add
						if (ask_count < 4) begin
							for (int i = 0; i < 4; i++) begin
								if (ask_buffer[i] == 64'b0) begin
									ask_buffer[i] <= {curr_price, curr_size};
									break;
								end
							end
						end else begin // drop high with bid comparator
							if (curr_price < highest_curr_ask) ask_buffer[highestaskpos] <= {curr_price, curr_size};
						end
					end else begin // append to existing
						ask_buffer[ask_find[1:0]][31:0] <= ask_buffer[ask_find[1:0]][31:0] + curr_size; // we assume we dont approach 4.3 billion shares
					end
					State <= S0;
					outready <= 1'b1;
				end else if (curr_side == 8'h1) begin // Bid
					if (bid_find[2] == 1'b0) begin
						if (bid_count < 4) begin
							for (int i = 0; i < 4; i++) begin
								if (bid_buffer[i] == 64'b0) begin 
									bid_buffer[i] <= {curr_price, curr_size};
									break;
								end
							end
							end else begin // drop low with ask comparator
							if (curr_price > lowest_curr_bid) bid_buffer[lowestbidpos] <= {curr_price, curr_size};
						end
					end else begin 
						bid_buffer[bid_find[1:0]][31:0] <= bid_buffer[bid_find[1:0]][31:0] + curr_size;
					end
					State <= S0;
					outready <= 1'b1;
				end else begin 
					// TODO err case for now do nothing
					State <= S0;
					outready <= 1'b1;
				end
			end 
			S3: begin // delete
				if (curr_side == 8'h0) begin //ask
					if (ask_find[2] == 1'b1) begin
						if (curr_size >= ask_buffer[ask_find[1:0]][31:0]) begin
							ask_buffer[ask_find[1:0]] <= 64'b0;
						end else begin 
							ask_buffer[ask_find[1:0]][31:0] <= ask_buffer[ask_find[1:0]][31:0] - curr_size;
						end 
						State <= S0;
						outready <= 1'b1;
					end else begin
						// TODO err case for now do nothing
						State <= S0;
						outready <= 1'b1;
					end
				end
					else if (curr_side == 8'h1) begin // bid
						if (bid_find[2] == 1'b1) begin
							if (curr_size >= bid_buffer[bid_find[1:0]][31:0]) begin
								bid_buffer[bid_find[1:0]] <= 64'b0;
							end else begin 
								bid_buffer[bid_find[1:0]][31:0] <= bid_buffer[bid_find[1:0]][31:0] - curr_size;
							end
						State <= S0;
						outready <= 1'b1;
					end else begin
						// TODO err case for now do nothing
						State <= S0;
						outready <= 1'b1;
					end
					end else begin 
					// TODO err case for now do nothing
					State <= S0;
					outready <= 1'b1; 
					end 
				
			end
			S4: begin //mod
				if (curr_side == 8'h0) begin // ask
					if (ask_find[2] == 1'b1) begin
						ask_buffer[ask_find[1:0]] <= {curr_price, curr_size};
						State <= S0;
						outready <= 1'b1;
					end else begin 
						// TODO 
						State <= S0;
						outready <= 1'b1;
					end
				end else if (curr_side == 8'h1) begin
					if(bid_find[2] == 1'b1) begin
						bid_buffer[bid_find[1:0]] <= {curr_price, curr_size};
						State <= S0;
						outready <= 1'b1;
					end else begin
						// TODO
						State <= S0;
						outready <= 1'b1;
					end
				end else begin
					// TODO
					State <= S0;
					outready <= 1'b1;
				end
			end
			default: State <= S0;
			endcase
			end
end

endmodule