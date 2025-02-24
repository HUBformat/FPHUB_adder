`timescale 1ns / 1ps

module testbench_adder_v1;
    parameter M = 24;
    parameter E = 8;
    
    // Señales
    logic [E+M:0] X, Y, Z;
    logic [M+1:0] result;  // Solo queremos ver la mantisa sumada/restada
    logic subtraction_output;
    logic M_major_sign_output;
    logic [M+1:0] M_major_output;
    logic [M+1:0] M_minor_output;
    logic [E:0] diff_output;
    logic [M+1:0] M_major_test;
    logic [M+1:0] M_minor_aligned_test;
    
    // Instancia del módulo
    my_FPHUB_adder #(M, E) dut (
        .X(X),
        .Y(Y),
        .Z(Z),
        .result_out(result),  // Conectamos la salida nueva
        .subtraction_output(subtraction_output),
        .M_major_sign_output(M_major_sign_output),
        .M_major_output(M_major_output),
        .M_minor_output(M_minor_output),
        .diff_output(diff_output)
    );
    
    logic [E:0] diff;
    logic X_greater_than_Y;
    logic Ex_equal_Ey;
    
    Exponent_difference #(.E(E)) Exponent_difference_inst (
    .Ex(X[E+M-1:M]),
    .Ey(Y[E+M-1:M]),
    .dif(diff),
    .X_greater_than_Y(X_greater_than_Y),
    .Ex_equal_Ey(Ex_equal_Ey)
    );
    
    // Módulo para comparar mantisas (solo se ejecuta si los exponentes son iguales)
    logic Mx_greater_than_My;
    compare_mantissas #(M) compare_inst (
        .Mx(X[M-1:0]),
        .My(Y[M-1:0]),
        .Mx_greater_than_My(Mx_greater_than_My)
    );
    
    logic [$clog2(M)-1:0] shift_LZA;

    LZA #(M) LZA_inst (
        .A(M_major_test),
        .B(M_minor_aligned_test),
        .shift_amt(shift_LZA)
    );
    
    initial begin
        $display("Probando suma de mantisas...");
        
        // Caso 1: 3.0 + 5.0
        X = 33'b0_10000001_110000000000000000000000;  // IEEE 754: 3.0
        Y = 33'b0_10000010_101000000000000000000000;  // IEEE 754: 5.0
        M_major_test = 26'b01010000000000000000000001;
        M_minor_aligned_test = 26'b00110000000000000000000000;
        #10;
        $display("------------------------------------------------------------------------------------------------------------------------------");
        $display("Test 1: 3.0 + 5.0");
        $display("------------------------------------------------------------------------------------------------------------------------------");
        $display("X_greater_than_Y = %b; Ex_equal_Ey = %b; Mx_greater_than_My = %b",X_greater_than_Y, Ex_equal_Ey, Mx_greater_than_My);
        $display("X = %b %b %b, Y = %b %b %b", X[E+M], X[E+M-1:M], X[M-1:0], Y[E+M], Y[E+M-1:M], Y[M-1:0]); // Esperamos mantisa ~1.00010000000000000000000
        $display("M_major = %b, M_minor = %b", M_major_output, M_minor_output);
        $display("result = %b", result);
        $display("subtraction = %b, M_major_sign = %b, diff = %0d", subtraction_output, M_major_sign_output, signed'(diff_output));
        $display("----------------------------------------------------------------------------");
        $display("Z = %b %b %b", Z[E+M], Z[E+M-1:M], Z[M-1:0]);
        $display("----------------------------------------------------------------------------");
        
        // Caso 2: -3.0 + 5.0
        X = 33'b1_10000001_110000000000000000000000;  // IEEE 754: -3.0
        Y = 33'b0_10000010_101000000000000000000000;  // IEEE 754: 5.0
        M_major_test = 26'b01010000000000000000000001;
        M_minor_aligned_test = 26'b00110000000000000000000000;
        #10;
        $display("------------------------------------------------------------------------------------------------------------------------------");
        $display("Test 2: -3.0 + 5.0");
        $display("------------------------------------------------------------------------------------------------------------------------------");
        $display("X_greater_than_Y = %b; Ex_equal_Ey = %b; Mx_greater_than_My = %b",X_greater_than_Y, Ex_equal_Ey, Mx_greater_than_My);
        $display("X = %b %b %b, Y = %b %b %b", X[E+M], X[E+M-1:M], X[M-1:0], Y[E+M], Y[E+M-1:M], Y[M-1:0]); // Esperamos mantisa ~1.00010000000000000000000
        $display("M_major = %b, M_minor = %b", M_major_output, M_minor_output);
        $display("result = %b, LZA_shifting = %d (%b)", result, shift_LZA, shift_LZA);
        $display("subtraction = %b, M_major_sign = %b, diff = %d", subtraction_output, M_major_sign_output, diff_output);
        $display("----------------------------------------------------------------------------");
        $display("Z = %b %b %b", Z[E+M], Z[E+M-1:M], Z[M-1:0]);
        $display("----------------------------------------------------------------------------");
        
        // Caso 3: +3.0 + (-5.0)
        X = 33'b0_10000001_110000000000000000000000;  // IEEE 754: 3.0
        Y = 33'b1_10000010_101000000000000000000000;  // IEEE 754: -5.0
        M_major_test = 26'b01010000000000000000000001;
        M_minor_aligned_test = 26'b00110000000000000000000000;
        #10;
        $display("------------------------------------------------------------------------------------------------------------------------------");
        $display("Test 3: +3.0 + (-5.0)");
        $display("------------------------------------------------------------------------------------------------------------------------------");
        $display("X_greater_than_Y = %b; Ex_equal_Ey = %b; Mx_greater_than_My = %b",X_greater_than_Y, Ex_equal_Ey, Mx_greater_than_My);
        $display("X = %b %b %b, Y = %b %b %b", X[E+M], X[E+M-1:M], X[M-1:0], Y[E+M], Y[E+M-1:M], Y[M-1:0]); // Esperamos mantisa ~1.00010000000000000000000
        $display("M_major = %b, M_minor = %b", M_major_output, M_minor_output);
        $display("result = %b, LZA_shifting = %d (%b)", result, shift_LZA, shift_LZA);
        $display("subtraction = %b, M_major_sign = %b, diff = %d", subtraction_output, M_major_sign_output, diff_output);
        $display("----------------------------------------------------------------------------");
        $display("Z = %b %b %b", Z[E+M], Z[E+M-1:M], Z[M-1:0]);
        $display("----------------------------------------------------------------------------");
        
        // Caso 4: -9.0 + 10.0
        X = 33'b1_10000011_100100000000000000000000;  // IEEE 754: -9.0
        Y = 33'b0_10000011_101000000000000000000000;  // IEEE 754: 10.0
        M_major_test = 26'b01010000000000000000000001;
        M_minor_aligned_test = 26'b01001000000000000000000001;
        #10;
        $display("------------------------------------------------------------------------------------------------------------------------------");
        $display("Test 4: -9.0 + 10.0");
        $display("------------------------------------------------------------------------------------------------------------------------------");
        $display("X_greater_than_Y = %b; Ex_equal_Ey = %b; Mx_greater_than_My = %b",X_greater_than_Y, Ex_equal_Ey, Mx_greater_than_My);
        $display("X = %b %b %b, Y = %b %b %b", X[E+M], X[E+M-1:M], X[M-1:0], Y[E+M], Y[E+M-1:M], Y[M-1:0]); // Esperamos mantisa ~1.00010000000000000000000
        $display("M_major = %b, M_minor = %b", M_major_output, M_minor_output);
        $display("result = %b, LZA_shifting = %d (%b)", result, shift_LZA, shift_LZA);
        $display("subtraction = %b, M_major_sign = %b, diff = %d", subtraction_output, M_major_sign_output, diff_output);
        $display("----------------------------------------------------------------------------");
        $display("Z = %b %b %b", Z[E+M], Z[E+M-1:M], Z[M-1:0]);
        $display("----------------------------------------------------------------------------");
    end
endmodule