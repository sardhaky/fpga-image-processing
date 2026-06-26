module harris_pipeline #(
    parameter IMG_W    = 128,
    parameter THRESHOLD = 50000
)(
    input  wire       clk, rst, pixel_valid,
    input  wire [7:0] r, g, b,
    output wire [7:0] corner_out,
    output wire       out_valid
);
    wire [7:0] gray; wire gray_valid;
    grayscale gs(.clk(clk),.rst(rst),.pixel_valid(pixel_valid),
                 .r(r),.g(g),.b(b),.gray(gray),.out_valid(gray_valid));

    harris #(.IMG_W(IMG_W),.THRESHOLD(THRESHOLD)) hc(
        .clk(clk),.rst(rst),
        .pixel_valid(gray_valid),.pixel_in(gray),
        .corner_out(corner_out),.out_valid(out_valid));
endmodule