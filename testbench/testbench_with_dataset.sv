`timescale 1ns / 1ps

module testbench;

  localparam int M = 4;  // Bits de la mantisa
  localparam int E = 4;  // Bits del exponente
    
  // Señales
  logic [E+M:0] X, Y, Z;
  logic [M+1:0] result;  // Solo queremos ver la mantisa sumada/restada
  logic subtraction_output;
  logic M_major_sign_output;
  logic [M+2:0] M_major_output;
  logic [M+2:0] M_minor_output;
  logic [M+2:0] M_minor_output_C2;
  logic [E:0] diff_output;
  logic [E:0] Ez_output;
  logic [$clog2(M)-1:0] shift_LZA_output;
  
  // Señales para la lectura del dataset
  int file, log_file, r, total_test, correct_test;
  string line;
  logic [E+M:0] expected_result;
    
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
      .diff_output(diff_output),
      .Ez_output(Ez_output),
      .shift_LZA_output(shift_LZA_output)
  );

  initial begin
    // Abrir el archivo CSV con los datos de prueba
    file = $fopen("additions_4_bit.csv", "r");
    if (file == 0) begin
      $display("Error: No se pudo abrir el archivo CSV.");
      $finish;
    end
    
    // Abrir archivo para guardar logs
    log_file = $fopen("4_bits_log_results_adder_v2.txt", "w");
    if (log_file == 0) begin
      $display("Error: No se pudo abrir el archivo de logs.");
      $finish;
    end

    // Leer la primera línea (encabezado) y descartarla
    r = $fgets(line, file);
    total_test = 0;
    correct_test = 0;

    // Leer cada línea del archivo CSV
    while (!$feof(file)) begin
      total_test++;
      r = $fgets(line, file);
      if (r > 0) begin
        r = $sscanf(line, "%h,%h,%h", X, Y, expected_result);
        if (r == 3) begin
          #0.1;  // Pequeño delay para la simulación
          
          if ((Z == expected_result) || ((Z[E+M-1:0] == expected_result[E+M-1:0]) && Z[E+M-1:0] == {(E+M){1'b0}})) begin
            correct_test++;
            //$display("[:)] Test %d superado: X(%b) + Y(%b) = %b", total_test, X, Y, Z);
            $fdisplay(log_file, "[:)] Test %d superado: X(%b) + Y(%b) = %b", total_test, X, Y, Z);
          end else begin
            //$display("[X] Test %d incorrecto: X(%b) + Y(%b) = %b (%b)", total_test, X, Y, Z, expected_result);
//            $display("Resultado esperado ---------------> %b \n", expected_result);
            
            // Guardar en el log
            $fdisplay(log_file, "[X] Test %d incorrecto: X(%b) + Y(%b) = %b", total_test, X, Y, Z);
            $fdisplay(log_file, "Ez normalizado = %b", Ez_output);
            $fdisplay(log_file, "Resultado esperado ---------------> %b \n", expected_result);
          end
        end
      end

      // Mostrar resultados cada 10,000 tests
//      if (total_test % 10000 == 0) begin
//        $display("--------------------------------------------------------------");
//        $display("Resultados: %d/%d tests superados", correct_test, total_test);
//        $display("--------------------------------------------------------------");
//        $fdisplay(log_file, "--------------------------------------------------------------");
//        $fdisplay(log_file, "Resultados: %d/%d tests superados", correct_test, total_test);
//        $fdisplay(log_file, "--------------------------------------------------------------");
//      end
    end
    
    $display("--------------------------------------------------------------");
    $display("Resultados: %d/%d tests superados", correct_test, total_test);
    //$display("--------------------------------------------------------------");
    $fdisplay(log_file, "--------------------------------------------------------------");
    $fdisplay(log_file, "Resultados finales: %d/%d tests superados", correct_test, total_test);
    $fdisplay(log_file, "--------------------------------------------------------------");
    
    // Cerrar archivos
    $fclose(file);
    $fclose(log_file);

//    $display("--------------------------------------------------------------");
//    $display("Resultados finales: %d/%d tests superados", correct_test, total_test);
//    $display("--------------------------------------------------------------");
  end

endmodule
