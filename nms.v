module nms #(parameter IMG_W = 64)(
    input  wire       clk, rst,
    input  wire [7:0] mag_in,
    input  wire [1:0] dir_in,
    input  wire       in_valid,
    output reg  [7:0] mag_out,
    output reg        out_valid
);
    // Pack {dir[1:0], mag[7:0]} = 10 bits into one line buffer
    wire [9:0] packed_in = {dir_in, mag_in};
    wire [9:0] pw00,pw01,pw02,pw10,pw11,pw12,pw20,pw21,pw22;
    wire window_valid;

    line_buffer #(.WIDTH(10),.IMG_W(IMG_W)) lb(
        .clk(clk),.rst(rst),
        .pixel_valid(in_valid),.pixel_in(packed_in),
        .w00(pw00),.w01(pw01),.w02(pw02),
        .w10(pw10),.w11(pw11),.w12(pw12),
        .w20(pw20),.w21(pw21),.w22(pw22),
        .window_valid(window_valid)
    );

    // Unpack magnitudes and center direction
    wire [7:0] m00=pw00[7:0],m01=pw01[7:0],m02=pw02[7:0];
    wire [7:0] m10=pw10[7:0],m11=pw11[7:0],m12=pw12[7:0];
    wire [7:0] m20=pw20[7:0],m21=pw21[7:0],m22=pw22[7:0];
    wire [1:0] cdir = pw11[9:8];

    always @(posedge clk) begin
        if (rst) begin mag_out<=0; out_valid<=0; end
        else begin
            out_valid <= window_valid;
            if (window_valid) begin
                case (cdir)
                    2'd0: // horizontal — compare left & right
                        mag_out <= (m11>=m10 && m11>=m12) ? m11 : 8'd0;
                    2'd1: // 45° — compare top-right & bottom-left
                        mag_out <= (m11>=m02 && m11>=m20) ? m11 : 8'd0;
                    2'd2: // vertical — compare top & bottom
                        mag_out <= (m11>=m01 && m11>=m21) ? m11 : 8'd0;
                    2'd3: // 135° — compare top-left & bottom-right
                        mag_out <= (m11>=m00 && m11>=m22) ? m11 : 8'd0;
                endcase
            end else
                mag_out <= 0;
        end
    end
endmodule