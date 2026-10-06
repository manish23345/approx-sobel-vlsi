// ============================================================
// sobel_mac.v
// Computes Gx and Gy for one 3x3 pixel window using the standard
// Sobel kernels. Each of the 18 multiplications (9 taps x 2
// kernels) goes through mult_wrapper, so the entire datapath's
// multiplier variant is controlled from one place.
//
// Pixel values: unsigned 8-bit (0-255), sign-extended to 9 bits
// for signed multiplication.
// Kernel values: {-2,-1,0,1,2}, small signed constants.
// ============================================================
`timescale 1ns/1ps

module sobel_mac #(
    parameter PW       = 8,   // pixel width
    parameter MULT_SEL = 0,   // 0 = exact, 1 = OSA  (see mult_wrapper.v)
    parameter OSA_SEG       = 4,
    parameter ETAI_ERR_BITS = 4
) (
    input  wire [PW-1:0]        p00, p01, p02,
    input  wire [PW-1:0]        p10, p11, p12,
    input  wire [PW-1:0]        p20, p21, p22,
    output wire signed [PW+4:0] gx,
    output wire signed [PW+4:0] gy
);

    localparam MW = PW + 1; // operand width fed into multiplier (room for sign)

    // Sobel kernels
    // Kx:                      Ky:
    //  -1  0  1                 -1 -2 -1
    //  -2  0  2                  0  0  0
    //  -1  0  1                  1  2  1

    wire signed [MW-1:0] px00 = {1'b0, p00}; wire signed [MW-1:0] px01 = {1'b0, p01}; wire signed [MW-1:0] px02 = {1'b0, p02};
    /* verilator lint_off UNUSEDSIGNAL */
    wire signed [MW-1:0] px10 = {1'b0, p10}; wire signed [MW-1:0] px11 = {1'b0, p11}; wire signed [MW-1:0] px12 = {1'b0, p12};
    /* verilator lint_on UNUSEDSIGNAL */
    wire signed [MW-1:0] px20 = {1'b0, p20}; wire signed [MW-1:0] px21 = {1'b0, p21}; wire signed [MW-1:0] px22 = {1'b0, p22};

    // --- Gx taps (coefficients: -1,0,1,-2,0,2,-1,0,1) ---
    wire signed [2*MW-1:0] gx00, gx02, gx10, gx12, gx20, gx22;
    mult_wrapper #(.W(MW), .MULT_SEL(MULT_SEL), .OSA_SEG(OSA_SEG), .ETAI_ERR_BITS(ETAI_ERR_BITS)) m_gx00 (.a(px00), .b(-9'sd1), .product(gx00));
    mult_wrapper #(.W(MW), .MULT_SEL(MULT_SEL), .OSA_SEG(OSA_SEG), .ETAI_ERR_BITS(ETAI_ERR_BITS)) m_gx02 (.a(px02), .b( 9'sd1), .product(gx02));
    mult_wrapper #(.W(MW), .MULT_SEL(MULT_SEL), .OSA_SEG(OSA_SEG), .ETAI_ERR_BITS(ETAI_ERR_BITS)) m_gx10 (.a(px10), .b(-9'sd2), .product(gx10));
    mult_wrapper #(.W(MW), .MULT_SEL(MULT_SEL), .OSA_SEG(OSA_SEG), .ETAI_ERR_BITS(ETAI_ERR_BITS)) m_gx12 (.a(px12), .b( 9'sd2), .product(gx12));
    mult_wrapper #(.W(MW), .MULT_SEL(MULT_SEL), .OSA_SEG(OSA_SEG), .ETAI_ERR_BITS(ETAI_ERR_BITS)) m_gx20 (.a(px20), .b(-9'sd1), .product(gx20));
    mult_wrapper #(.W(MW), .MULT_SEL(MULT_SEL), .OSA_SEG(OSA_SEG), .ETAI_ERR_BITS(ETAI_ERR_BITS)) m_gx22 (.a(px22), .b( 9'sd1), .product(gx22));
    // center column (p01,p11,p21) has coefficient 0 -> skip entirely

    /* verilator lint_off UNUSEDSIGNAL */
    wire signed [2*MW-1:0] gx_full = gx00 + gx02 + gx10 + gx12 + gx20 + gx22;
    /* verilator lint_on UNUSEDSIGNAL */
    assign gx = gx_full[PW+4:0];  // mathematically fits (max |Gx| needs 13 bits); upper bits deliberately unused

    // --- Gy taps (coefficients: -1,-2,-1,1,2,1) ---
    wire signed [2*MW-1:0] gy00, gy01, gy02, gy20, gy21, gy22;
    mult_wrapper #(.W(MW), .MULT_SEL(MULT_SEL), .OSA_SEG(OSA_SEG), .ETAI_ERR_BITS(ETAI_ERR_BITS)) m_gy00 (.a(px00), .b(-9'sd1), .product(gy00));
    mult_wrapper #(.W(MW), .MULT_SEL(MULT_SEL), .OSA_SEG(OSA_SEG), .ETAI_ERR_BITS(ETAI_ERR_BITS)) m_gy01 (.a(px01), .b(-9'sd2), .product(gy01));
    mult_wrapper #(.W(MW), .MULT_SEL(MULT_SEL), .OSA_SEG(OSA_SEG), .ETAI_ERR_BITS(ETAI_ERR_BITS)) m_gy02 (.a(px02), .b(-9'sd1), .product(gy02));
    mult_wrapper #(.W(MW), .MULT_SEL(MULT_SEL), .OSA_SEG(OSA_SEG), .ETAI_ERR_BITS(ETAI_ERR_BITS)) m_gy20 (.a(px20), .b( 9'sd1), .product(gy20));
    mult_wrapper #(.W(MW), .MULT_SEL(MULT_SEL), .OSA_SEG(OSA_SEG), .ETAI_ERR_BITS(ETAI_ERR_BITS)) m_gy21 (.a(px21), .b( 9'sd2), .product(gy21));
    mult_wrapper #(.W(MW), .MULT_SEL(MULT_SEL), .OSA_SEG(OSA_SEG), .ETAI_ERR_BITS(ETAI_ERR_BITS)) m_gy22 (.a(px22), .b( 9'sd1), .product(gy22));
    // middle row (p10,p11,p12) has coefficient 0 -> skip entirely

    /* verilator lint_off UNUSEDSIGNAL */
    wire signed [2*MW-1:0] gy_full = gy00 + gy01 + gy02 + gy20 + gy21 + gy22;
    /* verilator lint_on UNUSEDSIGNAL */
    assign gy = gy_full[PW+4:0];

endmodule
