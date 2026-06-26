`timescale 1ns/1ps
module tb_canny;
    parameter IMG_W = 128;
    parameter IMG_H = 128;
    parameter TOTAL = IMG_W * IMG_H;

    reg clk, rst, pixel_valid;
    reg [7:0] r, g, b;
    wire [7:0] edge_out;
    wire out_valid;

    reg [7:0] image_mem [0:TOTAL*3-1];

    canny_pipeline #(.IMG_W(IMG_W),.HIGH_THR(40),.LOW_THR(15)) uut(
        .clk(clk),.rst(rst),.pixel_valid(pixel_valid),
        .r(r),.g(g),.b(b),.edge_out(edge_out),.out_valid(out_valid)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    initial begin
        $dumpfile("sim/dump.vcd");
        $dumpvars(0, tb_canny);
    end

    integer out_file, i;
    initial begin
        $readmemh("image_data.hex", image_mem);
        out_file = $fopen("sim/canny_output.hex","w");
        rst=1; pixel_valid=0;
        repeat(2) @(posedge clk); #1;
        rst=0;
        for(i=0; i<TOTAL*3; i=i+3) begin
            r=image_mem[i]; g=image_mem[i+1]; b=image_mem[i+2];
            pixel_valid=1;
            @(posedge clk); #1;
        end
        pixel_valid=0;
        repeat(IMG_H*10) @(posedge clk);
        $fclose(out_file);
        $finish;
    end

    always @(posedge clk)
        if (out_valid) $fwrite(out_file,"%02X\n",edge_out);
endmodule