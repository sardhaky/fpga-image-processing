`timescale 1ns/1ps

module tb_grayscale;
    reg        clk, rst, pixel_valid;
    reg  [7:0] r, g, b;
    wire [7:0] gray;
    wire       out_valid;

    grayscale uut (
        .clk(clk), .rst(rst),
        .pixel_valid(pixel_valid),
        .r(r), .g(g), .b(b),
        .gray(gray), .out_valid(out_valid)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    initial begin
        $dumpfile("sim/dump.vcd");
        $dumpvars(0, tb_grayscale);
    end

    initial begin
        rst = 1; pixel_valid = 0;
        r = 0; g = 0; b = 0;
        @(posedge clk); #1;
        rst = 0;

        pixel_valid = 1;
        r = 255; g = 0;   b = 0;   @(posedge clk); #1; // Red
        r = 0;   g = 255; b = 0;   @(posedge clk); #1; // Green
        r = 255; g = 255; b = 255; @(posedge clk); #1; // White
        r = 100; g = 150; b = 200; @(posedge clk); #1; // Custom

        pixel_valid = 0;
        repeat(3) @(posedge clk);
        $finish;
    end

    initial begin
        $monitor("t=%0t | R=%0d G=%0d B=%0d | gray=%0d valid=%b",
                  $time, r, g, b, gray, out_valid);
    end
endmodule