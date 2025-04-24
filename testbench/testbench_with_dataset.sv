`timescale 1ns / 1ps

module testbench;

  localparam int M = 4;  // Bits de la mantisa
  localparam int E = 4;  // Bits del exponente
    
  // Señales
  logic [E+M:0] X, Y, Z;
  
  // Señales para la lectura del dataset
  int file, log_file, r, total_test, correct_test;
  string line;
  logic [E+M:0] expected_result;
    
  // Instancia del módulo
  my_FPHUB_adder #(M, E) dut (
      .X(X),
      .Y(Y),
      .Z(Z)
  );

  initial begin
    // Abrir el archivo CSV con los datos de prueba
    file = $fopen("hub_float_addition_exp4_mant4.csv", "r");
    if (file == 0) begin
      $display("Error: No se pudo abrir el archivo CSV.");
      $finish;
    end
    
    // Abrir archivo para guardar logs
    log_file = $fopen("4_bits_log_results_adder_1extra_bits.txt", "w");
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
    $display("Resultados: %d/%d tests superados", correct_test, total_test-1);
    //$display("--------------------------------------------------------------");
    $fdisplay(log_file, "--------------------------------------------------------------");
    $fdisplay(log_file, "Resultados finales: %d/%d tests superados", correct_test, total_test-1);
    $fdisplay(log_file, "--------------------------------------------------------------");
    
    // Cerrar archivos
    $fclose(file);
    $fclose(log_file);

//    $display("--------------------------------------------------------------");
//    $display("Resultados finales: %d/%d tests superados", correct_test, total_test);
//    $display("--------------------------------------------------------------");
  end

endmodule
