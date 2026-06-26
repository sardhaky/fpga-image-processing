`timescale 1ns/1ps

module tb_gaussian_blur;
    reg        clk, rst, pixel_valid;
    reg  [7:0] pixel_in;
    wire [7:0] blurred;
    wire       out_valid;

    gaussian_blur #(.IMG_W(6)) uut (
        .clk(clk), .rst(rst),
        .pixel_valid(pixel_valid),
        .pixel_in(pixel_in),
        .blurred(blurred),
        .out_valid(out_valid)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    initial begin
        $dumpfile("sim/dump.vcd");
        $dumpvars(0, tb_gaussian_blur);
    end

    task send_pixel;
        input [7:0] val;
        begin
            pixel_in = val; pixel_valid = 1;
            @(posedge clk); #1;
        end
    endtask

    initial begin
        rst = 1; pixel_valid = 0; pixel_in = 0;
        repeat(2) @(posedge clk); #1;
        rst = 0;

        // 6x5 image with a noise spike in the middle
        // Mostly flat at 100, with one bright noise pixel (255) at row2,col3
        // Row 0 — flat
        send_pixel(100); send_pixel(100); send_pixel(100);
        send_pixel(100); send_pixel(100); send_pixel(100);
        // Row 1 — flat
        send_pixel(100); send_pixel(100); send_pixel(100);
        send_pixel(100); send_pixel(100); send_pixel(100);
        // Row 2 — noise spike at col 3
        send_pixel(100); send_pixel(100); send_pixel(100);
        send_pixel(255); send_pixel(100); send_pixel(100);
        // Row 3 — flat
        send_pixel(100); send_pixel(100); send_pixel(100);
        send_pixel(100); send_pixel(100); send_pixel(100);
        // Row 4 — flat
        send_pixel(100); send_pixel(100); send_pixel(100);
        send_pixel(100); send_pixel(100); send_pixel(100);

        pixel_valid = 0;
        repeat(10) @(posedge clk);
        $finish;
    end

    always @(posedge clk) begin
        if (out_valid)
            $display("t=%0t | blurred=%0d", $time, blurred);
    end

endmodule