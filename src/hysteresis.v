module hysteresis #(
    parameter IMG_W    = 64,
    parameter HIGH_THR = 30,
    parameter LOW_THR  = 10
)(
    input  wire       clk, rst,
    input  wire [7:0] mag_in,
    input  wire       in_valid,
    output reg  [7:0] edge_out,
    output reg        out_valid
);
    wire [7:0] w00,w01,w02,w10,w11,w12,w20,w21,w22;
    wire window_valid;

    line_buffer #(.WIDTH(8),.IMG_W(IMG_W)) lb(
        .clk(clk),.rst(rst),
        .pixel_valid(in_valid),.pixel_in(mag_in),
        .w00(w00),.w01(w01),.w02(w02),
        .w10(w10),.w11(w11),.w12(w12),
        .w20(w20),.w21(w21),.w22(w22),
        .window_valid(window_valid)
    );

    wire is_strong = (w11 >= HIGH_THR);
    wire is_weak   = (w11 >= LOW_THR) && !is_strong;

    // Any neighbor above high threshold?
    wire nbr_strong = (w00>=HIGH_THR)||(w01>=HIGH_THR)||(w02>=HIGH_THR)||
                      (w10>=HIGH_THR)||(w12>=HIGH_THR)||
                      (w20>=HIGH_THR)||(w21>=HIGH_THR)||(w22>=HIGH_THR);

    always @(posedge clk) begin
        if (rst) begin edge_out<=0; out_valid<=0; end
        else begin
            out_valid <= window_valid;
            if (window_valid) begin
                if      (is_strong)              edge_out <= 255;
                else if (is_weak && nbr_strong)  edge_out <= 255;
                else                             edge_out <= 0;
            end else
                edge_out <= 0;
        end
    end
endmodule