`timescale 1ns / 1ps

module my_FPHUB_adder #(
    parameter int M = 23,              // Tamaño de la mantisa
    parameter int E = 8,               // Tamaño del exponente
    parameter int special_case = 7,    // Número de casos especiales (incluyendo el no especial)
    // Parámetros para la extensión de la mantisa:
    parameter int sign_mantissa_bit  = 1,
    parameter int one_implicit_bit   = 1,
    parameter int ilsb_bit           = 1,
    parameter int extra_bits_mantissa = 1 + sign_mantissa_bit + one_implicit_bit + ilsb_bit
)(
    input  logic signed [E+M:0] X,  // Entrada X
    input  logic signed [E+M:0] Y,  // Entrada Y
    output logic [E+M:0] Z         // Salida Z
);

// Numeros para testing
logic [E+M:0] X_prueba, Y_prueba;
assign X_prueba = 9'b011110011;
assign Y_prueba = 9'b111111000;

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

//--------------------------------------------------------------------------------------------------
// Determinación de la operación efectiva y el signo del resultado
//--------------------------------------------------------------------------------------------------
logic subtraction, Sz;
assign subtraction = X[E+M] ^ Y[E+M];

//--------------------------------------------------------------------------------------------------
// Organización de mantisas y signos
//--------------------------------------------------------------------------------------------------
// Las señales internas se definen con ancho M+extra_bits_mantissa
logic signed [M+extra_bits_mantissa-1:0] M_major, M_minor, M_minor_ready;
logic [E-1:0] Ez;
// Flag para indicar a los otros módulos que deben imprimir valores
logic print;
// Bits del ilsb
logic ilsb_x, ilsb_y;

//--------------------------------------------------------------------------------------------------
// Alineación de la mantisa menor usando un wire
//--------------------------------------------------------------------------------------------------
logic [M+extra_bits_mantissa-1:0] M_minor_aligned;

shifter #(
  .M(M),
  .E(E),
  .extra_bits_mantissa(extra_bits_mantissa)
) shifter_inst (
  .number_input(M_minor_ready),
  .shift_amount(diff_abs),
  .right_shift(1'b1),
  .arithmetic_shift(1'b1),
  .number_output(M_minor_aligned),
  .print(print)
);

//--------------------------------------------------------------------------------------------------
// Suma/Resta de mantisas
//--------------------------------------------------------------------------------------------------
logic signed [M+extra_bits_mantissa-1:0] M_result, M_result_ready, M_normalize;

logic [$clog2(M+extra_bits_mantissa-sign_mantissa_bit-1):0] shift_LZA;
logic [E:0] Ez_normalized;
logic [E+M:0] result;

LZD #(
      .M(M),
      .extra_bits_mantissa(extra_bits_mantissa),
      .sign_mantissa_bit(sign_mantissa_bit)
) LZA_inst (
      .A(M_result_ready[M+extra_bits_mantissa-sign_mantissa_bit-1:0]),
      .shift_amt(shift_LZA),
      .print(print)
);
always_comb begin
    // Se determina el signo del resultado
    Sz = (X_greater_than_Y) ? X[E+M] : Y[E+M];

    // Definición del ILSB según los casos especiales (por defecto siempre es 1)
    ilsb_x = (X_special_case == 5 || X_special_case == 6) ? 1'b0 : 1'b1;
    ilsb_y = (Y_special_case == 5 || Y_special_case == 6) ? 1'b0 : 1'b1;

    // Asignación de la mantisa mayor y menor
    M_major = (X_greater_than_Y) ? 
        { {sign_mantissa_bit{1'b0}}, {one_implicit_bit{1'b1}}, X[M-1:0], ilsb_x,
        {(extra_bits_mantissa - (sign_mantissa_bit+one_implicit_bit+ilsb_bit)){1'b0} } } :
        { {sign_mantissa_bit{1'b0}}, {one_implicit_bit{1'b1}}, Y[M-1:0], ilsb_y,
        {(extra_bits_mantissa - (sign_mantissa_bit+one_implicit_bit+ilsb_bit)){1'b0} } };

    M_minor = (X_greater_than_Y) ? 
        { {sign_mantissa_bit{1'b0}}, {one_implicit_bit{1'b1}}, Y[M-1:0], ilsb_y,
        {(extra_bits_mantissa - (sign_mantissa_bit+one_implicit_bit+ilsb_bit)){1'b0} } } :
        { {sign_mantissa_bit{1'b0}}, {one_implicit_bit{1'b1}}, X[M-1:0], ilsb_x,
        {(extra_bits_mantissa - (sign_mantissa_bit+one_implicit_bit+ilsb_bit)){1'b0} } };
    
    // El exponente de salida es el mayor de los dos, a menos que se necesite normalización, en cuyo caso será corregido
    Ez = (X_greater_than_Y) ? X[E+M-1:M] : Y[E+M-1:M];

    // Flag de casos espceciales (concretamente los casos de cero e infinito)
    if ((X_special_case >= 1 && X_special_case <= 4) || (Y_special_case >= 1 && Y_special_case <= 4))
        special_case_detected = 1;
    else
        special_case_detected = 0;
    
    // Cálculo del valor absoluto de la diferencia de exponentes
    diff_abs = (diff < 0) ? -diff : diff;

    if (X == X_prueba && Y == Y_prueba) begin
        $display("--------------------------------------");
        $display("Caso de prueba: ");
        $display("--------------------------------------");
        $display("X = %b", X);
        $display("Y = %b", Y);
        $display("--------------------------------------");
        $display("--------------------------------------");
        $display("Antes de alinear: ");
        $display("--------------------------------------");
        $display("M_major = %b", M_major);
        $display("M_minor = %b", M_minor);
        $display("--------------------------------------");
        print = 1;
    end
    
    // Como el ILSB siempre estará en la penúltima posición de la mantisa y sabemos que es 1, solo invertimos los bits anteriores a él.
    if (subtraction) begin
        if (M_minor[1] == 1) begin
            M_minor_ready = {~M_minor[M+extra_bits_mantissa-1:2], M_minor[1:0]};
        end
        else begin  // En los casos donde tengamos +1 o -1, asignaremos directamente el valor -1
            M_minor_ready = {~M_minor[M+extra_bits_mantissa-1], M_minor[M+extra_bits_mantissa-2:0]};
        end
        if (X == X_prueba && Y == Y_prueba) begin
            $display("--------------------------------------");
            $display("Como hay resta, calculamos el complemento a 2 de M_minor: ");
            $display("M_minor = %b", M_minor_ready);
            $display("--------------------------------------");
        end
    end
    else begin
        M_minor_ready = M_minor;
    end
    
    M_result = M_major + M_minor_aligned;
    if (X == X_prueba && Y == Y_prueba) begin
        $display("--------------------------------------");
        $display("Despues de alinear: ");
        $display("--------------------------------------");
        $display("M_major = %b", M_major);
        $display("M_minor = %b", M_minor_aligned);
        $display("--------------------------------------");
        $display("Resultado despues de la operacion: %b", M_result);
        $display("--------------------------------------");
    end
    // Si el resultado es negativo, se calcula el C2 del resultado y se corrige el signo.
    if ((M_result[M+extra_bits_mantissa-1] == 1'b1) && subtraction) begin
        M_result_ready = ~M_result + 1; 
        Sz = ~Sz;
        if (X == X_prueba && Y == Y_prueba) begin
            $display("--------------------------------------");
            $display("Se obtuvo resultado negativo. Se calcula el C2: ");
            $display("C2(M_result): %b", M_result_ready);            
            $display("--------------------------------------");
        end       
    end
    else begin
        M_result_ready = M_result;
    end
    
    // Normalización
    Ez_normalized = {1'b0, Ez};
    M_normalize = M_result_ready;
    if (X == X_prueba && Y == Y_prueba) begin
        $display("M_normalize = %b", M_normalize);
        $display("M_normalize[%d] = %b", M+extra_bits_mantissa-1, M_normalize[M+extra_bits_mantissa-1]);
    end
    if (subtraction) begin
        if (shift_LZA[$clog2(M+extra_bits_mantissa-sign_mantissa_bit-1)]) begin //En el caso especial de que las mantisas son iguales
            Ez_normalized = {(E+1){1'b0}};
            M_normalize = {(M+extra_bits_mantissa){1'b0}};
            if (X == X_prueba && Y == Y_prueba) begin
                $display("Resta. Caso especial donde el resultado es 0");
            end           
        end   
        else if (shift_LZA > 0) begin
            Ez_normalized = Ez_normalized - shift_LZA;
            if (Ez_normalized[E] == 1) begin //Underflow
                Ez_normalized = {(E+1){1'b0}};
                M_normalize = {(M+extra_bits_mantissa){1'b0}};
            end
            else begin
                M_normalize = M_normalize << shift_LZA;
            end
            if (X == X_prueba && Y == Y_prueba) begin
                $display("Resta. Se han detectado %d ceros a la izquierda.", shift_LZA);
            end 
        end
    end
    else begin    // Control de desbordamiento en la suma
        if (M_normalize[M+extra_bits_mantissa-1] == 1'b1) begin
            Ez_normalized = Ez_normalized + 1'b1;
            if (Ez_normalized[E] == 1) begin //Underflow
                Ez_normalized = {(E+1){1'b1}};
                M_normalize = {(M+extra_bits_mantissa){1'b1}};
                if (X == X_prueba && Y == Y_prueba) begin
                    $display("Suma. Overflow en el exponente.", shift_LZA);
                end 
            end
            else begin
                M_normalize = M_normalize >> 1;
                if (X == X_prueba && Y == Y_prueba) begin
                    $display("Suma. Overflow en la mantisa.", shift_LZA);
                end 
            end
        end
    end
    if (X == X_prueba && Y == Y_prueba) begin
        $display("Mantisa normalizada = %b", M_normalize);
        $display("Se selecciona: %b", M_normalize[M+extra_bits_mantissa-3 : extra_bits_mantissa-2]);
    end
    
    // Extraer los M bits de la fracción (después de los dos bits superiores: sign y bit implícito)
    result = {Sz, Ez_normalized[E-1:0], M_normalize[M+extra_bits_mantissa-3 : extra_bits_mantissa-2]};
    
    if (X == X_prueba && Y == Y_prueba) begin
        $display("Z = %b", result);
    end
end

assign Z = (special_case_detected) ? special_result : result;

endmodule