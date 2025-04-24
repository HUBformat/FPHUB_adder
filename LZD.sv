/**
 Module: LZD

 Summary:
     Computes the number of leading zeros in a mantissa-like input,
     used to normalize floating-point numbers.

 Parameters:
     M - Width of the mantissa.
     extra_bits_mantissa - Additional bits used in mantissa processing.
     sign_mantissa_bit - Number of sign bits in mantissa (typically 1).
     SHIFT_WIDTH - Width of the output shift count.

 Ports:
     A - Input vector from which to count leading zeros.
     print - Debug signal (currently unused).
     shift_amt - Number of leading zeros in A.
 */
 module LZD #(
  parameter M = 23,
  parameter extra_bits_mantissa = 7,
  parameter sign_mantissa_bit = 1,
  parameter SHIFT_WIDTH = $clog2(M+extra_bits_mantissa-sign_mantissa_bit-1)
)(
  input  logic [M+extra_bits_mantissa-sign_mantissa_bit-1:0] A,
  output logic [SHIFT_WIDTH:0] shift_amt,
  input logic print
);

/**
 Function: count_leading_zeros

 Summary:
    This function performs a leading zero count on the input signal *'A'*,
    which typically represents an unnormalized mantissa after arithmetic operations.

    The loop starts from the most significant bit and stops at the first '1',
    returning the count of leading zeros from the top bit down to that position.

    If the entire input is zero, a special flag value is returned:
    the MSB of 'shift_amt' is set to 1 and the rest to 0. This indicates
    a fully zero input and may be used downstream to flag underflow or to skip normalization.

    This function is purely combinational and used to drive 'shift_amt'.
  
  Parameters:
    value - Input vector from which to count leading zeros.

  Returns:
    count_leading_zeros - Number of leading zeros in the input vector.
    If all bits are zero, returns a special flag value with MSB set to 1.
 */
function automatic [SHIFT_WIDTH:0] count_leading_zeros(
  input logic [M+extra_bits_mantissa-sign_mantissa_bit-1:0] value
);
  integer i;
  begin
    count_leading_zeros = 0;
    for (i = M+extra_bits_mantissa-sign_mantissa_bit-1; i >= 0; i = i - 1) begin
      if (value[i] == 1'b1) begin
        count_leading_zeros = M+extra_bits_mantissa-sign_mantissa_bit-1 - i;
        break;
      end
      if (i == 0 && count_leading_zeros == 0) begin
        count_leading_zeros = {1'b1, {SHIFT_WIDTH{1'b0}}};  // Special flag: input is all zero
      end
    end
  end
endfunction

assign shift_amt = count_leading_zeros(A);

endmodule
