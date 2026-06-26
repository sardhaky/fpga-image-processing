module image_pipeline #(
    parameter IMG_W = 6
)(
    input  wire        clk,
    input  wire        rst,
    input  wire        pixel_valid,
    input  wire [7:0]  r, g, b,

    output wire [7:0]  edge_out,
    output wire        out_valid
);
    // Stage 1 — Grayscale
    wire [7:0] gray;
    wire       gray_valid;

    grayscale gs (
        .clk(clk), .rst(rst),
        .pixel_valid(pixel_valid),
        .r(r), .g(g), .b(b),
        .gray(gray),
        .out_valid(gray_valid)
    );

    // Stage 2 — Gaussian Blur
    wire [7:0] blurred;
    wire       blur_valid;

    gaussian_blur #(.IMG_W(IMG_W)) gb (
        .clk(clk), .rst(rst),
        .pixel_valid(gray_valid),
        .pixel_in(gray),
        .blurred(blurred),
        .out_valid(blur_valid)
    );

    // Stage 3 — Sobel Edge Detection
    sobel #(.IMG_W(IMG_W)) sb (
        .clk(clk), .rst(rst),
        .pixel_valid(blur_valid),
        .pixel_in(blurred),
        .edge_out(edge_out),
        .out_valid(out_valid)
    );

endmodule