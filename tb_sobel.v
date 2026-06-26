`timescale 1ns/1ps

module tb_sobel;
    reg        clk, rst, pixel_valid;
    reg  [7:0] pixel_in;
    wire [7:0] edge_out;
    wire       out_valid;

    sobel #(.IMG_W(6)) uut (
        .clk(clk), .rst(rst),
        .pixel_valid(pixel_valid),
        .pixel_in(pixel_in),
        .edge_out(edge_out),
        .out_valid(out_valid)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    initial begin
        $dumpfile("sim/dump.vcd");
        $dumpvars(0, tb_sobel);
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

        // 6x5 test image — sharp vertical edge in the middle
        // Left half = 0 (dark), Right half = 255 (bright)
        send_pixel(0);   send_pixel(0);   send_pixel(0);   send_pixel(255); send_pixel(255); send_pixel(255);
        send_pixel(0);   send_pixel(0);   send_pixel(0);   send_pixel(255); send_pixel(255); send_pixel(255);
        send_pixel(0);   send_pixel(0);   send_pixel(0);   send_pixel(255); send_pixel(255); send_pixel(255);
        send_pixel(0);   send_pixel(0);   send_pixel(0);   send_pixel(255); send_pixel(255); send_pixel(255);
        send_pixel(0);   send_pixel(0);   send_pixel(0);   send_pixel(255); send_pixel(255); send_pixel(255);

        pixel_valid = 0;
        repeat(5) @(posedge clk);
        $finish;
    end

    always @(posedge clk) begin
        if (out_valid)
            $display("t=%0t | edge=%0d", $time, edge_out);
    end

endmodule