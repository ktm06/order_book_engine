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
	input CLK,
	input RESET
);

logic [63:0] ask_buffer [0:3]; // stores 4  8 byte messages. message format [63:32] price [31:0] size
logic [63:0] bid_buffer [0:3];
logic [1:0] ask_count;
logic [1:0] bid_count;

logic validask0, validask1, validask2, validask3;
logic validbid0, validbid1, validbid2, validbid3;
logic [1:0] best_bid_num, best_ask_num;
logic [31:0] best_bid_price, best_ask_price;

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

Bid_Compare Bid_Comparator (
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
	.validout(bidready)
)

Ask_Compare Ask_Comparator (
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
)


// when the buffers r full we need a way to kick out the "worst" 
// contents so we can add new vals. we just reuse the comparators
// to achieve this
Lowest_Bid_Finder Ask_Comparator (
	.v0(1'b1),
	.v1(1'b1),
	.v2(1'b1),
	.v3(1'b1),
	.p0(bid_buffer[0][63:32]),
	.p1(bid_buffer[1][63:32]),
	.p2(bid_buffer[2][63:32]),
	.p3(bid_buffer[3][63:32]),
	.best_ask(lowestbidpos),
	.best_bid_num(),
	.validout()
)

Highest_Ask_Finder Bid_Comparator (
	.v0(1'b1),
	.v1(1'b1),
	.v2(1'b1),
	.v3(1'b1),
	.p0(ask_buffer[0][63:32]),
	.p1(ask_buffer[1][63:32]),
	.p2(ask_buffer[2][63:32]),
	.p3(ask_buffer[3][63:32]),
	.best_bid_val(highestaskpos),
	.best_bid_price(),
	.validout()

)

always_comb begin  // evaluate spread
	if (bidready & askready) begin
		best_spread = best_ask_price - best_bid_price;
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


logic [2:0] tempfind; // we will use this for find_price func in alwaysff block
logic [31:0] tempsize; // for capping sum at 4 bytes
function automatic logic [1:0] find_price(
	input logic [31:0] inprice,
	input logic [63:0] buffer [0:3]
);
	// [2:0] return type. [1:0] will be the position where we found 
	// the type, and [2] will be 1 if found, 0 if not found
	for (int i = 0; i < 4; i++) begin
		if (buffer[i][63:32] == inprice) begin
			return {1'b1, 2'i};
		end else begin
			return 3'b0;
		end
	end
endfunction

State_t State;


always_ff @(posedge CLK, RESET) begin
	if (RESET) begin
		ask_buffer <= '0;
		bid_buffer <= '0;
		State <= S0;
		curr_price <= '0;
		curr_size <= '0;
		curr_side <= '0;
		curr_msgtype <= '0;
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
				end
			S1: begin
				if (curr_msgtype = 8'h01) begin
					State <= S2; // add
				end else if (curr_msgtype = 8'h02) begin
					State <= S3;
				end else if (curr_msgtype = 8'h03) begin
					State <= S4;
				end else begin
					State <= S0;
				end
			S2: begin
				if (current_side = 8'h0) begin // Ask
					tempfind <= find_price(curr_price, ask_buffer);
					if (tempfind[2] == 1'b0) begin // not found so add
						if ask_count < 4 begin
							ask_buffer[ask_count] <= {curr_price, curr_size};
							ask_count <= ask_count + 1;
						end else begin // drop high with bid comparator
							ask_buffer[highestaskpos] <= {curr_price, curr_size};
						end
					end else begin // append to existing
						tempsize <= ((ask_buffer[tempfind[1:0]][31:0] + curr_size) > 32'hFFFFFFFF ? 32'hFFFFFFFF :
							ask_buffer[tempfind[1:0]][31:0] + curr_size);
						ask_buffer[tempfind[1:0]] <= {curr_price, tempsize};
					end
					State <= S0;
				end else if (current_side = 8'h1) begin // Bid
					tempfind <= find_price(curr_price, bid_buffer);
					if (tempfind[2] == 1'b0) begin
						if bid_count < 4 begin
							bid_buffer[bid_count] <= {curr_price, curr_size};
							bid_count <= bid_count + 1;
						end else begin // drop low with ask comparator
							bid_buffer[lowestbidpos] <= {curr_price, curr_size};
						end
					end else begin 
						tempsize <= ((bid_buffer[tempfind[1:0]][31:0] + curr_size) > 32'hFFFFFFFF ? 32'hFFFFFFFF :
							bid_buffer[tempfind[1:0]][31:0] + curr_size);
						bid_buffer[tempfind[1:0]] <= {curr_price, tempsize};
					end
					State <= S0;
				end else begin 
					// TODO err case for now do nothing
					State <= S0;
				end
			end 
			S3: begin
				if (current_side = 8'h0) begin //ask
					tempfind <= find_price(curr_price, ask_buffer);
					if (tempfind[2] == 1'b1) begin
						ask_buffer[tempfind[1:0]] <= ((ask_buffer[tempfind[1:0]][31:0] - curr_size) < 32'b0 ? 32'b0 
						: ask_buffer[tempfind[1:0]][31:0] - curr_size);
						State <= S0;
					end else begin
						// TODO err case for now do nothing
						State <= S0;
					end
				end else if (current_side = 8'h1) begin // bid
					tempfind <= find_price(curr_price, bid_buffer);
					if (tempfind[2] == 1'b1) begin
						bid_buffer[tempfind[1:0]] <= ((bid_buffer[tempfind[1:0]][31:0] - curr_size) < 32'b0 ? 32'b0 
						: bid_buffer[tempfind[1:0]][31:0] - curr_size);
						State <= S0;
					end else begin
						// TODO err case for now do nothing
						State <= S0;
					end
				end else begin 
					// TODO err case for now do nothing
					State <= S0;
				end
			end

		endcase
	end
endmodule

					

						