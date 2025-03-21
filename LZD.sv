`timescale 1ns / 1ps

module LZD #(
  parameter M = 23,                        // Default width of mantissa
  parameter extra_bits_mantissa = 7,       // Number of extra bits for the mantissa
  parameter sign_mantissa_bit = 1,         // Sign bit of the mantissa
  parameter SHIFT_WIDTH = $clog2(M+extra_bits_mantissa-sign_mantissa_bit-1)  // Width of shift count output
)(
  input  logic [M+extra_bits_mantissa-sign_mantissa_bit-1:0] A,  // Input A
  input  logic [M+extra_bits_mantissa-sign_mantissa_bit-1:0] B,  // Input B
  output logic [SHIFT_WIDTH:0] shift_amt,                      // Number of leading zeros
  input logic print
);

  // Compute absolute difference |A - B|
  logic [M+extra_bits_mantissa-sign_mantissa_bit-1:0] subtraction;
  
  always_comb begin
    if (A >= B)
      subtraction = A - B;
    else
      subtraction = B - A;  // Se invierte la operación para evitar resultados negativos
      
//    if (A == 13'b1001010000000 && B == 13'b1000110000000) begin
    if (print) begin
        $display("LZD: A = %b y B = %b", A, B);
        $display("Resta: %b", subtraction);
        $display("extra_bits_mantissa = %d", extra_bits_mantissa);
        $display("SHIFT_WIDTH = %d", SHIFT_WIDTH);
    end  
  end

  // Leading Zero Detection
  function automatic [SHIFT_WIDTH:0] count_leading_zeros(input logic [M+extra_bits_mantissa-sign_mantissa_bit-1:0] value);
    integer i;
    begin
      count_leading_zeros = 0;
      for (i = M+extra_bits_mantissa-sign_mantissa_bit-1; i >= 0; i = i - 1) begin
        if (print) begin
           $display("Mz[%d] = %b", i, value[i]);
        end
        if (value[i] == 1'b1) begin
          count_leading_zeros = M+extra_bits_mantissa-sign_mantissa_bit-1 - i;
          if (print) begin
            $display("Un 1 detectado en la posición %d", i);
            $display("Ceros contados: %d", count_leading_zeros);
          end
          break;
        end
        if (i == 0 && count_leading_zeros == 0) begin
            count_leading_zeros = {1'b1, {SHIFT_WIDTH{1'b0}}};
        end
      end
    end
  endfunction
 
 assign shift_amt = count_leading_zeros(subtraction);

  always_comb begin
    if (print) begin
        $display("Ceros a la izquierda: %d (%b)", shift_amt, shift_amt);
    end
  end

endmodule