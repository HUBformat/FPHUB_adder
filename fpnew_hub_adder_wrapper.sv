module fpnew_hub_adder_wrapper #(
  parameter FpFormat = fpnew_pkg::FP32,
  parameter int M = fpnew_pkg::man_bits(FpFormat),
  parameter int E = fpnew_pkg::exp_bits(FpFormat)
)(
  // Interfaz de entrada de FPnew
  input logic                    clk_i,
  input logic                    rst_ni,
  input logic [2:0][31:0]        operands_i,
  input fpnew_pkg::operation_e   op_i,
  input logic                    op_mod_i,
  input logic                    in_valid_i,
  output logic                   in_ready_o,
  input logic                    flush_i,
  // Interfaz de salida de FPnew
  output logic [31:0]            result_o,
  output fpnew_pkg::status_t     status_o,
  output logic                   out_valid_o,
  input logic                    out_ready_i
);

  // Señales internas para tu módulo FPHUB_adder
  logic [E+M:0] hub_X, hub_Y, hub_Z;
  logic hub_start_signal;
  logic hub_finish_signal;

  // Instancia de tu módulo FPHUB_adder sin modificar
  FPHUB_adder #(
    .M(M),
    .E(E)
  ) i_hub_adder (
    .start(hub_start_signal),
    .X(hub_X),
    .Y(hub_Y),
    .Z(hub_Z),
    .finish(hub_finish_signal)
  );

  // Lógica de mapeo para los operandos y el handshake
  assign hub_X = operands_i[1];
  assign hub_Y = operands_i[2];
  
  // Asume que el wrapper está siempre listo para aceptar datos
  assign in_ready_o = 1'b1;
  
  // Inicia la operación en tu módulo FPHUB_adder cuando se recibe una operación válida
  always @(posedge clk_i) begin
    if (rst_ni == 1'b0 || flush_i == 1'b1) begin
      hub_start_signal <= 1'b0;
    end else if (in_valid_i && in_ready_o) begin
      hub_start_signal <= 1'b1;
    end
  end

  // El resultado está listo cuando tu módulo FPHUB_adder termina
  assign out_valid_o = hub_finish_signal;
  assign result_o = hub_Z;

  // Los flags de estado deben ser manejados por tu módulo o por lógica de conversión
  assign status_o = '0; // Reemplazar con lógica de tu módulo
endmodule