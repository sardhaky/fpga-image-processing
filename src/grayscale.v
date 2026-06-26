module grayscale (
    input  wire        clk, rst, pixel_valid,
    input  wire [7:0]  r, g, b,
    output reg  [7:0]  gray,
    output reg         out_valid
);
    always @(posedge clk) begin
        if (rst) begin gray <= 0; out_valid <= 0; end
        else begin
            out_valid <= pixel_valid;
            if (pixel_valid)
                gray <= (77*r + 150*g + 29*b) >> 8;
        end
    end
endmodule