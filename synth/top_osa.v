// ============================================================
// top_osa.v
// Fixed-configuration synthesis top: OSA approximate multiplier.
// Change OSA_SEG here to synthesize a different point on your
// area/quality tradeoff curve (match whatever SEG value you
// quote the PSNR for in osa_seg_sweep.py's output).
// ============================================================
`timescale 1ns/1ps

module top_osa (
    input  wire [7:0] p00, p01, p02,
    input  wire [7:0] p10, p11, p12,
    input  wire [7:0] p20, p21, p22,
    output wire [7:0] out_pixel
);

    sobel_top #(.PW(8), .MULT_SEL(1), .OSA_SEG(4)) u_sobel (
        .p00(p00), .p01(p01), .p02(p02),
        .p10(p10), .p11(p11), .p12(p12),
        .p20(p20), .p21(p21), .p22(p22),
        .out_pixel(out_pixel)
    );

endmodule
