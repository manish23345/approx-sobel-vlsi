// ============================================================
// osa_mult.v
// Overlapped Segmentation Approximate (OSA) multiplier.
//
// Idea: instead of multiplying the full W-bit magnitudes exactly,
// find each operand's leading one, extract a small SEG-bit segment
// around it, multiply ONLY the two small segments exactly (a much
// cheaper SEGxSEG multiply), then shift the result back into place.
// Bits below the segment window are dropped -> deliberate, bounded
// approximation error concentrated in low-significance bits.
//
// Pin-compatible with exact_mult: same a/b/product ports, so it
// drops straight into mult_wrapper.v / sobel_mac.v with no other
// changes.
// ============================================================
`timescale 1ns/1ps

module osa_mult #(
    parameter W   = 8,   // operand width
    parameter SEG = 4    // segment width (tune this: smaller SEG =
                          // more approximation, more area/power savings)
) (
    input  wire signed [W-1:0]   a,
    input  wire signed [W-1:0]   b,
    output wire signed [2*W-1:0] product
);

    localparam SW = $clog2(W);

    // --- sign/magnitude split (OSA operates on unsigned magnitudes) ---
    wire                sign_a = a[W-1];
    wire                sign_b = b[W-1];
    wire [W-1:0]        mag_a  = sign_a ? (~a + 1'b1) : a;
    wire [W-1:0]        mag_b  = sign_b ? (~b + 1'b1) : b;

    // --- find leading one in each magnitude ---
    wire [SW-1:0] pos_a, pos_b;
    wire          valid_a, valid_b;

    leading_one_detector #(.W(W)) lod_a (.in(mag_a), .pos(pos_a), .valid(valid_a));
    leading_one_detector #(.W(W)) lod_b (.in(mag_b), .pos(pos_b), .valid(valid_b));

    // --- extract SEG-bit segments + their shift amounts ---
    wire [SEG-1:0] seg_a, seg_b;
    wire [SW-1:0]  shift_a, shift_b;

    segment_extract #(.W(W), .SEG(SEG)) ext_a
        (.in(mag_a), .msb_pos(pos_a), .valid(valid_a), .seg(seg_a), .shift(shift_a));
    segment_extract #(.W(W), .SEG(SEG)) ext_b
        (.in(mag_b), .msb_pos(pos_b), .valid(valid_b), .seg(seg_b), .shift(shift_b));

    // --- small exact multiply on just the segments ---
    wire [2*SEG-1:0] seg_product = seg_a * seg_b;

    // --- reconstruct approximate magnitude product ---
    wire [SW:0] total_shift = shift_a + shift_b;  // extra bit: sum can exceed SW range
    wire [2*W-1:0] mag_product_approx =
        (valid_a && valid_b)
            ? ({{(2*W-2*SEG){1'b0}}, seg_product} << total_shift)
            : {2*W{1'b0}};

    // --- restore sign ---
    wire result_sign = sign_a ^ sign_b;
    assign product = result_sign ? (~mag_product_approx + 1'b1) : mag_product_approx;

endmodule
