`timescale 1ps/1ps

module compare_mantissas #(
    parameter M = 23       // Size of the mantissas (including the implicit 1. That is to say, the mantissa is unpackaged as the form "1.M")
)(
    input logic [M:0] Mx,             // Input X (1 bit: Sx [E+M]; 8 bits: Ex [E+M-1:M]; 24 bits: Mx [M-1:0]) 
    input logic [M:0] My,             // Input Y (same structure as X)
    output logic Mx_greater_than_My     /* Flag indicating if the mantissa of X is greater than the mantissa of Y
                                        Mx_greater_than_My = 1 if Mx > My, 0 otherwise*/
);

always_comb begin
    Mx_greater_than_My = (Mx > My) ? 1'b1 : 1'b0;
end

endmodule