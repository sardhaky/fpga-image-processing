module gaussian5x5 #(parameter IMG_W = 64)(
    input  wire       clk, rst, pixel_valid,
    input  wire [7:0] pixel_in,
    output reg  [7:0] blurred,
    output reg        out_valid
);
    // 4 line buffers = 5 rows total
    reg [7:0] lb0[0:IMG_W-1], lb1[0:IMG_W-1];
    reg [7:0] lb2[0:IMG_W-1], lb3[0:IMG_W-1];

    // Shift registers (4 deep per row for 5-wide window)
    reg [7:0] sr0_0,sr0_1,sr0_2,sr0_3;
    reg [7:0] sr1_0,sr1_1,sr1_2,sr1_3;
    reg [7:0] sr2_0,sr2_1,sr2_2,sr2_3;
    reg [7:0] sr3_0,sr3_1,sr3_2,sr3_3;
    reg [7:0] sr4_0,sr4_1,sr4_2,sr4_3;

    reg [$clog2(IMG_W)-1:0] col;
    reg [7:0] row;
    reg [13:0] sum;

    // 5x5 window pixels
    reg [7:0] p00,p01,p02,p03,p04;
    reg [7:0] p10,p11,p12,p13,p14;
    reg [7:0] p20,p21,p22,p23,p24;
    reg [7:0] p30,p31,p32,p33,p34;
    reg [7:0] p40,p41,p42,p43,p44;

    integer i;

    always @(posedge clk) begin
        if (rst) begin
            col<=0; row<=0; out_valid<=0; blurred<=0;
            sr0_0<=0;sr0_1<=0;sr0_2<=0;sr0_3<=0;
            sr1_0<=0;sr1_1<=0;sr1_2<=0;sr1_3<=0;
            sr2_0<=0;sr2_1<=0;sr2_2<=0;sr2_3<=0;
            sr3_0<=0;sr3_1<=0;sr3_2<=0;sr3_3<=0;
            sr4_0<=0;sr4_1<=0;sr4_2<=0;sr4_3<=0;
            for (i=0;i<IMG_W;i=i+1) begin
                lb0[i]<=0;lb1[i]<=0;lb2[i]<=0;lb3[i]<=0;
            end
        end else if (pixel_valid) begin
            // Push through line buffers
            lb0[col] <= lb1[col];
            lb1[col] <= lb2[col];
            lb2[col] <= lb3[col];
            lb3[col] <= pixel_in;

            // Shift registers per row
            sr0_3<=sr0_2;sr0_2<=sr0_1;sr0_1<=sr0_0;sr0_0<=lb0[col];
            sr1_3<=sr1_2;sr1_2<=sr1_1;sr1_1<=sr1_0;sr1_0<=lb1[col];
            sr2_3<=sr2_2;sr2_2<=sr2_1;sr2_1<=sr2_0;sr2_0<=lb2[col];
            sr3_3<=sr3_2;sr3_2<=sr3_1;sr3_1<=sr3_0;sr3_0<=lb3[col];
            sr4_3<=sr4_2;sr4_2<=sr4_1;sr4_1<=sr4_0;sr4_0<=pixel_in;

            // Latch 5x5 window
            p00<=sr0_3;p01<=sr0_2;p02<=sr0_1;p03<=sr0_0;p04<=lb0[col];
            p10<=sr1_3;p11<=sr1_2;p12<=sr1_1;p13<=sr1_0;p14<=lb1[col];
            p20<=sr2_3;p21<=sr2_2;p22<=sr2_1;p23<=sr2_0;p24<=lb2[col];
            p30<=sr3_3;p31<=sr3_2;p32<=sr3_1;p33<=sr3_0;p34<=lb3[col];
            p40<=sr4_3;p41<=sr4_2;p42<=sr4_1;p43<=sr4_0;p44<=pixel_in;

            if (col==IMG_W-1) begin col<=0; row<=row+1; end
            else col<=col+1;

            out_valid <= (row >= 4);

            // Gaussian 5x5 kernel / 159
            // 2  4  5  4  2
            // 4  9 12  9  4
            // 5 12 15 12  5
            // 4  9 12  9  4
            // 2  4  5  4  2
            if (row >= 4) begin
                sum = 2*p00 + 4*p01 + 5*p02 + 4*p03 + 2*p04
                    + 4*p10 + 9*p11 +12*p12 + 9*p13 + 4*p14
                    + 5*p20 +12*p21 +15*p22 +12*p23 + 5*p24
                    + 4*p30 + 9*p31 +12*p32 + 9*p33 + 4*p34
                    + 2*p40 + 4*p41 + 5*p42 + 4*p43 + 2*p44;
                blurred <= sum / 159;
            end
        end else begin
            out_valid <= 0;
        end
    end
endmodule