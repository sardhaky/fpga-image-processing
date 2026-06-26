`timescale 1ns/1ps

module tb_line_buffer;

    parameter WIDTH = 8;
    parameter IMG_W = 4;    // tiny 4-wide image for easy viewing

    reg             clk, rst, pixel_valid;
    reg  [WIDTH-1:0] pixel_in;

    wire [WIDTH-1:0] w00, w01, w02;
    wire [WIDTH-1:0] w10, w11, w12;
    wire [WIDTH-1:0] w20, w21, w22;
    wire             window_valid;

    line_buffer #(.WIDTH(WIDTH), .IMG_W(IMG_W)) uut (
        .clk(clk), .rst(rst),
        .pixel_valid(pixel_valid),
        .pixel_in(pixel_in),
        .w00(w00), .w01(w01), .w02(w02),
        .w10(w10), .w11(w11), .w12(w12),
        .w20(w20), .w21(w21), .w22(w22),
        .window_valid(window_valid)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    initial begin
        $dumpfile("sim/dump.vcd");
        $dumpvars(0, tb_line_buffer);
    end

    // Feed a 4x4 image row by row
    // Row 0: 10 11 12 13
    // Row 1: 20 21 22 23
    // Row 2: 30 31 32 33
    // Row 3: 40 41 42 43
    task send_pixel;
        input [WIDTH-1:0] val;
        begin
            pixel_in    = val;
            pixel_valid = 1;
            @(posedge clk); #1;
        end
    endtask

    initial begin
        rst = 1; pixel_valid = 0; pixel_in = 0;
        repeat(2) @(posedge clk); #1;
        rst = 0;

        // Row 0
        send_pixel(10); send_pixel(11); send_pixel(12); send_pixel(13);
        // Row 1
        send_pixel(20); send_pixel(21); send_pixel(22); send_pixel(23);
        // Row 2
        send_pixel(30); send_pixel(31); send_pixel(32); send_pixel(33);
        // Row 3
        send_pixel(40); send_pixel(41); send_pixel(42); send_pixel(43);

        pixel_valid = 0;
        repeat(4) @(posedge clk);
        $finish;
    end

    // Print window when valid
    always @(posedge clk) begin
        if (window_valid) begin
            $display("--- 3x3 Window ---");
            $display("  %3d %3d %3d", w00, w01, w02);
            $display("  %3d %3d %3d", w10, w11, w12);
            $display("  %3d %3d %3d", w20, w21, w22);
        end
    end

endmodule