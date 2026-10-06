// ============================================================
// gradient_mag.v
// Combines Gx, Gy into a gradient magnitude using the standard
// hardware-friendly approximation |Gx| + |Gy| (avoids sqrt).
// Output is saturated to 8 bits (0-255) to stay a valid pixel.
// ============================================================
`timescale 1ns/1ps

module gradient_mag #(
    parameter IW = 13,  // input width (must match sobel_mac's gx/gy width)
    parameter OW = 8    // output pixel width
) (
    input  wire signed [IW-1:0] gx,
    input  wire signed [IW-1:0] gy,
    output wire [OW-1:0]        mag
);

    wire [IW-1:0] abs_gx = gx[IW-1] ? (-gx) : gx;
    wire [IW-1:0] abs_gy = gy[IW-1] ? (-gy) : gy;
    wire [IW:0]   sum    = abs_gx + abs_gy;  // one extra bit for safety

    // saturate to [0,255]
    wire [IW:0] max_val = {{(IW+1-OW){1'b0}}, {OW{1'b1}}};
    assign mag = (sum > max_val) ? {OW{1'b1}} : sum[OW-1:0];

endmodule
