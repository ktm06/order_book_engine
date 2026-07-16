`timescale 1ns/1ps

module TF_Ask_Comparator();
    logic v0, v1, v2, v3;
    logic [31:0] p0, p1, p2, p3;
    logic [1:0] best_ask;
    logic [31:0] ask_price;
    logic validout;

    Ask_Comparator uut (
        .v0(v0),
        .v1(v1),
        .v2(v2),
        .v3(v3),
        .p0(p0),
        .p1(p1),
        .p2(p2),
        .p3(p3),
        .best_ask(best_ask),
        .ask_price(ask_price),
        .validout(validout)
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
        if (best_ask === 2'b00 && ask_price === 32'h0000000A && validout === 1'b1) begin
            $display("PASS: All valid test");
        end else begin
            $display("FAIL: best_ask- %h, ask_price: %h, validout: %h", best_ask, ask_price, validout);
        end
        // v0 invalid test
        v0 = 1'b0;
        v1 = 1'b1; 
        v2 = 1'b1;
        v3 = 1'b1;
        p0 = 32'h0000000A;
        p1 = 32'h0000000B;
        p2 = 32'h0000000C;
        p3 = 32'h0000000D;
        #50;
        if (best_ask === 2'b01 && ask_price === 32'h0000000B && validout === 1'b1) begin
            $display("PASS: v0 invalid test");
        end else begin
            $display("FAIL: best_ask- %h, ask_price: %h, validout: %h", best_ask, ask_price, validout);
        end
        // all invalid test
        v0 = 1'b0;
        v1 = 1'b0;
        v2 = 1'b0;
        v3 = 1'b0;
        p0 = 32'h0000000A;
        p1 = 32'h0000000B;
        p2 = 32'h0000000C;
        p3 = 32'h0000000D;
        #50;
        if (validout === 1'b0) begin
            $display("PASS: all invalid test");
        end else begin
            $display("FAIL: best_ask- %h, ask_price: %h, validout: %h", best_ask, ask_price, validout);
        end
    end
endmodule