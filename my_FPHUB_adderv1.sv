`timescale 1ns / 1ps

module my_FPHUB_adder #(
    parameter int M = 23,              // Tamaño de la mantisa
    parameter int E = 8,               // Tamaño del exponente
    parameter int special_case = 7,    // Número de casos especiales (incluyendo el no especial)
    // Parámetros para la extensión de la mantisa:
    parameter int sign_mantissa_bit  = 1,
    parameter int one_implicit_bit   = 1,
    parameter int ilsb_bit           = 1,
    parameter int extra_bits_mantissa = 4 + sign_mantissa_bit + one_implicit_bit + ilsb_bit
)(
    input  logic signed [E+M:0] X,  // Entrada X
    input  logic signed [E+M:0] Y,  // Entrada Y
    output logic [E+M:0] Z,         // Salida Z
    output logic [M+1:0] result_out, // Salida con la mantisa sumada/restada (para testbench)
    output logic subtraction_output,
    output logic M_major_sign_output,
    output logic [M+extra_bits_mantissa-1:0] M_major_output,
    output logic [M+extra_bits_mantissa-1:0] M_minor_output,
    output logic [M+extra_bits_mantissa-1:0] M_minor_output_C2,
    output logic signed [E:0] diff_output,
    output logic [E:0] Ez_output
);

  //--------------------------------------------------------------------------------------------------
  // Identificación de casos especiales
  //--------------------------------------------------------------------------------------------------
  logic [M+E:0] special_result;
  logic [$clog2(special_case)-1:0] X_special_case, Y_special_case;
  logic special_case_detected;

  special_cases_detector #(E, M, special_case) special_cases_inst (
      .X(X),
      .Y(Y),
      .X_special_case(X_special_case),
      .Y_special_case(Y_special_case)
  );

  special_result_for_adder #(E, M, special_case) special_result_inst (
      .X(X),
      .Y(Y),
      .X_special_case(X_special_case),
      .Y_special_case(Y_special_case),
      .special_result(special_result)
  );

  //--------------------------------------------------------------------------------------------------
  // Cálculo de la diferencia de exponentes
  //--------------------------------------------------------------------------------------------------
  logic signed [E:0] diff;
  logic [E:0] diff_abs;
  logic X_greater_than_Y;
  logic Ex_equal_Ey;

  Exponent_difference #(E) Exponent_difference_inst (
      .Ex(X[E+M-1:M]),
      .Ey(Y[E+M-1:M]),
      .dif(diff),
      .X_greater_than_Y(X_greater_than_Y),
      .Ex_equal_Ey(Ex_equal_Ey)
  );
  assign diff_output = diff;

  logic Mx_greater_than_My;
  logic [M:0] Mx_complete, My_complete;

  always_comb begin
      Mx_complete = {1'b1, X[M-1:0]};
      My_complete = {1'b1, Y[M-1:0]};
  end

  compare_mantissas #(M) compare_inst (
      .Mx(Mx_complete),
      .My(My_complete),
      .Mx_greater_than_My(Mx_greater_than_My)
  );

  //--------------------------------------------------------------------------------------------------
  // Organización de mantisas y signos
  //--------------------------------------------------------------------------------------------------
  // Las señales internas se definen con ancho M+extra_bits_mantissa
  logic [M+extra_bits_mantissa-1:0] M_major, M_minor;
  logic M_major_sign, M_minor_sign;
  logic [E-1:0] Ez;

  // Definición de ilsb según casos especiales:
  logic ilsb_x, ilsb_y;
  always_comb begin
      ilsb_x = (X_special_case == 5 || X_special_case == 6) ? 1'b0 : 1'b1;
      ilsb_y = (Y_special_case == 5 || Y_special_case == 6) ? 1'b0 : 1'b1;
      
      if (Ex_equal_Ey) begin
          M_major = (Mx_greater_than_My) ? 
              { {sign_mantissa_bit{1'b0}}, {one_implicit_bit{1'b1}}, X[M-1:0], ilsb_x,
                {(extra_bits_mantissa - (sign_mantissa_bit+one_implicit_bit+ilsb_bit)){1'b0} } } :
              { {sign_mantissa_bit{1'b0}}, {one_implicit_bit{1'b1}}, Y[M-1:0], ilsb_y,
                {(extra_bits_mantissa - (sign_mantissa_bit+one_implicit_bit+ilsb_bit)){1'b0} } };
          M_major_sign = (Mx_greater_than_My) ? X[M+E] : Y[M+E];
          M_minor = (Mx_greater_than_My) ? 
              { {sign_mantissa_bit{1'b0}}, {one_implicit_bit{1'b1}}, Y[M-1:0], ilsb_y,
                {(extra_bits_mantissa - (sign_mantissa_bit+one_implicit_bit+ilsb_bit)){1'b0} } } :
              { {sign_mantissa_bit{1'b0}}, {one_implicit_bit{1'b1}}, X[M-1:0], ilsb_x,
                {(extra_bits_mantissa - (sign_mantissa_bit+one_implicit_bit+ilsb_bit)){1'b0} } };
          M_minor_sign = (Mx_greater_than_My) ? Y[M+E] : X[M+E];
          Ez = X[E+M-1:M];
      end
      else begin
          M_major = (X_greater_than_Y) ? 
              { {sign_mantissa_bit{1'b0}}, {one_implicit_bit{1'b1}}, X[M-1:0], ilsb_x,
                {(extra_bits_mantissa - (sign_mantissa_bit+one_implicit_bit+ilsb_bit)){1'b0} } } :
              { {sign_mantissa_bit{1'b0}}, {one_implicit_bit{1'b1}}, Y[M-1:0], ilsb_y,
                {(extra_bits_mantissa - (sign_mantissa_bit+one_implicit_bit+ilsb_bit)){1'b0} } };
          M_major_sign = (X_greater_than_Y) ? X[M+E] : Y[M+E];
          M_minor = (X_greater_than_Y) ? 
              { {sign_mantissa_bit{1'b0}}, {one_implicit_bit{1'b1}}, Y[M-1:0], ilsb_y,
                {(extra_bits_mantissa - (sign_mantissa_bit+one_implicit_bit+ilsb_bit)){1'b0} } } :
              { {sign_mantissa_bit{1'b0}}, {one_implicit_bit{1'b1}}, X[M-1:0], ilsb_x,
                {(extra_bits_mantissa - (sign_mantissa_bit+one_implicit_bit+ilsb_bit)){1'b0} } };
          M_minor_sign = (X_greater_than_Y) ? Y[M+E] : X[M+E];
          Ez = (X_greater_than_Y) ? X[E+M-1:M] : Y[E+M-1:M];
      end

      if ((X_special_case >= 1 && X_special_case <= 4) || (Y_special_case >= 1 && Y_special_case <= 4))
          special_case_detected = 1;
      else
          special_case_detected = 0;
      
      M_major_sign_output = M_major_sign;
      diff_abs = (diff < 0) ? -diff : diff;
  end

  //--------------------------------------------------------------------------------------------------
  // Alineación de la mantisa menor usando un wire
  //--------------------------------------------------------------------------------------------------
  wire [M+extra_bits_mantissa-1:0] M_minor_aligned;

  shifter #(
      .M(M),
      .E(E),
      .extra_bits_mantissa(extra_bits_mantissa)
  ) shifter_inst (
      .number_input(M_minor),
      .shift_amount(diff_abs),
      .right_shift(1'b1),
      .arithmetic_shift(1'b0),
      .number_output(M_minor_aligned)
  );

  //--------------------------------------------------------------------------------------------------
  // Suma/Resta de mantisas
  //--------------------------------------------------------------------------------------------------
  logic subtraction, Sz;
  logic [M+extra_bits_mantissa-1:0] M_result, M1, M2;
  logic [$clog2(M)-1:0] shift_LZA;
  logic [E-1:0] Ez_normalized;
  logic [E+M:0] result;

  LZD #(
      .M(M),
      .extra_bits_mantissa(extra_bits_mantissa),
      .sign_mantissa_bit(sign_mantissa_bit)
  ) LZA_inst (
      .A(M_major[M+extra_bits_mantissa-sign_mantissa_bit-1:0]),
      .B(M_minor_aligned[M+extra_bits_mantissa-sign_mantissa_bit-1:0]),
      .shift_amt(shift_LZA)
  );

  always_comb begin
      subtraction = M_major_sign ^ M_minor_sign;
      subtraction_output = subtraction;

      M_major_output = M_major;
      M_minor_output = M_minor_aligned;
      M_minor_output_C2 = ~M_minor_aligned + 1;

      if (subtraction) begin
          if (M_major_sign)
              M_result = (~M_major + 1) + M_minor_aligned;
          else
              M_result = M_major + (~M_minor_aligned + 1);
      end
      else begin
          M_result = M_major + M_minor_aligned;
      end

      // Normalización
      Ez_normalized = Ez;
      if (subtraction) begin
          if (M_result[M+extra_bits_mantissa-1] == 1)
              M_result = ~M_result + 1;
          if (shift_LZA > 0) begin
              if (Ez_normalized == {E{1'b0}})
                  M_result = 0;
              else begin
                  M_result = M_result << shift_LZA;
                  Ez_normalized = Ez_normalized - shift_LZA;
              end
          end
      end
      else begin
          if (M_result[M+extra_bits_mantissa-1] == 1) begin
              if (Ez_normalized == {E{1'b1}})
                  M_result = {(M+3){1'b1}};
              else begin
                  M_result = M_result >> 1;
                  Ez_normalized = Ez_normalized + 1;
              end         
          end
      end
      result_out = M_result;

      Sz = (subtraction) ? M_major_sign : X[E+M];
      // Extraer los M bits de la fracción (después de los dos bits superiores: sign y bit implícito)
      result = {Sz, Ez_normalized, M_result[M+extra_bits_mantissa-3 : extra_bits_mantissa-2]};
  end

  assign Z = (special_case_detected) ? special_result : result;
  assign Ez_output = Ez;
  
endmodule