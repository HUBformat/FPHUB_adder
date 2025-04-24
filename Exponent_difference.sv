/* Module: Exponent_difference

 Summary:
     Computes the signed difference between two unsigned exponents Ex and Ey.
     Also determines whether Ex is greater than Ey and whether they are equal.

 Parameters:
     E -  Width of the exponent (in bits).

 Ports:
     Ex - Exponent from operand X (E bits).
     Ey - Exponent from operand Y (E bits).
     dif - Signed difference between Ex and Ey (E+1 bits).
     X_greater_than_Y - High if Ex >= Ey.
     Ex_equal_Ey - High if Ex == Ey.
 */
module Exponent_difference #(
    parameter int E = 8            // Size of Mantissa
)(
    input logic [E-1:0] Ex,
    input logic [E-1:0] Ey,
    output logic signed [E:0] dif,
    output logic X_greater_than_Y,
    output logic Ex_equal_Ey
);

/**
Section: Exponent comparison

This block performs a comparison between two unsigned exponents (Ex and Ey)
by subtracting them after zero-extending each to E+1 bits. This avoids overflow
and ensures that the result *dif* is interpreted correctly as a signed number,
capable of representing both positive and negative differences.

Two flags are generated alongside:

- *X_greater_than_Y* is set when Ex is greater than or equal to Ey.
- *Ex_equal_Ey* is set when both exponents are exactly equal.

These outputs are critical for determining mantissa alignment in floating-point operations,
as well as for selecting the sign and exponent of the resulting number.
*/
always_comb begin
    dif = {1'b0, Ex} - {1'b0, Ey};
    
    X_greater_than_Y = (dif >= 0);
    Ex_equal_Ey = (dif == 0);
end

endmodule
