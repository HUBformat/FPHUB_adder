module my_FPHUB_adder #(
    parameter M = 24,       // Size of the mantissas (including the implicit 1. That is to say, the mantissa is unpackaged as the form "1.M")
    parameter E = 8         // Size of the exponent
)(
    input wire [E+M:0] X,   // Input X (1 bit: Sx [E+M]; 8 bits: Ex [E+M-1:M]; 24 bits: Mx [M-1:0]) 
    input wire [E+M:0] Y,   // Input Y (same structure as X)
    output wire [E+M:0] Z   // Output Z (same structure as X)
);

//--------------------------------------------------------------------------------------------------
// Calculus of the difference between the exponents of X and Y
//--------------------------------------------------------------------------------------------------
logic [E:0] diff;           // Difference between the exponents, considering the sign bit in two's complement representation
logic X_greater_than_Y;     // Flag indicating if the exponent of X is greater than the exponent of Y
                            // X_greater_than_Y = 1 if Ex > Ey, 0 otherwise

// "Exponent_difference" module call
Exponent_difference #(
    .E(E)
) Exponent_difference_inst (
    .Ex(X[E+M-1:M]),
    .Ey(Y[E+M-1:M]),
    .dif(diff),
    .X_greater_than_Y(X_greater_than_Y)
);

//--------------------------------------------------------------------------------------------------
// In this module the mantissas are ordered according to the X_greater_than_Y flag. The minor 
// mantissa is shifted to the right to align the exponents according to the difference between
// the exponents.
//--------------------------------------------------------------------------------------------------

logic [M-1:0] Mx = (X_greater_than_Y) ? X[M-1:0] : Y[M-1:0];      // Mx = X if X > Y, Y otherwise
logic [M-1:0] My = (X_greater_than_Y) ? Y[M-1:0] : X[M-1:0];      // My = Y if X > Y, X otherwise

logic [E-1:0] Ez = (X_greater_than_Y) ? X[E+M-1:M] : Y[E+M-1:M];  // Ez = Ex if X > Y, Ey otherwise

initial begin
    $display("X = %b", X);
    $display("Y = %b", Y);
    $display("My = %b", My);
    $display("Mx = %b", Mx);
    $display("Ez = %b", Ez);
end

endmodule