// ============================================================
// top_exact.v
// Fixed-configuration synthesis top: exact multiplier.
// DC needs one unambiguous top module per run (no command-line
// parameter override like the simulator's -P flag), so each
// variant gets its own tiny wrapper that just pins MULT_SEL.
// ============================================================
`timescale 1ns/1ps

module top_exact (
    input  wire [7:0] p00, p01, p02,
    input  wire [7:0] p10, p11, p12,
    input  wire [7:0] p20, p21, p22,
    output wire [7:0] out_pixel
);

    sobel_top #(.PW(8), .MULT_SEL(0)) u_sobel (
        .p00(p00), .p01(p01), .p02(p02),
        .p10(p10), .p11(p11), .p12(p12),
        .p20(p20), .p21(p21), .p22(p22),
        .out_pixel(out_pixel)
    );

endmodule
