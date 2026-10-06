// ============================================================
// segment_extract.v
// Given a value's leading-one position, extracts the top SEG bits
// starting at that position (the "meaningful segment"). Bits below
// the segment window are discarded -- this truncation is exactly
// where OSA's approximation error comes from. Also returns the
// shift amount needed to put the segment's product back in the
// right place after a small exact multiply.
// ============================================================
`timescale 1ns/1ps

module segment_extract #(
    parameter W   = 8,
    parameter SEG = 4
) (
    input  wire [W-1:0]            in,
    input  wire [$clog2(W)-1:0]    msb_pos,
    input  wire                    valid,
    output reg  [SEG-1:0]          seg,
    output reg  [$clog2(W)-1:0]    shift
);

    /* verilator lint_off UNUSEDSIGNAL */
    reg [W-1:0] shifted_in;
    /* verilator lint_on UNUSEDSIGNAL */

    always @(*) begin
        seg        = {SEG{1'b0}};
        shift      = {$clog2(W){1'b0}};
        shifted_in = {W{1'b0}};
        if (valid) begin
            if (msb_pos >= (SEG-1)) begin
                // enough significant bits to fill a full segment window
                shift      = msb_pos - (SEG-1);
                shifted_in = (in >> shift);
                seg        = shifted_in[SEG-1:0];  // top SEG bits around msb_pos (explicit slice: deliberate truncation)
            end else begin
                // value itself is smaller than the segment window ->
                // no truncation needed, represent it exactly
                shift = {$clog2(W){1'b0}};
                seg   = in[SEG-1:0];
            end
        end
    end

endmodule
