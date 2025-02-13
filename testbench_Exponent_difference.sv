`timescale 1ns / 1ps

module testbench_insert_ILSB();
parameter int E = 8;

logic [E-1:0] Ex;
logic [E-1:0] Ey;
logic signed [E:0] dif;
logic X_greater_than_Y;

Exponent_difference #(E) dut (
    .Ex(Ex),
    .Ey(Ey),
    .dif(dif),
    .X_greater_than_Y(X_greater_than_Y)
);

initial begin

// First test: Ex > Ey
Ex = 8'b00001101;
Ey = 8'b00000111;
#10;
$display("Ex = %d, Ey = %d -> dif = %d (%b), X_greater_than_Y = %b", Ex, Ey, dif, dif, X_greater_than_Y);

// Second test: Ex < Ey
Ex = 8'b00000111;
Ey = 8'b00001101;
#10;
$display("Ex = %d, Ey = %d -> dif = %d (%b), X_greater_than_Y = %b", Ex, Ey, dif, dif, X_greater_than_Y);

// Third test: Ex = Ey
Ex = 8'b00001101;
Ey = 8'b00001101;
#10;
$display("Ex = %d, Ey = %d -> dif = %d (%b), X_greater_than_Y = %b", Ex, Ey, dif, dif, X_greater_than_Y);

end

endmodule