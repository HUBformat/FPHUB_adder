/**
 Module: shifter

 Summary:
     Performs a configurable left or right shift on a signed input number.
     Supports both logical and arithmetic shifting based on control flags.

 Parameters:
     M - Width of the mantissa.
     E - Width of the exponent.
     extra_bits_mantissa - Extra bits used for intermediate mantissa operations.

 Ports:
     number_input - Operand to be shifted (signed).
     shift_amount - Shift amount in two's complement (E+1 bits).
     right_shift - Shift direction control: 1 = right, 0 = left.
     arithmetic_shift - Shift type control: 1 = arithmetic, 0 = logical.
     print - Debug print control (currently unused).
     number_output - Shifted result.
 */
module shifter #(
    parameter int M = 23,
    parameter int E = 8,
    parameter int extra_bits_mantissa = 7
) ( 
    input logic signed [M+extra_bits_mantissa-1:0] number_input,
    input logic [E:0] shift_amount,
    input logic right_shift,
    input logic arithmetic_shift,
    output logic [M+extra_bits_mantissa-1:0] number_output,
    input logic print
);

logic [M+extra_bits_mantissa-1:0] number_shifted;

/*
Section: Shift logic

Implements directional shifting of a signed input operand based on two control flags:

- If *right_shift* is 0, the input is shifted to the left.
- If *right_shift* is 1 and *arithmetic_shift* is 1, a signed (arithmetic) right shift is performed.
- Otherwise, a logical (unsigned) right shift is used.

This logic allows dynamic selection between left/right and logical/arithmetic shifting,
supporting normalization, alignment, and rounding operations in floating-point units.
*/
always_comb begin
    // Left shift
    if (right_shift == 1'b0)                      
        number_shifted = number_input << shift_amount;
    // Right shift
    else if (right_shift == 1'b1 && arithmetic_shift == 1'b1)   
        number_shifted = number_input >>> shift_amount;
    // Right logical shift
    else                                          
        number_shifted = number_input >> shift_amount;
end

assign number_output = number_shifted;

endmodule
