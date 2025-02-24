`timescale 1ps/1ps

module shifter #(
    parameter int M = 24,                       // Size of the mantissa
    parameter int E = 8                         // Size of the exponent
) ( 
    input logic [M+1:0] number_input,           // Input X (1 bit: Sx [E+M]; 8 bits: Ex [E+M-1:M]; 23 bits: Mx [M-1:0]) 
    input logic [E:0] shift_amount,            /* Shift ammount (this input is the difference between the exponents of X and Y 
                                                in two's complement representation) */
    input logic right_shift,                    // Right shift flag (1: right shift; 0: left shift)
    input logic arithmetic_shift,               // Arithmetic shift flag (1: arithmetic shift; 0: logical shift)
    output logic [M+1:0] number_output          // Output Z (same structure as X)
);

// Because the shift ammount is in two's complement representation, the shift ammount must be in absolute value
//logic [E:0] shift_amount_abs;                           // Absolute value of the shift ammount

always_comb begin
    // Getting the absolute value of the shift ammount
    //shift_amount_abs = (shift_amount < 0 ) ? -shift_amount : shift_amount;

    // Shift operation
    if (!right_shift)   // Left shift
        number_output = number_input << shift_amount;
    else if (right_shift && arithmetic_shift)   // Right arithmetic shift
        number_output = number_input >>> shift_amount;
    else    // Right logical shift
        number_output = number_input >> shift_amount;
end
endmodule