`timescale 1ns/1ps
module tb_harris;
    parameter IMG_W = 128;
    parameter IMG_H = 128;
    parameter TOTAL = IMG_W * IMG_H;

    reg clk,rst,pixel_valid;
    reg [7:0] r,g,b;
    wire [7:0] corner_out;
    wire out_valid;
    reg [7:0] image_mem [0:TOTAL*3-1];

    harris_pipeline #(.IMG_W(IMG_W),.THRESHOLD(50000)) uut(
        .clk(clk),.rst(rst),.pixel_valid(pixel_valid),
        .r(r),.g(g),.b(b),.corner_out(corner_out),.out_valid(out_valid));

    initial clk=0;
    always #5 clk=~clk;

    integer out_file,i,corner_count;
    initial begin
        $readmemh("image_data.hex",image_mem);
        out_file=$fopen("sim/harris_output.hex","w");
        corner_count=0;
        rst=1; pixel_valid=0;
        repeat(2) @(posedge clk); #1;
        rst=0;
        for(i=0;i<TOTAL*3;i=i+3) begin
            r=image_mem[i]; g=image_mem[i+1]; b=image_mem[i+2];
            pixel_valid=1;
            @(posedge clk); #1;
        end
        pixel_valid=0;
        repeat(IMG_H*10) @(posedge clk);
        $display("Total corners: %0d", corner_count);
        $fclose(out_file);
        $finish;
    end

    always @(posedge clk) begin
        if(out_valid) begin
            $fwrite(out_file,"%02X\n",corner_out);
            if(corner_out > 0) corner_count = corner_count+1;
        end
    end
endmodule