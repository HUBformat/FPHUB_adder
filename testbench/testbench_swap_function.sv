`timescale 1ns / 1ps

module testbench_swap_function();
parameter int M = 24;
parameter int E = 8;

logic [M+E-1:0] X;
logic [M+E-1:0] Y;
logic [M+E-1:0] Z;

my_FPHUB_adder #(M,E) DUT (
    .X(X),
    .Y(Y),
    .Z(Z)
);

initial begin
    // First test: X > Y (X = 3.0; Y = 5.0)
    X = 33'b010000001110000000000000000000000;
    Y = 33'b010000010101000000000000000000000;
    #10;

    // Second test: X < Y (X = 5.0; Y = 3.0)
    X = 33'b010000010101000000000000000000000;
    Y = 33'b010000001110000000000000000000000;
    #10;

    // Third test: X = Y (X = 3.0; Y = 3.0)
    X = 33'b010000001110000000000000000000000;
    Y = 33'b010000001110000000000000000000000;
    #10;
end
endmodule