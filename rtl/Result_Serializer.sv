`timescale 1ns/1ps

module Result_Serializer (
    input [31:0] spread_in,
    input inready,
    output logic [7:0] TX_DATA,
    output logic TX_SEND,
    input logic TX_DONE,
    input logic CLK,
    input logic RESET
);

logic [4:0] State; 
logic [31:0] curr_spread;
localparam [4:0]
S0 = 5'b00001,
S1 = 5'b00010,
S2 = 5'b00100,
S3 = 5'b01000,
S4 = 5'b10000;

always_ff @(posedge CLK, posedge RESET) begin
    if (RESET) begin
         TX_DATA <= '0;
         TX_SEND <= '0;
         State <= S0;
    end else begin
        case (State) 
            S0: begin
                if (inready) begin
                    curr_spread <= spread_in;
                    State <= S1;
                    TX_SEND <= 1'b0;
                end else begin
                    State <= S0;
                    TX_SEND <= 1'b0;
                end
            end
            S1: begin
                TX_DATA <= curr_spread[31:24];
                TX_SEND <= 1'b1;
                if (TX_DONE) begin
                    TX_SEND <= 1'b0;
                    State <= S2;
                end
            end
            S2: begin
                TX_DATA <= curr_spread[23:16];
                TX_SEND <= 1'b1;
                if (TX_DONE) begin
                    TX_SEND <= 1'b0;
                    State <= S3;
                end
            end
            S3: begin
                TX_DATA <= curr_spread[15:8];
                TX_SEND <= 1'b1;
                if (TX_DONE) begin
                    TX_SEND <= 1'b0;
                    State <= S4;
                end
            end
            S4: begin
                TX_DATA <= curr_spread[7:0];
                TX_SEND <= 1'b1;
                if (TX_DONE) begin
                    TX_SEND <= 1'b0;
                    State <= S0;
                end
            end
        endcase
    end
end



endmodule