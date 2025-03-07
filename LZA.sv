`timescale 1ns / 1ps
// Real LZA module with a hierarchical (prefix tree) network
// Parameters:
//   M: total input width (e.g., 32 bits)
//   GROUP_SIZE: number of bits per group (we use 4 in this example)
//   NUM_GROUPS: number of groups = M / GROUP_SIZE
//   SHIFT_WIDTH: width of the shift counter = log2(M)
module LZA #(
  parameter M = 23,
  parameter GROUP_SIZE  = 5,
  parameter NUM_GROUPS  = (M+2) / GROUP_SIZE,
  parameter SHIFT_WIDTH = $clog2(M)
)(
  input  logic [M+1:0] A,         // Mantissa part or value A
  input  logic [M+1:0] B,         // Mantissa part or value B
  output logic [SHIFT_WIDTH-1:0] shift_amt  // Number of bits to shift (leading zero count)
);

  // --------------------------------------------------------------
  // Step 1: Calculate the G, P, and Z signals for each bit.
  // --------------------------------------------------------------
  // These signals are computed bit by bit in parallel.
  logic [M+1:0] G, P, Z;
  genvar i;
  generate
    for (i = 0; i <= M+1; i = i + 1) begin : gpz_gen
      // G[i] is 1 if A[i] is 1 and B[i] is 0.
      assign G[i] = A[i] & ~B[i];
      // Z[i] is 1 if A[i] is 0 and B[i] is 1.
      assign Z[i] = ~A[i] & B[i];
      
      // Since we are not using P at the moment, we omit it.
      // P[i] is 1 if A[i] and B[i] are equal.
      //assign P[i] = ~(A[i] ^ B[i]);  // or A[i] ~^ B[i]
    end
  endgenerate

  // Define the "effective" vector that marks the positions where a difference is generated
  // (either by G or by Z).
  logic [M+1:0] effective;
  assign effective = G | Z;

  // --------------------------------------------------------------
  // Step 2: Group the 'effective' vector into groups of GROUP_SIZE bits.
  // For each group, compute:
  //   - group_or: OR of all bits in the group (1 if there is any effective bit)
  //   - group_first_index: local position of the first effective bit within the group
  // --------------------------------------------------------------
  logic [NUM_GROUPS-1:0] group_or;
  // We use an array of size NUM_GROUPS to store the local index of each group.
  logic [$clog2(GROUP_SIZE)-1:0] group_first_index [NUM_GROUPS-1:0];

  genvar j;
  generate
    for (j = 0; j < NUM_GROUPS; j = j + 1) begin : group_proc
      // Select the bits that belong to group j.
      // The notation [ (j+1)*GROUP_SIZE-1 -: GROUP_SIZE ] selects GROUP_SIZE bits
      // starting at (j+1)*GROUP_SIZE-1 and counting down.
      wire [GROUP_SIZE-1:0] grp = effective[(j+1)*GROUP_SIZE-1 -: GROUP_SIZE];

      // group_or is 1 if at least one of the bits in the group is 1.
      assign group_or[j] = |grp;

      // Now implement a small priority encoder for the group.
      // It is assumed that within the group, the most significant bit has index 0.
      // The "casez" allows using patterns with ? to ignore some bits.
      always_comb begin
        casez (grp)
            // If the first bit is 1
            5'b1????: group_first_index[j] = 0;
            // If bit 0 is 0 and bit 1 is 1
            5'b01???: group_first_index[j] = 1;
            // If bit 0 and bit 1 are 0, but bit 2 is 1
            5'b001??: group_first_index[j] = 2;
            // If bit 0, 1, and 2 are 0, but bit 3 is 1
            5'b0001?: group_first_index[j] = 3;
            // If bit 0, 1, 2 and 3 are 0, but bit 4 is 1
            5'b00001: group_first_index[j] = 4;
            // Default case
            default: group_first_index[j] = 0;
        endcase
      end
    end
  endgenerate

  // --------------------------------------------------------------
  // Step 3: Determine, at the group level, which is the first group that has
  //         at least one effective bit. This is a priority encoder over 'group_or'.
  // --------------------------------------------------------------
  // The vector group_or is scanned from the most significant group (MSB)
  // to the least significant group (LSB) and the first group with group_or == 1 is selected.
  function automatic [SHIFT_WIDTH-1:0] leading_group(input logic [NUM_GROUPS-1:0] vec);
    integer k;
    begin
      // By default, if no group has effective bits, assume 0.
      leading_group = 0;
      // Scan from MSB to LSB (the MSB corresponds to the highest-weight group)
      for (k = NUM_GROUPS-1; k >= 0; k = k - 1) begin
        if (vec[k]) begin
          leading_group = k;
          break;
        end
      end
    end
  endfunction

  logic [SHIFT_WIDTH-1:0] sel_group, effective_index;
  logic LZA_carry;
  assign sel_group = leading_group(group_or);

  // --------------------------------------------------------------
  // Step 4: Calculate the final shift amount.
  // Combine the number of complete groups without information and the
  // local position within the active group.
  // shift_amt = (selected group * GROUP_SIZE) + (local index within the group)
  // --------------------------------------------------------------
  
  //assign shift_amt = M + 1 - (sel_group * GROUP_SIZE + (sel_group - group_first_index[sel_group]));
  //assign shift_amt = M - (sel_group * GROUP_SIZE + (GROUP_SIZE - 1 - group_first_index[sel_group]));
  always_comb begin
    effective_index = sel_group * GROUP_SIZE + (GROUP_SIZE - 1 - group_first_index[sel_group]);
    LZA_carry = (Z[effective_index - 1] == 1'b1) ? 1'b1 : 1'b0;
    shift_amt = M + 1 - effective_index + LZA_carry;
  end
endmodule