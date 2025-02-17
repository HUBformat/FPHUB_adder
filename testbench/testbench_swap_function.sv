`timescale 1ns / 1ps

module testbench_swap_function();
parameter int M = 24;
parameter int E = 8;

logic [E+M:0] X;
logic [E+M:0] Y;
logic [E+M:0] Z;

my_FPHUB_adder #(M,E) DUT (
    .X(X),
    .Y(Y),
    .Z(Z)
);

initial begin
    // First test: X > Y (X = 3.0; Y = 5.0)
    X = 32'b01000000110000000000000000000000;
    Y = 32'b01000001001000000000000000000000;
    #10;
    $display("X = %b", X);
    $display("Y = %b", Y);
    $display("Z = %b", Z);

    // Second test: X < Y (X = 5.0; Y = 3.0)
    X = 32'b01000001001000000000000000000000;
    Y = 32'b01000000110000000000000000000000;
    #10;
    $display("X = %b", X);
    $display("Y = %b", Y);
    $display("Z = %b", Z);

    // Third test: X = Y (X = 3.0; Y = 3.0)
    X = 32'b01000000110000000000000000000000;
    Y = 32'b01000000110000000000000000000000;
    #10;
    $display("X = %b", X);
    $display("Y = %b", Y);
    $display("Z = %b", Z);
end

endmodule