/*Title: Main module FPHUB Adder

  Floating-point adder for HUB format.
*/

/* Module: FPHUB_adder
 
  Summary:
      Implements a floating-point adder for HUB format, supporting addition and subtraction of two operands.

  Parameters:
      M - Width of the mantissa.
      E - Width of the exponent.
      special_case - Number of special case identifiers (e.g., 0 = none, 1 = +inf, etc.).
      sign_mantissa_bit - Width of the sign bit added to mantissa extension.
      one_implicit_bit - Implicit leading one in normalized mantissas.
      ilsb_bit - Extra bit for rounding support (Implicit Least Significant Bit).
      extra_bits_mantissa - Total number of extra bits added to the mantissa.
 
  Ports:
      start - Initiates the operation.
      X - First operand in HUB floating-point format.
      Y - Second operand in HUB floating-point format.
      finish - Indicates the operation is complete.
      Z - Result of the floating-point addition.
 */
module FPHUB_adder #(
    parameter int M = 23,              
    parameter int E = 8,               
    parameter int special_case = 7,    
    parameter int sign_mantissa_bit   = 1,
    parameter int one_implicit_bit    = 1,
    parameter int ilsb_bit            = 1,
    parameter int extra_bits_mantissa = 1 + sign_mantissa_bit + one_implicit_bit + ilsb_bit
)
(
    input  logic start,             
    input  logic signed [E+M:0] X,  
    input  logic signed [E+M:0] Y,  
    output logic finish,            
    output logic [E+M:0] Z          
);

/* Section: Debbugging and Testing

 This section allows specifying test values for X and Y to facilitate debugging through simulation logs.
 By assigning specific values to X_prueba and Y_prueba, the module can identify these inputs during simulation.
 When the specified values match the inputs X and Y, detailed logs are generated to trace the internal operations.
 This mechanism is useful for verifying the behavior of the floating-point adder under controlled test cases.
*/

/* Variable: X_prueba
    Test value for X to trigger debug logs.
*/
logic [E+M:0] X_prueba;
assign X_prueba = 9'b011110011;

/* Variable: Y_prueba
    Test value for Y to trigger debug logs.
*/
logic [E+M:0] Y_prueba;
assign Y_prueba = 9'b111111000;


/* Section: Special Case Handling

 Detects if either operand is a special floating-point value (e.g., ±0, ±1, ±inf).
 A special case detector module identifies the category for each operand.
 If a special case is detected, a dedicated result is computed using a separate module.
 This mechanism ensures correct handling of exceptions before further computation.
 
 Modules:
     The modules used are:

        - <special_cases_detector>: Detects ones, zeros, and infinities in the operands.

        - <special_result_for_adder>: Computes the output for those special inputs for the sum or subtraction.
*/

/* Variable: special_result
    Stores the result of the operation when a special case is detected.
*/
logic [M+E:0] special_result;

/* Variable: X_special_case
    Encodes the type of special case for operand X.
*/
logic [$clog2(special_case)-1:0] X_special_case;

/* Variable: Y_special_case
    Encodes the type of special case for operand Y.
*/
logic [$clog2(special_case)-1:0] Y_special_case;

/* Variable: special_case_detected
    Flag indicating whether a special case has been detected.
*/
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

/*
Section: Exponent Difference Calculation

This section calculates the signed difference between the exponents of operands X and Y.
It also determines whether X has a greater exponent than Y, or if both are equal.
These signals are critical for preparing mantissas prior to alignment and arithmetic.

The calculation is performed using the external module <Exponent_difference>, which encapsulates
the logic for comparing and subtracting exponents while flagging their relationship.
*/

/* Variable: diff
   Signed difference between the exponents of X and Y.
   Used to determine how much the mantissas must be shifted.
*/
logic signed [E:0] diff;

/* Variable: diff_abs
   Absolute value of the exponent difference.
   Useful for determining shift amounts regardless of sign.
*/
logic [E:0] diff_abs;

/* Variable: X_greater_than_Y
   Flag indicating whether the exponent of X is greater than that of Y.
   Used to determine which mantissa is considered the major operand.
*/
logic X_greater_than_Y;

/* Variable: Ex_equal_Ey
   Flag indicating whether the exponents of X and Y are equal.
   Allows short-circuiting alignment logic when no shift is needed.
*/
logic Ex_equal_Ey;

Exponent_difference #(E) Exponent_difference_inst (
    .Ex(X[E+M-1:M]),
    .Ey(Y[E+M-1:M]),
    .dif(diff),
    .X_greater_than_Y(X_greater_than_Y),
    .Ex_equal_Ey(Ex_equal_Ey)
);


//--------------------------------------------------------------------------------------------------
// Declaración de las variables que determinan la operación efectiva y el signo del resultado
//--------------------------------------------------------------------------------------------------
logic subtraction, Sz;

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

