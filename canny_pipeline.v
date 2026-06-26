module canny_pipeline #(
    parameter IMG_W    = 64,
    parameter HIGH_THR = 30,
    parameter LOW_THR  = 10
)(
    input  wire       clk, rst, pixel_valid,
    input  wire [7:0] r, g, b,
    output wire [7:0] edge_out,
    output wire       out_valid
);
    // Stage 1 — Grayscale
    wire [7:0] gray; wire gray_valid;
    grayscale gs(.clk(clk),.rst(rst),.pixel_valid(pixel_valid),
                 .r(r),.g(g),.b(b),.gray(gray),.out_valid(gray_valid));

    // Stage 2 — 5x5 Gaussian
    wire [7:0] blurred; wire blur_valid;
    gaussian5x5 #(.IMG_W(IMG_W)) gb(.clk(clk),.rst(rst),
                 .pixel_valid(gray_valid),.pixel_in(gray),
                 .blurred(blurred),.out_valid(blur_valid));

    // Stage 3 — Sobel + Direction
    wire [7:0] mag; wire [1:0] dir; wire sobel_valid;
    sobel_dir #(.IMG_W(IMG_W)) sd(.clk(clk),.rst(rst),
                 .pixel_valid(blur_valid),.pixel_in(blurred),
                 .mag(mag),.dir(dir),.out_valid(sobel_valid));

    // Stage 4 — Non-Maximum Suppression
    wire [7:0] nms_mag; wire nms_valid;
    nms #(.IMG_W(IMG_W)) nm(.clk(clk),.rst(rst),
                 .mag_in(mag),.dir_in(dir),.in_valid(sobel_valid),
                 .mag_out(nms_mag),.out_valid(nms_valid));

    // Stage 5 — Hysteresis Thresholding
    hysteresis #(.IMG_W(IMG_W),.HIGH_THR(HIGH_THR),.LOW_THR(LOW_THR)) hy(
                 .clk(clk),.rst(rst),
                 .mag_in(nms_mag),.in_valid(nms_valid),
                 .edge_out(edge_out),.out_valid(out_valid));
endmodule