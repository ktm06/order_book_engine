`timescale 1ns/1ps

module Ask_Comparator (
    input v0,
    input v1,
    input v2,
    input v3,
    input logic[31:0] p0,
    input logic[31:0] p1,
    input logic[31:0] p2,
    input logic[31:0] p3,
    output logic [1:0]best_ask,
    output logic [31:0] ask_price,
    output logic validout
);

logic [31:0] m0;
logic [31:0] m1;
logic [31:0] m2;
logic [31:0] m3;
logic [31:0] loser1;
logic [31:0] loser2;

always_comb begin
    if (~v0) m0 = 32'hFFFFFFFF;
    else m0 = p0;
    if (~v1) m1 = 32'hFFFFFFFF;
    else m1 =p1;
    if (~v2) m2 = 32'hFFFFFFFF;
    else m2=p2;
    if (~v3) m3 = 32'hFFFFFFFF;
    else m3=p3;

    loser1 = m0 < m1 ? m0 : m1;
    loser2 = m2 < m3 ? m2 : m3;

    if (v0 | v1 | v2 | v3) begin
        ask_price = loser1 < loser2 ? loser1 : loser2;
        validout = 1'b1;
        if (ask_price === m0) best_ask = 2'b00;
        else if (ask_price === m1) best_ask = 2'b01;
        else if (ask_price === m2) best_ask = 2'b10;
        else if (ask_price === m3) best_ask = 2'b11;
        else best_ask = 2'b00; //default
    end else begin
        validout = 1'b0;
        ask_price = 32'hFFFFFFFF;
        best_ask = 2'b00;
        end
end

endmodule