/*
Section: Mantissa Alignment

This section aligns the minor mantissa (the one corresponding to the operand with the smaller exponent)
so that it can be correctly combined with the major mantissa in subsequent arithmetic.

The alignment is performed using the external module <shifter>, which takes the mantissa and the absolute
value of the exponent difference as inputs, and applies a right arithmetic shift. This prepares both operands
to be added or subtracted with the same exponent scale.
*/

/* Variable: M_minor_aligned
   Aligned version of the minor mantissa, shifted to match the exponent of the major operand.
   This is the result of applying a right arithmetic shift to the unaligned minor mantissa.
*/
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

/*
Section: Mantissa Operation

This section holds the result of the arithmetic operation between the aligned mantissas
(either an addition or subtraction, depending on operand signs).

The result may contain leading zeros and must later be normalized. Intermediate
results are also stored before and after normalization.
*/

/* Variable: M_result
   Raw result of the addition or subtraction between the aligned mantissas.
*/
logic signed [M+extra_bits_mantissa-1:0] M_result;

/* Variable: M_result_ready
   Result of mantissa operation, possibly passed through logic for post-processing.
   Ready to be normalized.
*/
logic signed [M+extra_bits_mantissa-1:0] M_result_ready;

/* Variable: M_normalize
   Mantissa value after normalization by left shifting to remove leading zeros.
*/
logic signed [M+extra_bits_mantissa-1:0] M_normalize;

/* Variable: result
   Final floating-point result before assignment to output.
*/
logic [E+M:0] result;

/* Variable: shift_LZA
   Amount of leading zeros detected by the LZD module, used to normalize the result.
*/
logic [$clog2(M+extra_bits_mantissa-sign_mantissa_bit-1):0] shift_LZA;

/* Variable: Ez_normalized
   Final exponent after subtracting the number of leading zeros from the original exponent.
*/
logic [E:0] Ez_normalized;

