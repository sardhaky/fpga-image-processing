module gaussian_blur #(
    parameter IMG_W = 6
)(
    input  wire        clk,
    input  wire        rst,
    input  wire        pixel_valid,
    input  wire [7:0]  pixel_in,

    output reg  [7:0]  blurred,
    output reg         out_valid
);
    // Get 3x3 window from line buffer
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

    // Gaussian: (1*corners + 2*edges + 4*center) / 16
    reg [11:0] sum;

    always @(posedge clk) begin
        if (rst) begin
            blurred   <= 0;
            out_valid <= 0;
        end else begin
            out_valid <= window_valid;
            if (window_valid) begin
                sum =   ({2'b0, w00}) +
                        ({1'b0, w01, 1'b0}) +       // w01 * 2
                        ({2'b0, w02}) +
                        ({1'b0, w10, 1'b0}) +       // w10 * 2
                        ({w11, 2'b0}) +             // w11 * 4
                        ({1'b0, w12, 1'b0}) +       // w12 * 2
                        ({2'b0, w20}) +
                        ({1'b0, w21, 1'b0}) +       // w21 * 2
                        ({2'b0, w22});

                blurred <= sum[11:4];  // divide by 16 = right shift 4
            end
        end
    end

endmodule