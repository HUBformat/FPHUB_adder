`timescale 1ns / 1ps

module my_FPHUB_adder #(
    parameter M = 24,  // Mantissa size (including implicit 1)
    parameter E = 8    // Exponent size
)(
    input logic signed[E+M:0] X,  // Entrada X
    input logic signed[E+M:0] Y,  // Entrada Y
    output logic [M+1:0] result_out, // Salida con la mantisa sumada/restada
    output logic subtraction_output,
    output logic M_major_sign_output,
    output logic [M+1:0] M_major_output,
    output logic [M+1:0] M_minor_output,
    output logic signed[E:0] diff_output
);

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
    $display("diff en my_FPHUB_adder interpretado como signed = %0d", signed'(diff));
    $display("diff_output = %0d", signed'(diff_output));
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

always_comb begin
    // Determinar si la operación es suma o resta
    subtraction = M_major_sign ^ M_minor_sign;
    subtraction_output = subtraction;

    M_major_output = M_major;
    M_minor_output = M_minor_aligned;

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
end

// Asignamos la salida
assign result_out = result;

endmodule