/*
Section: Leading Zero Detection and Normalization

This section uses the external module <LZD> (Leading Zero Detector) to count how many
leading zeros are present in the result of the mantissa operation.

The value *shift_LZA* is then used to normalize the mantissa by left shifting it,
and the exponent is adjusted accordingly to preserve numerical value.
*/

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
    $display("SUMADOR HUB");
    if (start) begin
        $display("INICIO DE SUMA");
        /*
        Section: Sign and Operation Selection

        Determines the sign of the result and the effective operation (addition or subtraction),
        based on the sign bits and exponent comparison of the operands.
        */

        /* Variable: Sz
        Sign of the result. It is taken from the operand with the greater exponent.
        */
        Sz = (X_greater_than_Y) ? X[E+M] : Y[E+M];

        /* Variable: subtraction
        Flag indicating whether the effective operation is a subtraction.
        Determined by XOR-ing the sign bits of the inputs.
        */
        subtraction = X[E+M] ^ Y[E+M];

        /*
        Section: ILSB Definition

        Defines the value of the Implicit Least Significant Bit (ILSB) based on special cases.
        For operands that represent ±1, the ILSB is set to 0 to represent their special encoding.
        */

        /* Variable: ilsb_x
        ILSB value for operand X. Set to 0 if X is +1 or -1, otherwise 1.
        */
        ilsb_x = (X_special_case == 5 || X_special_case == 6) ? 1'b0 : 1'b1;

        /* Variable: ilsb_y
        ILSB value for operand Y. Set to 0 if Y is +1 or -1, otherwise 1.
        */
        ilsb_y = (Y_special_case == 5 || Y_special_case == 6) ? 1'b0 : 1'b1;

        /*
        Section: Mantissa Construction

        Builds the major and minor mantissas by extending them with:

        - a sign extension field (*sign_mantissa_bit* zeros),
        - an implicit one for normalized numbers,
        - the actual mantissa bits,
        - the ILSB bit (it is zero for ±1),
        - and additional zero-padding to reach the desired length.

        The operand with the greater exponent is considered the major operand.
        */

        /* Variable: M_major
        Fully constructed mantissa of the operand with the greater exponent.
        This will not be shifted and directly participates in the addition.
        */
        M_major = (X_greater_than_Y) ? 
            { {sign_mantissa_bit{1'b0}}, {one_implicit_bit{1'b1}}, X[M-1:0], ilsb_x,
            {(extra_bits_mantissa - (sign_mantissa_bit+one_implicit_bit+ilsb_bit)){1'b0} } } :
            { {sign_mantissa_bit{1'b0}}, {one_implicit_bit{1'b1}}, Y[M-1:0], ilsb_y,
            {(extra_bits_mantissa - (sign_mantissa_bit+one_implicit_bit+ilsb_bit)){1'b0} } };

        /* Variable: M_minor
        Fully constructed mantissa of the operand with the smaller exponent.
        This will be aligned (shifted) before being added or subtracted.
        */
        M_minor = (X_greater_than_Y) ? 
            { {sign_mantissa_bit{1'b0}}, {one_implicit_bit{1'b1}}, Y[M-1:0], ilsb_y,
            {(extra_bits_mantissa - (sign_mantissa_bit+one_implicit_bit+ilsb_bit)){1'b0} } } :
            { {sign_mantissa_bit{1'b0}}, {one_implicit_bit{1'b1}}, X[M-1:0], ilsb_x,
            {(extra_bits_mantissa - (sign_mantissa_bit+one_implicit_bit+ilsb_bit)){1'b0} } };

        /*
        Section: Exponent and Special Case Detection

        Selects the exponent of the operand with the larger value as the initial exponent output.
        Also detects whether any operand represents a special case such as ±0 or ±infinity.
        */

        /* Variable: Ez
        Output exponent before normalization. It is taken from the operand with the greater exponent.
        */
        Ez = (X_greater_than_Y) ? X[E+M-1:M] : Y[E+M-1:M];

        /* Variable: special_case_detected.
        Flag set to 1 when either operand corresponds to a special value:
        specifically, positive/negative zero or positive/negative infinity.
        This disables the normal arithmetic path and triggers special result handling.
        */

        if ((X_special_case >= 1 && X_special_case <= 4) || (Y_special_case >= 1 && Y_special_case <= 4))
            special_case_detected = 1;
        else
            special_case_detected = 0;

        
        /*
        Section: Exponent Difference Absolute Value

        Computes the absolute value of the signed difference between the exponents.
        This is used to determine the amount of shift needed to align the mantissas.
        */

        /* Variable: diff_abs
        Absolute value of the exponent difference *diff*.
        Required for proper alignment of the minor mantissa.
        */
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
        
        /*
        Section: Mantissa Preparation for Subtraction

        If subtraction is needed, the minor mantissa is inverted and prepared for
        two's complement adjustment. This step ensures correct subtraction handling
        based on the known fixed position of the ILSB.
        */

        /* Variable: M_minor_ready
        Adjusted minor mantissa to be used in the arithmetic operation.
        If subtraction is active, its bits are conditionally inverted
        to prepare for two's complement computation.
        */
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

        /*
        Section: Mantissa Addition

        Performs the addition between the major and (aligned) minor mantissas.
        This is the core arithmetic operation of the adder module.
        */

        /* Variable: M_result
        Raw result of the mantissa addition.
        May require sign correction and normalization depending on the outcome.
        */        
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

        /*
        Section: Result Sign Correction

        If the result is negative (i.e., MSB is 1) and subtraction was performed,
        the result is converted to its two's complement form and the result sign is flipped.
        */

        /* Variable: M_result_ready
        Final version of the mantissa result after correcting the sign if necessary.
        */
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
        
        /*
        Section: Normalization and Exponent Adjustment

        This section handles the normalization of the mantissa after the addition or subtraction operation.

        - First, the exponent *Ez* is extended to *Ez_normalized* with one extra MSB to handle potential overflow.
        - The mantissa result (*M_result_ready*) is copied to *M_normalize* for further adjustment.

        If the operation was a subtraction:

        - The number of leading zeros in the result (given by *shift_LZA*) is used to determine how much to left-shift *M_normalize*.
        - If *shift_LZA* indicates that all bits are zero (i.e., X and Y cancel each other), the result is set to zero and the exponent is cleared.
        - Otherwise, *Ez_normalized* is decremented by *shift_LZA*. If this causes an underflow (MSB of exponent becomes 1), the result is flushed to zero.

        If the operation was an addition:
        
        - If the MSB of the mantissa is 1 after the operation (indicating an overflow), the mantissa is right-shifted and *Ez_normalized* is incremented.
        - If incrementing the exponent causes overflow (MSB set), a saturating value is assigned to both the exponent and the mantissa.

        At the end of this process, *M_normalize* contains the properly aligned and normalized mantissa,
        and *Ez_normalized* holds the adjusted exponent, both ready to be assembled into the final result.
        */
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
        
        /*
        Section: Final Result Assembly

        Assembles the final floating-point result in custom HUB format by concatenating:

        - The final sign bit *Sz*.
        - The adjusted exponent *Ez_normalized*, dropping its MSB (used only for overflow detection).
        - The normalized mantissa, taking the M most significant bits starting just after the implicit and sign bits.

        This forms the output result that is later selected if no special case was detected.
        */

        /* Variable: result
        Final output in custom HUB format, combining sign, exponent, and normalized mantissa.
        */
        result = {Sz, Ez_normalized[E-1:0], M_normalize[M+extra_bits_mantissa-3 : extra_bits_mantissa-2]};
        
        if (X == X_prueba && Y == Y_prueba) begin
            $display("Z = %b", result);
        end
    end
end

/*
Section: Final Output Selection and Completion Flag

Determines the final result to output and signals the completion of the operation.

- If a special case was detected earlier (e.g., ±0, ±inf), the precomputed *special_result* is selected.
- Otherwise, the normal arithmetic result is used.
- The *finish* flag is set to 1 to indicate that the computation has completed.
*/

/* Variable: Z
   Final output of the module. Chooses between a special result or the normal computed result.
*/
assign Z = (special_case_detected) ? special_result : result;

/* Variable: finish
   Control signal set to 1 when the operation is complete.
*/
assign finish = 1'b1;


endmodule