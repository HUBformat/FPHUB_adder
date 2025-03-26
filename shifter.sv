`timescale 1ps/1ps

module shifter #(
    parameter int M = 23,                       // Size of the mantissa
    parameter int E = 8,                        // Size of the exponent
    parameter int extra_bits_mantissa = 7       // Number of extra bits for the mantissa
) ( 
    input logic signed [M+extra_bits_mantissa-1:0] number_input,           // Input X (1 bit: Sx [E+M]; 8 bits: Ex [E+M-1:M]; 23 bits: Mx [M-1:0]) 
    input logic [E:0] shift_amount,            /* Shift ammount (this input is the difference between the exponents of X and Y 
                                                in two's complement representation) */
    input logic right_shift,                    // Right shift flag (1: right shift; 0: left shift)
    input logic arithmetic_shift,               // Arithmetic shift flag (1: arithmetic shift; 0: logical shift)
    output logic [M+extra_bits_mantissa-1:0] number_output,          // Output Z (same structure as X)
    input logic print
);

logic [M+extra_bits_mantissa-1:0] number_shifted;

// Because the shift ammount is in two's complement representation, the shift ammount must be in absolute value
//logic [E:0] shift_amount_abs;                           // Absolute value of the shift ammount

always_comb begin
    // Getting the absolute value of the shift ammount
    //shift_amount_abs = (shift_amount < 0 ) ? -shift_amount : shift_amount;
    // Shift operation
    if (right_shift == 1'b0)   // Left shift
        number_shifted = number_input << shift_amount;
    else if (right_shift == 1'b1 && arithmetic_shift == 1'b1)   // Right arithmetic shift
        number_shifted = number_input >>> shift_amount;
    else    // Right logical shift
        number_shifted = number_input >> shift_amount;
//    if (print) begin
//        $display("SHIFTER: number_input = %b, shift_amount = %d (%b) number_output = %b", number_input, shift_amount, shift_amount, number_shifted);
//    end
end

assign number_output = number_shifted;
endmodule