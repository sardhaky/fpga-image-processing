module sobel #(
    parameter IMG_W = 4
)(
    input  wire        clk,
    input  wire        rst,
    input  wire        pixel_valid,
    input  wire [7:0]  pixel_in,

    output reg  [7:0]  edge_out,
    output reg         out_valid
);

    // 3x3 window wires from line buffer
    wire [7:0] w00, w01, w02;
    wire [7:0] w10, w11, w12;
    wire [7:0] w20, w21, w22;
    wire       window_valid;

    line_buffer #(.WIDTH(8), .IMG_W(IMG_W)) lb (
        .clk(clk), .rst(rst),
        .pixel_valid(pixel_valid),
        .pixel_in(pixel_in),
        .w00(w00), .w01(w01), .w02(w02),
        .w10(w10), .w11(w11), .w12(w12),
        .w20(w20), .w21(w21), .w22(w22),
        .window_valid(window_valid)
    );

    // Signed intermediate values
    reg signed [10:0] Gx, Gy;
    reg        [10:0] Gx_abs, Gy_abs, G_sum;

    always @(posedge clk) begin
        if (rst) begin
            edge_out  <= 0;
            out_valid <= 0;
        end else begin
            out_valid <= window_valid;

            if (window_valid) begin
                // Gx = (-w00 + w02) + 2*(-w10 + w12) + (-w20 + w22)
                Gx = (-$signed({1'b0, w00}) + $signed({1'b0, w02}))
                   + ((-$signed({1'b0, w10}) + $signed({1'b0, w12})) << 1)
                   + (-$signed({1'b0, w20}) + $signed({1'b0, w22}));

                // Gy = (-w00 - 2*w01 - w02) + (w20 + 2*w21 + w22)
                Gy = (-$signed({1'b0, w00}) - ($signed({1'b0, w01}) << 1) - $signed({1'b0, w02}))
                   + ( $signed({1'b0, w20}) + ($signed({1'b0, w21}) << 1) + $signed({1'b0, w22}));

                // Absolute values
                Gx_abs = (Gx < 0) ? -Gx : Gx;
                Gy_abs = (Gy < 0) ? -Gy : Gy;

                // Sum and clamp to 8 bits
                G_sum = Gx_abs + Gy_abs;
                edge_out <= (G_sum > 255) ? 255 : G_sum[7:0];
            end
        end
    end

endmodule