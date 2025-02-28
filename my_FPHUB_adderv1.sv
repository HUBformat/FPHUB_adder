`timescale 1ns / 1ps

module my_FPHUB_adder #(
    parameter M = 24,                                                           // Mantissa size (including implicit 1)
    parameter E = 8,                                                            // Exponent sizeparameter [E+M:0] POS_ZERO  = {1'b0, {E{1'b0}}, {M{1'b0}}};
    parameter [E+M:0] POS_ZERO  = {1'b0, {E{1'b0}}, {M{1'b0}}},                 // Special case: +0
    parameter [E+M:0] NEG_ZERO  = {1'b1, {E{1'b0}}, {M{1'b0}}},                 // Special case: -0
    parameter [E+M:0] POS_ONE   = {1'b0, 8'b10000000, 1'b1, {(M-1){1'b0}}},     // Special case: +1
    parameter [E+M:0] NEG_ONE   = {1'b1, 8'b10000000, 1'b1, {(M-1){1'b0}}},     // Special case: -1
    parameter [E+M:0] POS_INF   = {1'b0, {E{1'b1}}, {M{1'b1}}},                 // Special case: +∞
    parameter [E+M:0] NEG_INF   = {1'b1, {E{1'b1}}, {M{1'b1}}}                 // Special case: -∞
)(
    input logic signed[E+M:0] X,  // Entrada X
    input logic signed[E+M:0] Y,  // Entrada Y
    output logic [E+M:0] Z,       // Salida Z
    output logic [M+1:0] result_out, // Salida con la mantisa sumada/restada
    output logic subtraction_output,
    output logic M_major_sign_output,
    output logic [M+1:0] M_major_output,
    output logic [M+1:0] M_minor_output,
    output logic [M+1:0] M_minor_output_C2,
    output logic signed[E:0] diff_output
);

//--------------------------------------------------------------------------------------------------
// Identificación de casos especiales
//--------------------------------------------------------------------------------------------------
logic special_case;
logic [E+M:0] special_result;

always_comb begin
    // Caso 1: X e Y son infinitos con el mismo signo
    special_case = 0;
    // Casos con infinito
    // Si X = +∞ e Y = -∞, el resultado es NaN
    if ((X == POS_INF && Y == NEG_INF) || (X == NEG_INF && Y == POS_INF)) begin
        special_case = 1;
        special_result = POS_ZERO;      // Sería NaN
        $display("X = +inf e Y = -inf");
    end
    // Si X = +∞ e Y = +∞, el resultado es +∞
    else if (X == POS_INF && Y == POS_INF) begin
        special_case = 1;
        special_result = POS_INF;
        $display("X = +inf e Y = +inf");
    end
    // Si X = -∞ e Y = -∞, el resultado es -∞
    else if (X == NEG_INF && Y == NEG_INF) begin
        special_case = 1;
        special_result = NEG_INF;
        $display("X = -inf e Y = -inf");
    end
    // Si X o Y son +∞, el resultado es +∞
    else if (X == POS_INF || Y == POS_INF) begin
        special_case = 1;
        special_result = POS_INF;
        $display("X o Y son +inf");
    end
    // Si X o Y son -∞, el resultado es -∞
    else if (X == NEG_INF || Y == NEG_INF) begin
        special_case = 1;
        special_result = NEG_INF;
        $display("X o Y son -inf");
    end
    // Casos con cero
    else if (X == POS_ZERO && Y == NEG_ZERO) begin
        special_case = 1;
        special_result = POS_ZERO;
        $display("X e Y son 0");
    end
    else if ((X == POS_ZERO) || (X == NEG_ZERO)) begin
        special_case = 1;
        special_result = Y;
        $display("X = 0");
    end
    else if ((Y == POS_ZERO) || (Y == NEG_ZERO)) begin
        special_case = 1;
        special_result = X;
        $display("Y = 0");
    end
end


//--------------------------------------------------------------------------------------------------
// Cálculo de la diferencia de exponentes
//--------------------------------------------------------------------------------------------------
logic signed[E:0] diff;
logic [E:0] diff_abs;
logic X_greater_than_Y;
logic Ex_equal_Ey;

// Módulo para comparar exponentes
Exponent_difference #(E) Exponent_difference_inst (
    .Ex(X[E+M-1:M]),
    .Ey(Y[E+M-1:M]),
    .dif(diff),
    .X_greater_than_Y(X_greater_than_Y),
    .Ex_equal_Ey(Ex_equal_Ey)
);

always_comb begin
    diff_output = diff;
    //$display("diff en my_FPHUB_adder interpretado como signed = %0d", signed'(diff));
    //$display("diff_output = %0d", signed'(diff_output));
end


// Módulo para comparar mantisas (solo se ejecuta si los exponentes son iguales)
logic Mx_greater_than_My;
compare_mantissas #(M) compare_inst (
    .Mx(X[M-1:0]),
    .My(Y[M-1:0]),
    .Mx_greater_than_My(Mx_greater_than_My)
);

//--------------------------------------------------------------------------------------------------
// Organización de mantisas y signos
//--------------------------------------------------------------------------------------------------
logic [M+1:0] M_major, M_minor;
logic M_major_sign, M_minor_sign;
logic [E-1:0] Ez;

always_comb begin
    if (Ex_equal_Ey) begin
        M_major = (Mx_greater_than_My) ? {1'b0, X[M-1:0], 1'b1} : {1'b0, Y[M-1:0], 1'b1};
        M_major_sign = (Mx_greater_than_My) ? X[M+E] : Y[M+E];
        M_minor = (Mx_greater_than_My) ? {1'b0, Y[M-1:0], 1'b1} : {1'b0, X[M-1:0], 1'b1};
        M_minor_sign = (Mx_greater_than_My) ? Y[M+E] : X[M+E];
        Ez = X[E+M-1:M];
    end
    else begin
        M_major = (X_greater_than_Y) ? {1'b0, X[M-1:0], 1'b1} : {1'b0, Y[M-1:0], 1'b1};
        M_major_sign = (X_greater_than_Y) ? X[M+E] : Y[M+E];
        M_minor = (X_greater_than_Y) ? {1'b0, Y[M-1:0], 1'b1} : {1'b0, X[M-1:0], 1'b1};
        M_minor_sign = (X_greater_than_Y) ? Y[M+E] : X[M+E];
        Ez = (X_greater_than_Y) ? X[E+M-1:M] : Y[E+M-1:M];
    end
    M_major_sign_output = M_major_sign;
    diff_abs = (diff < 0) ? -diff : diff;
    //$display("diff_abs = %b", diff_abs);
end

//--------------------------------------------------------------------------------------------------
// Alineación de la mantisa menor usando un wire
//--------------------------------------------------------------------------------------------------
wire [M+1:0] M_minor_aligned;

// Instancia del módulo de desplazamiento
shifter #(
    .M(M),
    .E(E)
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
logic subtraction;
logic [M+1:0] result;
logic [$clog2(M)-1:0] shift_LZA;
logic [E-1:0] Ez_normalized;

LZA #(M)LZA_inst (
    .A(M_major[M:0]),
    .B(M_minor_aligned[M:0]),
    .shift_amt(shift_LZA)
);

always_comb begin
    // Mostrar desplazamiento de LZA
    //$display("Leading Zeros = %d (%b)", shift_LZA, shift_LZA);
    // Determinar si la operación es suma o resta
    if (special_case == 1) begin
        Z = special_result;
    end
    else begin
        subtraction = M_major_sign ^ M_minor_sign;
        subtraction_output = subtraction;

        M_major_output = M_major;
        M_minor_output = M_minor_aligned;
        M_minor_output_C2 = ~M_minor_aligned + 1;
        if (subtraction) begin
            if (M_major_sign) begin
                result = (~M_major + 1) + M_minor_aligned;
            end
            else begin
                result = M_major + (~M_minor_aligned + 1);
            end
        end
        else begin
            result = M_major + M_minor_aligned;
        end
        
        // BORRAR ESTA LINEA
        result_out = result;
        
        // Normalization
        Ez_normalized = Ez;
        if (subtraction) begin
            if (result[M+1] == 1) begin
                result = ~result + 1;
            end
            if (shift_LZA > 0) begin
                result = result << shift_LZA;
                Ez_normalized = Ez_normalized - shift_LZA;
            end
        end
        else begin
            if (result[M+1] == 1) begin
                result = result >> 1;
                Ez_normalized = Ez_normalized + 1;
            end
        end
        Z[M-1:0] = result[M:1];
        Z[E+M-1:M] = Ez_normalized;
        if (subtraction) begin
            Z[E+M] = M_major_sign;
        end
        else begin
            Z[E+M] = X[E+M];    
        end
    end
end

// Asignamos la salida
//assign result_out = result;
endmodule