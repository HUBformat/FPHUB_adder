`timescale 1ns / 1ps

module LZD #(
  parameter M = 23,                       // Default width of mantissa
  parameter extra_bits_mantissa = 7,       // Number of extra bits for the mantissa
  parameter sign_mantissa_bit = 1,         // Sign bit of the mantissa
  parameter SHIFT_WIDTH = $clog2(M+extra_bits_mantissa-sign_mantissa_bit-1)     // Width of shift count output
)(
  input  logic [M+extra_bits_mantissa-sign_mantissa_bit-1:0] A,                 // Input A
  input  logic [M+extra_bits_mantissa-sign_mantissa_bit-1:0] B,                 // Input B
  output logic [SHIFT_WIDTH-1:0] shift_amt // Number of leading zeros
);

  // Compute the difference A - B
  logic [M+extra_bits_mantissa-sign_mantissa_bit-1:0] subtraction;
  assign subtraction = A - B;

  // Leading Zero Detection
  function automatic [SHIFT_WIDTH-1:0] count_leading_zeros(input logic [M+extra_bits_mantissa-sign_mantissa_bit-1:0] value);
    integer i;
    begin
      count_leading_zeros = 0;
      for (i = M+extra_bits_mantissa-sign_mantissa_bit-1; i >= 0; i = i - 1) begin
        if (value[i] == 1'b1) begin
          count_leading_zeros = M+extra_bits_mantissa-sign_mantissa_bit-1 - i;
          break;
        end
      end
    end
  endfunction

  always_comb begin
    shift_amt = count_leading_zeros(subtraction);
  end

endmodule