`timescale 1ns / 1ps

module my_FPHUB_adder #(
    parameter int M = 23,              // Mantissa size parameter
    parameter int E = 8,               // Exponent size parameter
    parameter int special_case = 7     // Number of special cases (including no special case)
)(
    input logic signed [E+M:0] X,  // Entrada X
    input logic signed [E+M:0] Y,  // Entrada Y
    output logic [E+M:0] Z,       // Salida Z
    output logic [M+1:0] result_out, // Salida con la mantisa sumada/restada
    output logic subtraction_output,
    output logic M_major_sign_output,
    output logic [M+2:0] M_major_output,
    output logic [M+2:0] M_minor_output,
    output logic [M+2:0] M_minor_output_C2,
    output logic signed[E:0] diff_output
);
//--------------------------------------------------------------------------------------------------
// Identificación de casos especiales
//--------------------------------------------------------------------------------------------------
logic [M+E:0] special_result;
logic [$clog2(special_case)-1:0] X_special_case, Y_special_case;
logic special_case_detected;

//always_comb begin
//    $display("Antes de los casos especiales: X = %b %b %b, Y = %b %b %b", X[E+M], X[E+M-1:M], X[M-1:0], Y[E+M], Y[E+M-1:M], Y[M-1:0]);
//end

special_cases_detector #(E, M, special_case) special_cases_inst (
    .X(X),
    .Y(Y),
    .X_special_case(X_special_case),
    .Y_special_case(Y_special_case)
);

//assign special_case_detected = (X_special_case != 0) || (Y_special_case != 0);

special_result_for_adder #(E, M, special_case) special_result_inst (
    .X(X),
    .Y(Y),
    .X_special_case(X_special_case),
    .Y_special_case(Y_special_case),
    .special_result(special_result)
);


//always_comb begin
//    $display("X = %b %b %b, Y = %b %b %b", X[E+M], X[E+M-1:M], X[M-1:0], Y[E+M], Y[E+M-1:M], Y[M-1:0]);
//    $display("X_special_case = %d, Y_special_case = %d", X_special_case, Y_special_case);
//end

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
assign diff_output = diff;

logic Mx_greater_than_My;
logic [M:0] Mx_complete , My_complete;

always_comb begin
    Mx_complete = {1'b1, X[M-1:0]};
    My_complete = {1'b1, Y[M-1:0]};
    //$display("Mx_complete = %b; My_complete = %b", Mx_complete, My_complete);
end

compare_mantissas #(M) compare_inst (
    .Mx(Mx_complete),
    .My(My_complete),
    .Mx_greater_than_My(Mx_greater_than_My)
);

//--------------------------------------------------------------------------------------------------
// Organización de mantisas y signos
//--------------------------------------------------------------------------------------------------
logic [M+2:0] M_major, M_minor;
logic M_major_sign, M_minor_sign;
logic [E-1:0] Ez;
logic X_one_implicit, Y_one_implicit;
logic X_ilsb, Y_ilsb;

always_comb begin
    X_one_implicit = (X[E+M-1:M] == {E{1'b0}}) ? 1'b0 : 1'b1;
    Y_one_implicit = (Y[E+M-1:M] == {E{1'b0}}) ? 1'b0 : 1'b1;
    X_ilsb = (X_special_case == 5 || X_special_case == 6) ? 1'b0 : 1'b1;
    Y_ilsb = (Y_special_case == 5 || Y_special_case == 6) ? 1'b0 : 1'b1;
    if (Ex_equal_Ey) begin
        M_major = (Mx_greater_than_My) ? {1'b0, X_one_implicit, X[M-1:0], X_ilsb} : {1'b0, Y_one_implicit, Y[M-1:0], Y_ilsb};
        M_major_sign = (Mx_greater_than_My) ? X[M+E] : Y[M+E];
        M_minor = (Mx_greater_than_My) ? {1'b0, Y_one_implicit, Y[M-1:0], Y_ilsb} : {1'b0, X_one_implicit, X[M-1:0], X_ilsb};
        M_minor_sign = (Mx_greater_than_My) ? Y[M+E] : X[M+E];
        Ez = X[E+M-1:M];
    end
    else begin
        M_major = (X_greater_than_Y) ? {1'b0, X_one_implicit, X[M-1:0], X_ilsb} : {1'b0, Y_one_implicit, Y[M-1:0], Y_ilsb};
        M_major_sign = (X_greater_than_Y) ? X[M+E] : Y[M+E];
        M_minor = (X_greater_than_Y) ? {1'b0, Y_one_implicit, Y[M-1:0], Y_ilsb} : {1'b0, X_one_implicit, X[M-1:0], X_ilsb};
        M_minor_sign = (X_greater_than_Y) ? Y[M+E] : X[M+E];
        Ez = (X_greater_than_Y) ? X[E+M-1:M] : Y[E+M-1:M];
    end
    if ((X_special_case >= 1 && X_special_case <= 4) || (Y_special_case >= 1 && Y_special_case <= 4)) begin
        special_case_detected = 1;
    end else begin
        special_case_detected = 0;
    end
    M_major_sign_output = M_major_sign;
    diff_abs = (diff < 0) ? -diff : diff;
end

//--------------------------------------------------------------------------------------------------
// Alineación de la mantisa menor usando un wire
//--------------------------------------------------------------------------------------------------
wire [M+2:0] M_minor_aligned;

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
logic subtraction, Sz;
logic [M+2:0] M_result;
logic [$clog2(M)-1:0] shift_LZA;
logic [E-1:0] Ez_normalized;
logic [E+M:0] result;

LZA #(M)LZA_inst (
    .A(M_major[M+1:0]),
    .B(M_minor_aligned[M+1:0]),
    .shift_amt(shift_LZA)
);

always_comb begin
    // Mostrar desplazamiento de LZA
    //$display("Leading Zeros = %d (%b)", shift_LZA, shift_LZA);
    // Determinar si la operación es suma o resta
    //if (special_case == 1) begin
    //    Z = special_result;
    //end
    //else begin
    subtraction = M_major_sign ^ M_minor_sign;
    subtraction_output = subtraction;

    M_major_output = M_major;
    M_minor_output = M_minor_aligned;
    M_minor_output_C2 = ~M_minor_aligned + 1;
    if (subtraction) begin
        if (M_major_sign) begin
            M_result = (~M_major + 1) + M_minor_aligned;
        end
        else begin
            M_result = M_major + (~M_minor_aligned + 1);
        end
    end
    else begin
        M_result = M_major + M_minor_aligned;
    end

    // BORRAR ESTA LINEA
    result_out = M_result;

    // Normalization
    Ez_normalized = Ez;
    if (subtraction) begin
        if (M_result[M+2] == 1) begin
            M_result = ~M_result + 1;
        end
        if (shift_LZA > 0) begin
            M_result = M_result << shift_LZA;
            Ez_normalized = Ez_normalized - shift_LZA;
        end
    end
    else begin
        if (M_result[M+2] == 1) begin
            M_result = M_result >> 1;
            Ez_normalized = Ez_normalized + 1;
        end
    end

    Sz = (subtraction) ? M_major_sign : X[E+M];
    //if (subtraction) begin
    //    Sz = M_major_sign;
    //end
    //else begin
    //    Z[E+M] = X[E+M];    
    //end
    result = {Sz, Ez_normalized, M_result[M:1]};

    end

assign Z = (special_case_detected) ? special_result : result;
endmodule