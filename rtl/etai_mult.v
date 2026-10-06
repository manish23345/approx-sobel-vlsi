// ============================================================
// etai_mult.v
// Error-Tolerant Adder-based (ETAI) approximate multiplier.
//
// Unlike OSA (which approximates by throwing away low-order
// OPERAND bits), ETAI builds a real array multiplier -- explicit
// partial products, explicit row-by-row accumulation -- and
// approximates at the ADDER level: the lowest ERR_BITS columns of
// every row addition use a cheap approximate full adder that
// ignores its carry-in, instead of an exact full adder. Columns
// above ERR_BITS stay exact.
//
// Approximate full adder used here (a common, simple, published
// AFA variant):
//   sum  = a ^ b          (carry-in ignored)
//   cout = a & b          (carry-in ignored)
// This saves a gate level and a carry-in dependency per
// approximated bit, at the cost of an occasional 1-bit error
// exactly where expected: the low-order bits.
//
// Pin-compatible with exact_mult / osa_mult.
// ============================================================
`timescale 1ns/1ps

module etai_mult #(
    parameter W        = 8,   // operand width
    parameter ERR_BITS = 4    // number of low-order columns using
                               // the approximate adder (tune this)
) (
    input  wire signed [W-1:0]   a,
    input  wire signed [W-1:0]   b,
    output wire signed [2*W-1:0] product
);

    localparam AW = 2*W;

    // --- sign/magnitude split (same convention as osa_mult) ---
    wire         sign_a = a[W-1];
    wire         sign_b = b[W-1];
    wire [W-1:0] mag_a  = sign_a ? (~a + 1'b1) : a;
    wire [W-1:0] mag_b  = sign_b ? (~b + 1'b1) : b;

    // --- partial products: pp[row] = mag_a AND'd with bit 'row' of mag_b ---
    // (packed array, not unpacked -- gives Verilator/synthesis tools clean
    // per-element dependency tracking instead of treating the whole array
    // as one circularly-dependent blob)
    wire [W-1:0] pp [0:W-1] /*verilator split_var*/;
    genvar gi, gj;
    generate
        for (gi = 0; gi < W; gi = gi + 1) begin : pp_gen
            assign pp[gi] = mag_a & {W{mag_b[gi]}};
        end
    endgenerate

    // --- row-by-row accumulation, column-selective approximate adders ---
    wire [AW-1:0] acc [0:W-1] /*verilator split_var*/;
    assign acc[0] = {{(AW-W){1'b0}}, pp[0]};   // row 0: no addition needed

    generate
        for (gi = 1; gi < W; gi = gi + 1) begin : acc_stage
            wire [AW-1:0] shifted_pp = ({{(AW-W){1'b0}}, pp[gi]} << gi);
            /* verilator lint_off UNUSEDSIGNAL */
            wire [AW:0]   carry /*verilator split_var*/;
            /* verilator lint_on UNUSEDSIGNAL */
            wire [AW-1:0] sum_bits;

            assign carry[0] = 1'b0;

            for (gj = 0; gj < AW; gj = gj + 1) begin : bit_adder
                if (gj < ERR_BITS) begin : approx_bit
                    // approximate full adder: carry-in ignored
                    assign sum_bits[gj] = acc[gi-1][gj] ^ shifted_pp[gj];
                    assign carry[gj+1]  = acc[gi-1][gj] & shifted_pp[gj];
                end else begin : exact_bit
                    // exact full adder
                    assign sum_bits[gj] = acc[gi-1][gj] ^ shifted_pp[gj] ^ carry[gj];
                    assign carry[gj+1]  = (acc[gi-1][gj] & shifted_pp[gj])
                                         | (shifted_pp[gj] & carry[gj])
                                         | (acc[gi-1][gj] & carry[gj]);
                end
            end

            assign acc[gi] = sum_bits;
        end
    endgenerate

    wire [AW-1:0] mag_product_approx = acc[W-1];
    wire          result_sign        = sign_a ^ sign_b;
    assign product = result_sign ? (~mag_product_approx + 1'b1) : mag_product_approx;

endmodule
