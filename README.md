# Floating-Point Adder (HUB Format)

## Overview

This module implements a custom **floating-point adder** using a simplified, educational format referred to as **HUB**. The design supports normalized numbers only, and handles key IEEE 754-style special cases like ±zero, ±infinity, and ±one. The goal is to offer a modular, understandable architecture for floating-point addition in digital systems.

The core component (`my_FPHUB_adderv1`) takes two inputs in HUB format and returns a correctly computed sum, managing alignment, normalization, overflow, and special cases through a series of coordinated submodules.

---

## HUB Format

Each operand is composed of:

- 1-bit **sign**.
- E-bit **exponent**.
- M-bit **mantissa**, where the leading 1 is implicit (normalized form).

There are **no subnormals**. Even when the exponent is zero, the implicit one is still present in the mantissa.

---

## Key Features

- **Modular architecture**: The design is split into dedicated, self-contained submodules.
- **Special case support**: Recognizes and handles ±0, ±1, and ±∞.
- **Two’s complement subtraction**: Proper handling of signed operations.
- **Leading zero anticipation (LZA)**: Enables accurate normalization.
- **Debug hooks**: Includes `X_prueba` and `Y_prueba` test hooks for simulation logging.

---

## Submodules

- [`Exponent_difference`](#Exponent_difference): Computes signed difference between exponents and determines which operand is greater.
- [`special_cases_detector`](#special_cases_detector): Classifies each operand (e.g., normal, zero, infinity, one).
- [`special_result_for_adder`](#special_result_for_adder): Produces predefined result when special cases are present.
- [`shifter`](#shifter): Aligns the minor mantissa by performing arithmetic right shifts.
- [`LZD`](#LZD): Leading Zero Detector for result normalization.

---

## Result Composition

After normalization and overflow control, the final result is assembled from:

- Sign bit (`Sz`)
- Normalized exponent (`Ez_normalized`)
- Most significant bits of the mantissa (`M_normalize`)

The output is a valid HUB-formatted floating-point number.

---

## Usage

To integrate the adder into your own project:

1. **Instantiate** the top module `my_FPHUB_adderv1`, or connect its submodules individually for advanced control.
2. **Provide inputs** `X` and `Y` using the custom HUB format: `{sign, exponent, mantissa}`.
3. **Monitor** the `finish` output to detect when the operation has completed.
4. **Read** the output `Z`, which will contain the final result in HUB format.

### Parameterization

The adder is **fully parameterizable**:
- You can adjust the number of exponent bits (`E`) and mantissa bits (`M`) via parameters.
- By default, the module uses **E = 8** and **M = 23**, which corresponds to a 32-bit floating-point format (1 + 8 + 23 bits).
- This allows easy scaling of precision for custom applications, embedded systems, or educational experiments.

---

## Simulation Support

When `X_prueba` and `Y_prueba` are matched, detailed `$display` logs are printed to facilitate debugging during testbench simulation.

---

## License

This project is intended for educational and research purposes.
Feel free to adapt it to your own system design work or coursework.
