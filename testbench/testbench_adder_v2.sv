`timescale 1ns / 1ps

module testbench_adder_v2;
    parameter M = 23;
    parameter E = 8;
    
    // Señales
    logic [E+M:0] X, Y, Z;
    logic [M+1:0] result;  // Solo queremos ver la mantisa sumada/restada
    logic subtraction_output;
    logic M_major_sign_output;
    logic [M+2:0] M_major_output;
    logic [M+2:0] M_minor_output;
    logic [M+2:0] M_minor_output_C2;
    logic [E:0] diff_output;
    logic [M+2:0] M_major_test;
    logic [M+2:0] M_minor_aligned_test;
    
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
        .M_minor_output_C2(M_minor_output_C2),
        .diff_output(diff_output)
    );
    
    // Parámetros locales para casos especiales (mismo formato que el adder)
    localparam [E+M:0] POS_ZERO = {1'b0, {E{1'b0}}, {M{1'b0}}};
    localparam [E+M:0] NEG_ZERO = {1'b1, {E{1'b0}}, {M{1'b0}}};
    localparam [E+M:0] POS_ONE  = {1'b0, 1'b1, {(E-1){1'b0}}, {M{1'b0}}};
    localparam [E+M:0] NEG_ONE  = {1'b1, 1'b1, {(E-1){1'b0}}, {M{1'b0}}};
    localparam [E+M:0] POS_INF  = {1'b0, {E{1'b1}}, {M{1'b1}}};
    localparam [E+M:0] NEG_INF  = {1'b1, {E{1'b1}}, {M{1'b1}}};

    // Parámetro que activa el modo debug para visualizar los resultados intermedios
    localparam debug = 1;
    logic [E+M:0] expected_result;
    
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
        if (debug) begin
            $display("MODO DEBUG: Probando suma de mantisas...");
        end else begin
            $display("Probando suma de mantisas...");
        end
            
            // Caso 1: 3.0 + 5.0
            X = 32'b0_10000001_10000000000000000000000;  // IEEE 754: 3.0
            Y = 32'b0_10000010_01000000000000000000000;  // IEEE 754: 5.0
            M_major_test = 26'b01010000000000000000000001;
            M_minor_aligned_test = 26'b00110000000000000000000000;
            expected_result = 32'b0_10000011_00000000000000000000000;  // IEEE 754: 8.0
            #10;
            if (debug) begin
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
            end else begin
                $display("------------------------------------------------------------------------------------------------------------------------------");
                if (Z == expected_result) begin
                    $display("[OK] Test 1: 3.0 + 5.0");
                end
                else begin
                    $display("[ERROR] Test 1: 3.0 + 5.0");
                end
                $display("------------------------------------------------------------------------------------------------------------------------------");
            end
            
            // Caso 2: -3.0 + 5.0
            X = 32'b1_10000001_10000000000000000000000;  // IEEE 754: -3.0
            Y = 32'b0_10000010_01000000000000000000000;  // IEEE 754: 5.0
            M_major_test = 26'b01010000000000000000000001;
            M_minor_aligned_test = 26'b00110000000000000000000000;
            expected_result = 32'b0_10000001_00000000000000000000000;
            #10;
            if (debug) begin
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
            end else begin
                $display("------------------------------------------------------------------------------------------------------------------------------");
                if (Z == expected_result) begin
                    $display("[OK] Test 1: 3.0 + 5.0");
                end
                else begin
                    $display("[ERROR] Test 1: 3.0 + 5.0");
                end
                $display("------------------------------------------------------------------------------------------------------------------------------");
            end
            
            // Caso 3: +3.0 + (-5.0)
            X = 32'b0_10000001_10000000000000000000000;  // IEEE 754: 3.0
            Y = 32'b1_10000010_01000000000000000000000;  // IEEE 754: -5.0
            M_major_test = 26'b01010000000000000000000001;
            M_minor_aligned_test = 26'b00110000000000000000000000;
            expected_result = 32'b1_10000001_00000000000000000000000;
            #10;
            if (debug) begin
                $display("------------------------------------------------------------------");
            end else begin-------------------------------------------------------------------------------------------------------------------");
                $display("Test 3: +3.0 + (-5.0)");
                $display("------------------------------------------------------------------------------------------------------------------------------");
                $display("X_greater_than_Y = %b; Ex_equal_Ey = %b; Mx_greater_than_My = %b",X_greater_than_Y, Ex_equal_Ey, Mx_greater_than_My);
                $display("X = %b %b %b, Y = %b %b %b", X[E+M], X[E+M-1:M], X[M-1:0], Y[E+M], Y[E+M-1:M], Y[M-1:0]); // Esperamos mantisa ~1.00010000000000000000000
                $display("M_major = %b, M_minor = %b", M_major_output, M_minor_output);
                $display("result = %b, LZA_shifting = %d (%b)", result, shift_LZA, shift_LZA);
                $display("subtraction = %b, M_major_sign = %b, diff = %d", subtraction_output, M_major_sign_output, diff_output);
                $display("----------------------------------------------------------------------------");
                $display("Z = %b %b %b", Z[E+M], Z[E+M-1:M], Z[M-1:0]);
                $display("---------------------
                $display("------------------------------------------------------------------------------------------------------------------------------");
                if (Z == expected_result) begin
                    $display("[OK] Test 1: 3.0 + 5.0");
                end
                else begin
                    $display("[ERROR] Test 1: 3.0 + 5.0");
                end
                $display("------------------------------------------------------------------------------------------------------------------------------");
            end
            
            // Caso 4: -9.0 + 10.0
            X = 32'b1_10000011_00100000000000000000000;  // IEEE 754: -9.0
            Y = 32'b0_10000011_01000000000000000000000;  // IEEE 754: 10.0
            M_major_test = 26'b01010000000000000000000001;
            M_minor_aligned_test = 26'b01001000000000000000000001;
            expected_result = POS_ONE;
            #10;
            if (debug) begin
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
            end else begin
                $display("------------------------------------------------------------------------------------------------------------------------------");
                if (Z == expected_result) begin
                    $display("[OK] Test 1: 3.0 + 5.0");
                end
                else begin
                    $display("[ERROR] Test 1: 3.0 + 5.0");
                end
                $display("------------------------------------------------------------------------------------------------------------------------------");
            end
            
            // Caso 5: 9.0 + (-10.0)
            X = 32'b0_10000011_00100000000000000000000;  // IEEE 754: -9.0
            Y = 32'b1_10000011_01000000000000000000000;  // IEEE 754: 10.0
            M_major_test = 26'b01010000000000000000000001;
            M_minor_aligned_test = 26'b01001000000000000000000001;
            expected_result = NEG_ONE;
            #10;
            if (debug) begin
                $display("------------------------------------------------------------------------------------------------------------------------------");
                $display("Test 5: 9.0 + (-10.0)");
                $display("------------------------------------------------------------------------------------------------------------------------------");
                $display("X_greater_than_Y = %b; Ex_equal_Ey = %b; Mx_greater_than_My = %b",X_greater_than_Y, Ex_equal_Ey, Mx_greater_than_My);
                $display("X = %b %b %b, Y = %b %b %b", X[E+M], X[E+M-1:M], X[M-1:0], Y[E+M], Y[E+M-1:M], Y[M-1:0]); // Esperamos mantisa ~1.00010000000000000000000
                $display("M_major = %b, M_minor = %b", M_major_output, M_minor_output);
                $display("result = %b, LZA_shifting = %d (%b)", result, shift_LZA, shift_LZA);
                $display("subtraction = %b, M_major_sign = %b, diff = %d", subtraction_output, M_major_sign_output, diff_output);
                $display("----------------------------------------------------------------------------");
                $display("Z = %b %b %b", Z[E+M], Z[E+M-1:M], Z[M-1:0]);
                $display("----------------------------------------------------------------------------");
            end else begin
                $display("------------------------------------------------------------------------------------------------------------------------------");
                if (Z == expected_result) begin
                    $display("[OK] Test 1: 3.0 + 5.0");
                end
                else begin
                    $display("[ERROR] Test 1: 3.0 + 5.0");
                end
                $display("------------------------------------------------------------------------------------------------------------------------------");
            end
            
            // Caso 6: 9.0 + 1
            X = 32'b0_10000011_00100000000000000000000;  // IEEE 754: -9.0
            Y = 32'b0_10000000_00000000000000000000000;  // IEEE 754: 10.0
            expected_result = 32'b0_10000011_01000000000000000000000;
            #10;
            if (debug) begin
                $display("------------------------------------------------------------------------------------------------------------------------------");
                $display("Test 6: 9.0 + 1 (Special case)");
                $display("------------------------------------------------------------------------------------------------------------------------------");
                $display("X_greater_than_Y = %b; Ex_equal_Ey = %b; Mx_greater_than_My = %b",X_greater_than_Y, Ex_equal_Ey, Mx_greater_than_My);
                $display("X = %b %b %b, Y = %b %b %b", X[E+M], X[E+M-1:M], X[M-1:0], Y[E+M], Y[E+M-1:M], Y[M-1:0]); // Esperamos mantisa ~1.00010000000000000000000
                $display("M_major = %b, M_minor = %b", M_major_output, M_minor_output);
                $display("result = %b, LZA_shifting = %d (%b)", result, shift_LZA, shift_LZA);
                $display("subtraction = %b, M_major_sign = %b, diff = %d", subtraction_output, M_major_sign_output, diff_output);
                $display("----------------------------------------------------------------------------");
                $display("Z = %b %b %b", Z[E+M], Z[E+M-1:M], Z[M-1:0]);
                $display("----------------------------------------------------------------------------");
            end else begin
                $display("------------------------------------------------------------------------------------------------------------------------------");
                if (Z == expected_result) begin
                    $display("[OK] Test 1: 3.0 + 5.0");
                end
                else begin
                    $display("[ERROR] Test 1: 3.0 + 5.0");
                end
                $display("------------------------------------------------------------------------------------------------------------------------------");
            end
            
            // Caso 7: -1 + 10.0
            X = 32'b1_10000000_00000000000000000000000;  // IEEE 754: -9.0
            Y = 32'b0_10000011_01000000000000000000000;  // IEEE 754: 10.0
            M_major_test = 26'b1010000000000000000000001;
            M_minor_aligned_test = 26'b0001000000000000000000000;
            expected_result = 32'b0_10000011_00100000000000000000000;
            #10;
            if (debug) begin
                $display("------------------------------------------------------------------------------------------------------------------------------");
                $display("Test 7: -1 + 10 (Special case)");
                $display("------------------------------------------------------------------------------------------------------------------------------");
                $display("X_greater_than_Y = %b; Ex_equal_Ey = %b; Mx_greater_than_My = %b",X_greater_than_Y, Ex_equal_Ey, Mx_greater_than_My);
                $display("X = %b %b %b, Y = %b %b %b", X[E+M], X[E+M-1:M], X[M-1:0], Y[E+M], Y[E+M-1:M], Y[M-1:0]); // Esperamos mantisa ~1.00010000000000000000000
                $display("M_major = %b, M_minor = %b, C2 de M_minor = %b", M_major_output, M_minor_output, M_minor_output_C2);
                $display("result = %b, LZA_shifting = %d (%b)", result, shift_LZA, shift_LZA);
                $display("subtraction = %b, M_major_sign = %b, diff = %0d", subtraction_output, M_major_sign_output, signed'(diff_output));
                $display("----------------------------------------------------------------------------");
                $display("Z = %b %b %b", Z[E+M], Z[E+M-1:M], Z[M-1:0]);
                $display("----------------------------------------------------------------------------");
            end else begin
                $display("------------------------------------------------------------------------------------------------------------------------------");
                if (Z == expected_result) begin
                    $display("[OK] Test 1: 3.0 + 5.0");
                end
                else begin
                    $display("[ERROR] Test 1: 3.0 + 5.0");
                end
                $display("------------------------------------------------------------------------------------------------------------------------------");
            end
            
            // Caso 8: 10.0 - 1
            X = 32'b0_10000011_01000000000000000000000;  // IEEE 754: 10.0
            Y = 32'b1_10000000_00000000000000000000000;  // IEEE 754: -9.0
            expected_result = 32'b0_10000011_00100000000000000000000;
            #10;
            if (debug) begin
            $display("------------------------------------------------------------------------------------------------------------------------------");
            $display("Test 8: 10 - 1 (Special case)");
            $display("------------------------------------------------------------------------------------------------------------------------------");
            $display("X_greater_than_Y = %b; Ex_equal_Ey = %b; Mx_greater_than_My = %b",X_greater_than_Y, Ex_equal_Ey, Mx_greater_than_My);
            $display("X = %b %b %b, Y = %b %b %b", X[E+M], X[E+M-1:M], X[M-1:0], Y[E+M], Y[E+M-1:M], Y[M-1:0]); // Esperamos mantisa ~1.00010000000000000000000
            $display("M_major = %b, M_minor = %b", M_major_output, M_minor_output);
            $display("result = %b, LZA_shifting = %d (%b)", result, shift_LZA, shift_LZA);
            $display("subtraction = %b, M_major_sign = %b, diff = %d", subtraction_output, M_major_sign_output, diff_output);
            $display("----------------------------------------------------------------------------");
            $display("Z = %b %b %b", Z[E+M], Z[E+M-1:M], Z[M-1:0]);
            $display("----------------------------------------------------------------------------");
            end else begin
                $display("------------------------------------------------------------------------------------------------------------------------------");
                if (Z == expected_result) begin
                    $display("[OK] Test 1: 3.0 + 5.0");
                end
                else begin
                    $display("[ERROR] Test 1: 3.0 + 5.0");
                end
                $display("------------------------------------------------------------------------------------------------------------------------------");
            end
            
            // Caso 9: 0.00456 - 0.000005
            X = 32'b0_01111000_00101010110110000001101;  // IEEE 754: 10.0
            Y = 32'b1_01101110_01001111100010110101100;  // IEEE 754: -9.0
            expected_result = 32'b0_01111000_00101010100001000011100;
            #10;
            if (debug) begin
            $display("------------------------------------------------------------------------------------------------------------------------------");
            $display("Test 9: 0.00456 - 0.000005 (Special case)");
            $display("------------------------------------------------------------------------------------------------------------------------------");
            $display("X_greater_than_Y = %b; Ex_equal_Ey = %b; Mx_greater_than_My = %b",X_greater_than_Y, Ex_equal_Ey, Mx_greater_than_My);
            $display("X = %b %b %b, Y = %b %b %b", X[E+M], X[E+M-1:M], X[M-1:0], Y[E+M], Y[E+M-1:M], Y[M-1:0]); // Esperamos mantisa ~1.00010000000000000000000
            $display("M_major = %b, M_minor = %b", M_major_output, M_minor_output);
            $display("result = %b, LZA_shifting = %d (%b)", result, shift_LZA, shift_LZA);
            $display("subtraction = %b, M_major_sign = %b, diff = %d", subtraction_output, M_major_sign_output, diff_output);
            $display("----------------------------------------------------------------------------");
            $display("Z = %b %b %b", Z[E+M], Z[E+M-1:M], Z[M-1:0]);
            $display("----------------------------------------------------------------------------");
            end else begin
                $display("------------------------------------------------------------------------------------------------------------------------------");
                if (Z == expected_result) begin
                    $display("[OK] Test 1: 3.0 + 5.0");
                end
                else begin
                    $display("[ERROR] Test 1: 3.0 + 5.0");
                end
                $display("------------------------------------------------------------------------------------------------------------------------------");
            end
            
            // Caso 10: 1e-45 - 4e-45
            X = 32'b0_00000000_00000000000000000000001;  // IEEE 754: 10.0
            Y = 32'b1_00000000_00000000000000000000011;  // IEEE 754: -9.0
            #10;
            $display("------------------------------------------------------------------------------------------------------------------------------");
            $display("Test 10: 1e-45 - 4e-45 (Special case)");
            $display("------------------------------------------------------------------------------------------------------------------------------");
            $display("X_greater_than_Y = %b; Ex_equal_Ey = %b; Mx_greater_than_My = %b",X_greater_than_Y, Ex_equal_Ey, Mx_greater_than_My);
            $display("X = %b %b %b, Y = %b %b %b", X[E+M], X[E+M-1:M], X[M-1:0], Y[E+M], Y[E+M-1:M], Y[M-1:0]); // Esperamos mantisa ~1.00010000000000000000000
            $display("M_major_sign_output = %b", M_major_sign_output);
            $display("M_major = %b, M_minor = %b", M_major_output, M_minor_output);
            $display("result = %b, LZA_shifting = %d (%b)", result, shift_LZA, shift_LZA);
            $display("subtraction = %b, M_major_sign = %b, diff = %d", subtraction_output, M_major_sign_output, diff_output);
            $display("----------------------------------------------------------------------------");
            $display("Z = %b %b %b", Z[E+M], Z[E+M-1:M], Z[M-1:0]);
            $display("----------------------------------------------------------------------------");
            
            $display("=== Testbench: Casos especiales para my_FPHUB_adder ===");
            
            // Caso 10: 1e-45 - 4e-45
            X = 32'b0_11111111_00000000000000000000001;  // IEEE 754: 10.0
            Y = 32'b1_11111111_00000000000000000000011;  // IEEE 754: -9.0
            #10;
            $display("------------------------------------------------------------------------------------------------------------------------------");
            $display("Test 11: 1e-45 - 4e-45 (Special case)");
            $display("------------------------------------------------------------------------------------------------------------------------------");
            $display("X_greater_than_Y = %b; Ex_equal_Ey = %b; Mx_greater_than_My = %b",X_greater_than_Y, Ex_equal_Ey, Mx_greater_than_My);
            $display("X = %b %b %b, Y = %b %b %b", X[E+M], X[E+M-1:M], X[M-1:0], Y[E+M], Y[E+M-1:M], Y[M-1:0]); // Esperamos mantisa ~1.00010000000000000000000
            $display("M_major_sign_output = %b", M_major_sign_output);
            $display("M_major = %b, M_minor = %b", M_major_output, M_minor_output);
            $display("result = %b, LZA_shifting = %d (%b)", result, shift_LZA, shift_LZA);
            $display("subtraction = %b, M_major_sign = %b, diff = %d", subtraction_output, M_major_sign_output, diff_output);
            $display("----------------------------------------------------------------------------");
            $display("Z = %b %b %b", Z[E+M], Z[E+M-1:M], Z[M-1:0]);
            $display("----------------------------------------------------------------------------");
            
            $display("=== Testbench: Casos especiales para my_FPHUB_adder ===");
            
            // --- Casos en que ambos operandos son casos especiales ---
            
            // Test 1: X = Y = inf  -> resultado: inf
            X = POS_INF;
            Y = POS_INF;
            #10;
            $display("Test 1: X = Y = inf");
            $display("  X = %b", X);
            $display("  Y = %b", Y);
            $display("  Z = %b", Z);
            
            // Test 2: X = Y = -inf  -> resultado: -inf
            X = NEG_INF;
            Y = NEG_INF;
            #10;
            $display("Test 2: X = Y = -inf");
            $display("  X = %b", X);
            $display("  Y = %b", Y);
            $display("  Z = %b", Z);
            
            // Test 3: X = Y = +0  -> resultado: +0 (por convención)
            X = POS_ZERO;
            Y = POS_ZERO;
            #10;
            $display("Test 3: X = Y = +0");
            $display("  X = %b", X);
            $display("  Y = %b", Y);
            $display("  Z = %b", Z);
            
            // Test 4: X = Y = -0  -> resultado: -0 (o +0, según convención)
            X = NEG_ZERO;
            Y = NEG_ZERO;
            #10;
            $display("Test 4: X = Y = -0");
            $display("  X = %b", X);
            $display("  Y = %b", Y);
            $display("  Z = %b", Z);
            
            // --- Casos mixtos: combinaciones de cero e infinito ---
            
            // Test 5: X = inf, Y = +0  -> resultado: inf
            X = POS_INF;
            Y = POS_ZERO;
            #10;
            $display("Test 5: X = inf, Y = +0");
            $display("  X = %b", X);
            $display("  Y = %b", Y);
            $display("  Z = %b", Z);
            
            // Test 6: X = -inf, Y = -0  -> resultado: -inf
            X = NEG_INF;
            Y = NEG_ZERO;
            #10;
            $display("Test 6: X = -inf, Y = -0");
            $display("  X = %b", X);
            $display("  Y = %b", Y);
            $display("  Z = %b", Z);
            
            // Test 7: X = +0, Y = inf  -> resultado: inf
            X = POS_ZERO;
            Y = POS_INF;
            #10;
            $display("Test 7: X = +0, Y = inf");
            $display("  X = %b", X);
            $display("  Y = %b", Y);
            $display("  Z = %b", Z);
            
            // Test 8: X = -0, Y = -inf  -> resultado: -inf
            X = NEG_ZERO;
            Y = NEG_INF;
            #10;
            $display("Test 8: X = -0, Y = -inf");
            $display("  X = %b", X);
            $display("  Y = %b", Y);
            $display("  Z = %b", Z);
            
            // Test 9: X = inf, Y = -0  -> resultado: inf
            X = POS_INF;
            Y = NEG_ZERO;
            #10;
            $display("Test 9: X = inf, Y = -0");
            $display("  X = %b", X);
            $display("  Y = %b", Y);
            $display("  Z = %b", Z);
            
            // Test 10: X = -inf, Y = +0  -> resultado: -inf
            X = NEG_INF;
            Y = POS_ZERO;
            #10;
            $display("Test 10: X = -inf, Y = +0");
            $display("  X = %b", X);
            $display("  Y = %b", Y);
            $display("  Z = %b", Z);
            
            // --- Otros casos especiales combinados ---
            
            // Test 11: X = inf, Y = -inf  -> resultado especial (NaN, o como se defina)
            X = POS_INF;
            Y = NEG_INF;
            #10;
            $display("Test 11: X = inf, Y = -inf");
            $display("  X = %b", X);
            $display("  Y = %b", Y);
            $display("  Z = %b", Z);
    end
endmodule