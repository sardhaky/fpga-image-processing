`timescale 1ns/1ps

module tb_pipeline_real;

    parameter IMG_W = 64;
    parameter IMG_H = 64;
    parameter TOTAL = IMG_W * IMG_H;

    reg        clk, rst, pixel_valid;
    reg  [7:0] r, g, b;
    wire [7:0] edge_out;
    wire       out_valid;

    // Memory to hold image data (R, G, B interleaved)
    reg [7:0] image_mem [0:TOTAL*3-1];

    image_pipeline #(.IMG_W(IMG_W)) uut (
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
        $dumpvars(0, tb_pipeline_real);
    end

    // Output file for edge results
    integer out_file;
    integer i;

    initial begin
        // Load hex image data
        $readmemh("image_data.hex", image_mem);

        out_file = $fopen("sim/edge_output.hex", "w");

        rst = 1; pixel_valid = 0;
        repeat(2) @(posedge clk); #1;
        rst = 0;

        // Stream all pixels
        for (i = 0; i < TOTAL * 3; i = i + 3) begin
            r = image_mem[i];
            g = image_mem[i+1];
            b = image_mem[i+2];
            pixel_valid = 1;
            @(posedge clk); #1;
        end

        pixel_valid = 0;
        // Wait for pipeline to flush
        repeat(20) @(posedge clk);

        $fclose(out_file);
        $finish;
    end

    // Capture output pixels to file
    always @(posedge clk) begin
        if (out_valid) begin
            $fwrite(out_file, "%02X\n", edge_out);
            $display("edge=%0d", edge_out);
        end
    end

endmodule