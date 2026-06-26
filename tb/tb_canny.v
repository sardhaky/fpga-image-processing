`timescale 1ns/1ps

module tb_image_pipeline;
    reg        clk, rst, pixel_valid;
    reg  [7:0] r, g, b;
    wire [7:0] edge_out;
    wire       out_valid;

    image_pipeline #(.IMG_W(6)) uut (
        .clk(clk), .rst(rst),
        .pixel_valid(pixel_valid),
        .r(r), .g(g), .b(b),
        .edge_out(edge_out),
        .out_valid(out_valid)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    initial begin
        $dumpfile("sim/dump.vcd");
        $dumpvars(0, tb_image_pipeline);
    end

    task send_pixel;
        input [7:0] rv, gv, bv;
        begin
            r = rv; g = gv; b = bv;
            pixel_valid = 1;
            @(posedge clk); #1;
        end
    endtask

    initial begin
        rst = 1; pixel_valid = 0;
        r = 0; g = 0; b = 0;
        repeat(2) @(posedge clk); #1;
        rst = 0;

        // 6x5 image: left dark / right bright + noise spike at row2,col2
        // Row 0
        send_pixel(50,50,50);   send_pixel(50,50,50);   send_pixel(50,50,50);
        send_pixel(200,200,200);send_pixel(200,200,200);send_pixel(200,200,200);
        // Row 1
        send_pixel(50,50,50);   send_pixel(50,50,50);   send_pixel(50,50,50);
        send_pixel(200,200,200);send_pixel(200,200,200);send_pixel(200,200,200);
        // Row 2 — noise spike injected at col 2 (left side)
        send_pixel(50,50,50);   send_pixel(50,50,50);   send_pixel(255,255,255);
        send_pixel(200,200,200);send_pixel(200,200,200);send_pixel(200,200,200);
        // Row 3
        send_pixel(50,50,50);   send_pixel(50,50,50);   send_pixel(50,50,50);
        send_pixel(200,200,200);send_pixel(200,200,200);send_pixel(200,200,200);
        // Row 4
        send_pixel(50,50,50);   send_pixel(50,50,50);   send_pixel(50,50,50);
        send_pixel(200,200,200);send_pixel(200,200,200);send_pixel(200,200,200);

        pixel_valid = 0;
        repeat(10) @(posedge clk);
        $finish;
    end

    always @(posedge clk) begin
        if (out_valid)
            $display("t=%0t | edge=%0d", $time, edge_out);
    end

endmodule