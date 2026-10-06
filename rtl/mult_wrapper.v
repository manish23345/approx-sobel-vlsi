// ============================================================
// mult_wrapper.v
// Single point of control for which multiplier variant a datapath
// uses, selected via the MULT_SEL parameter (not a global compile
// flag) so that an exact-multiplier instance and an approximate-
// multiplier instance can coexist in the SAME simulation -- this
// is what lets a testbench compare them directly, pixel for pixel,
// instead of requiring two separate simulation runs.
//
// MULT_SEL = 0 -> exact_mult
// MULT_SEL = 1 -> osa_mult  (SEG settable via OSA_SEG)
// MULT_SEL = 2 -> etai_mult (ERR_BITS settable via ETAI_ERR_BITS)
//
// For an actual synthesis run you still pick ONE value and
// synthesize that configuration (Design Compiler resolves the
// generate-case at elaboration time, same as any other parameter).
// ============================================================
`timescale 1ns/1ps

module mult_wrapper #(
    parameter W             = 8,
    parameter MULT_SEL      = 0,   // 0 = exact, 1 = OSA, 2 = ETAI
    parameter OSA_SEG       = 4,
    parameter ETAI_ERR_BITS = 4
) (
    input  wire signed [W-1:0]   a,
    input  wire signed [W-1:0]   b,
    output wire signed [2*W-1:0] product
);

    generate
        if (MULT_SEL == 0) begin : g_exact
            exact_mult #(.W(W)) u_mult (.a(a), .b(b), .product(product));
        end else if (MULT_SEL == 1) begin : g_osa
            osa_mult #(.W(W), .SEG(OSA_SEG)) u_mult (.a(a), .b(b), .product(product));
        end else begin : g_etai
            etai_mult #(.W(W), .ERR_BITS(ETAI_ERR_BITS)) u_mult (.a(a), .b(b), .product(product));
        end
    endgenerate

endmodule
