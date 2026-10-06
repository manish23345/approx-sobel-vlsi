// ============================================================
// sobel_top.v
// Single-pixel-per-call Sobel operator: takes a 3x3 window,
// returns the edge-magnitude output pixel. This is the module
// instantiated once per output pixel by the testbench (Week 3-4
// functional-correctness stage). Streaming line-buffer wrapper
// for continuous video-rate operation is a later synthesis-stage
// addition and is not needed to validate the arithmetic.
// ============================================================
`timescale 1ns/1ps

module sobel_top #(
    parameter PW       = 8,
    parameter MULT_SEL = 0,   // 0 = exact, 1 = OSA  (see mult_wrapper.v)
    parameter OSA_SEG       = 4,
    parameter ETAI_ERR_BITS = 4
) (
    input  wire [PW-1:0] p00, p01, p02,
    input  wire [PW-1:0] p10, p11, p12,
    input  wire [PW-1:0] p20, p21, p22,
    output wire [PW-1:0] out_pixel
);

    localparam GW = PW + 5; // gx/gy width, matches sobel_mac's output width

    wire signed [GW-1:0] gx, gy;

    sobel_mac #(.PW(PW), .MULT_SEL(MULT_SEL), .OSA_SEG(OSA_SEG), .ETAI_ERR_BITS(ETAI_ERR_BITS)) u_mac (
        .p00(p00), .p01(p01), .p02(p02),
        .p10(p10), .p11(p11), .p12(p12),
        .p20(p20), .p21(p21), .p22(p22),
        .gx(gx), .gy(gy)
    );

    gradient_mag #(.IW(GW), .OW(PW)) u_mag (
        .gx(gx), .gy(gy), .mag(out_pixel)
    );

endmodule
