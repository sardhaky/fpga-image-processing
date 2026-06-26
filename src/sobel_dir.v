module sobel_dir #(parameter IMG_W = 64)(
    input  wire       clk, rst, pixel_valid,
    input  wire [7:0] pixel_in,
    output reg  [7:0] mag,
    output reg  [1:0] dir,   // 0=0°  1=45°  2=90°  3=135°
    output reg        out_valid
);
    wire [7:0] w00,w01,w02,w10,w11,w12,w20,w21,w22;
    wire window_valid;

    line_buffer #(.WIDTH(8),.IMG_W(IMG_W)) lb(
        .clk(clk),.rst(rst),
        .pixel_valid(pixel_valid),.pixel_in(pixel_in),
        .w00(w00),.w01(w01),.w02(w02),
        .w10(w10),.w11(w11),.w12(w12),
        .w20(w20),.w21(w21),.w22(w22),
        .window_valid(window_valid)
    );

    reg signed [10:0] Gx, Gy;
    reg        [10:0] Gx_abs, Gy_abs;
    reg        [11:0] G_sum;

    always @(posedge clk) begin
        if (rst) begin mag<=0; dir<=0; out_valid<=0; end
        else begin
            out_valid <= window_valid;
            if (window_valid) begin
                // Sobel kernels
                Gx = (-$signed({1'b0,w00}) + $signed({1'b0,w02}))
                   + ((-$signed({1'b0,w10}) + $signed({1'b0,w12})) << 1)
                   + (-$signed({1'b0,w20}) + $signed({1'b0,w22}));

                Gy = (-$signed({1'b0,w00}) - ($signed({1'b0,w01})<<1) - $signed({1'b0,w02}))
                   + ( $signed({1'b0,w20}) + ($signed({1'b0,w21})<<1) + $signed({1'b0,w22}));

                Gx_abs = (Gx<0) ? -Gx : Gx;
                Gy_abs = (Gy<0) ? -Gy : Gy;
                G_sum  = Gx_abs + Gy_abs;
                mag    <= (G_sum > 255) ? 255 : G_sum[7:0];

                // Quantize direction to 4 angles
                if      (Gy_abs < (Gx_abs >> 1))  dir <= 2'd0; // ~0°  horizontal
                else if (Gx_abs < (Gy_abs >> 1))  dir <= 2'd2; // ~90° vertical
                else if ((Gx>=0)==(Gy>=0))         dir <= 2'd1; // 45°
                else                               dir <= 2'd3; // 135°
            end
        end
    end
endmodule