`timescale 1ns / 1ps

module Exponent_difference #(
    parameter int E = 8            // Size of Mantissa
)(
    input logic [E-1:0] Ex,
    input logic [E-1:0] Ey,
    output logic signed [E:0] dif,
    output logic X_greater_than_Y
    );

always_comb begin
    dif = {1'b0, Ex} - {1'b0, Ey};
    
    X_greater_than_Y = (dif >= 0);
end
endmodule