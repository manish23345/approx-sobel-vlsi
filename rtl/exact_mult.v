// ============================================================
// exact_mult.v
// Baseline exact multiplier. Pin-compatible with all approximate
// multiplier variants (osa_mult, trunc_mult, etc.) so it can be
// swapped in/out of sobel_mac without changing any other module.
// ============================================================
`timescale 1ns/1ps

module exact_mult #(
    parameter W = 8   // operand width
) (
    input  wire signed [W-1:0]   a,
    input  wire signed [W-1:0]   b,
    output wire signed [2*W-1:0] product
);

    assign product = a * b;

endmodule
