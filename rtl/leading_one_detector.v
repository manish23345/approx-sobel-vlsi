// ============================================================
// leading_one_detector.v
// Combinational priority encoder: finds the bit position of the
// most-significant '1' in an unsigned W-bit value.
// Used by osa_mult to locate where the "meaningful" segment of
// each operand's magnitude begins.
// ============================================================
`timescale 1ns/1ps

module leading_one_detector #(
    parameter W = 8
) (
    input  wire [W-1:0]            in,
    output reg  [$clog2(W)-1:0]    pos,    // bit position of leading 1
    output reg                     valid   // 0 if in == 0 (no leading one)
);

    integer i;
    always @(*) begin
        pos   = {$clog2(W){1'b0}};
        valid = 1'b0;
        for (i = W-1; i >= 0; i = i-1) begin
            if (in[i] && !valid) begin
                pos   = i[$clog2(W)-1:0];
                valid = 1'b1;
            end
        end
    end

endmodule
