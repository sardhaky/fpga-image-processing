module harris #(
    parameter IMG_W    = 128,
    parameter THRESHOLD = 50000
)(
    input  wire        clk, rst,
    input  wire        pixel_valid,
    input  wire [7:0]  pixel_in,
    output reg  [7:0]  corner_out,
    output reg         out_valid
);
    // ── Stage 1: Sobel on 3×3 window ─────────────────────────────
    wire [7:0] w00,w01,w02,w10,w11,w12,w20,w21,w22;
    wire       win1_valid;

    line_buffer #(.WIDTH(8),.IMG_W(IMG_W)) lb1(
        .clk(clk),.rst(rst),
        .pixel_valid(pixel_valid),.pixel_in(pixel_in),
        .w00(w00),.w01(w01),.w02(w02),
        .w10(w10),.w11(w11),.w12(w12),
        .w20(w20),.w21(w21),.w22(w22),
        .window_valid(win1_valid)
    );

    // Sobel gradients (signed, up to ±1020)
    reg signed [10:0] Gx_s, Gy_s;

    // Gradient products as 8-bit (scaled) for second stage
    reg [7:0] Gx2_scaled, Gy2_scaled, GxGy_scaled;
    reg signed [21:0] Gx2_full, Gy2_full, GxGy_full;

    always @(posedge clk) begin
        if (rst) begin
            Gx_s <= 0; Gy_s <= 0;
            Gx2_scaled <= 0; Gy2_scaled <= 0; GxGy_scaled <= 0;
        end else if (win1_valid) begin
            Gx_s = (-$signed({1'b0,w00}) + $signed({1'b0,w02}))
                 + ((-$signed({1'b0,w10}) + $signed({1'b0,w12})) <<< 1)
                 + (-$signed({1'b0,w20}) + $signed({1'b0,w22}));

            Gy_s = (-$signed({1'b0,w00}) - ($signed({1'b0,w01})<<<1) - $signed({1'b0,w02}))
                 + ( $signed({1'b0,w20}) + ($signed({1'b0,w21})<<<1) + $signed({1'b0,w22}));

            // Scale products to 8-bit (shift right 11 so max ~255)
            Gx2_full  = Gx_s * Gx_s;
            Gy2_full  = Gy_s * Gy_s;
            GxGy_full = Gx_s * Gy_s;

            Gx2_scaled  <= (Gx2_full  > 22'sd261120) ? 8'd255 : Gx2_full[17:10];
            Gy2_scaled  <= (Gy2_full  > 22'sd261120) ? 8'd255 : Gy2_full[17:10];
            // GxGy can be negative — store absolute value
            begin : gxgy_block
                reg signed [21:0] abs_GxGy;
                abs_GxGy = (GxGy_full < 0) ? -GxGy_full : GxGy_full;
                GxGy_scaled <= (abs_GxGy > 22'sd261120) ? 8'd255 : abs_GxGy[17:10];
            end
        end
    end

    // Valid signal pipelined through sobel stage
    reg sobel_valid;
    always @(posedge clk) begin
        if (rst) sobel_valid <= 0;
        else     sobel_valid <= win1_valid;
    end

    // ── Stage 2: Sum gradient products over 3×3 ──────────────────
    // Pack 3 channels into one 24-bit value for line buffer
    wire [23:0] packed_in = {Gx2_scaled, Gy2_scaled, GxGy_scaled};

    wire [23:0] p00,p01,p02,p10,p11,p12,p20,p21,p22;
    wire        win2_valid;

    line_buffer #(.WIDTH(24),.IMG_W(IMG_W)) lb2(
        .clk(clk),.rst(rst),
        .pixel_valid(sobel_valid),.pixel_in(packed_in),
        .w00(p00),.w01(p01),.w02(p02),
        .w10(p10),.w11(p11),.w12(p12),
        .w20(p20),.w21(p21),.w22(p22),
        .window_valid(win2_valid)
    );

    // Sum over 3×3 neighborhood
    reg [10:0] sum_Gx2, sum_Gy2, sum_GxGy;
    reg signed [63:0] det, trace2, R;

    always @(posedge clk) begin
        if (rst) begin
            corner_out <= 0;
            out_valid  <= 0;
        end else begin
            out_valid <= win2_valid;
            if (win2_valid) begin
                // Sum Gx² over 3×3
                sum_Gx2 = p00[23:16] + p01[23:16] + p02[23:16]
                        + p10[23:16] + p11[23:16] + p12[23:16]
                        + p20[23:16] + p21[23:16] + p22[23:16];

                // Sum Gy² over 3×3
                sum_Gy2 = p00[15:8] + p01[15:8] + p02[15:8]
                        + p10[15:8] + p11[15:8] + p12[15:8]
                        + p20[15:8] + p21[15:8] + p22[15:8];

                // Sum |GxGy| over 3×3
                sum_GxGy = p00[7:0] + p01[7:0] + p02[7:0]
                         + p10[7:0] + p11[7:0] + p12[7:0]
                         + p20[7:0] + p21[7:0] + p22[7:0];

                // Harris R = det(M) - k*trace(M)²
                // det   = Gx2*Gy2 - GxGy²
                // trace = Gx2 + Gy2
                // k = 1/16 (approx 0.04)
                det    = ($signed({1'b0,sum_Gx2}) * $signed({1'b0,sum_Gy2}))
                       - ($signed({1'b0,sum_GxGy}) * $signed({1'b0,sum_GxGy}));
                trace2 = ($signed({1'b0,sum_Gx2}) + $signed({1'b0,sum_Gy2}))
                       * ($signed({1'b0,sum_Gx2}) + $signed({1'b0,sum_Gy2}));

                R = det - (trace2 >>> 4);

                corner_out <= (R > THRESHOLD) ? 8'd255 : 8'd0;
            end
        end
    end
endmodule