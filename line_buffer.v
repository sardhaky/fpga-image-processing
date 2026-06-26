module line_buffer #(
    parameter WIDTH = 8,        // pixel bit width
    parameter IMG_W = 8         // image width in pixels (keep small for simulation)
)(
    input  wire             clk,
    input  wire             rst,
    input  wire             pixel_valid,
    input  wire [WIDTH-1:0] pixel_in,

    // 3x3 window output (row0 = oldest, row2 = current)
    output reg  [WIDTH-1:0] w00, w01, w02,  // top row
    output reg  [WIDTH-1:0] w10, w11, w12,  // middle row
    output reg  [WIDTH-1:0] w20, w21, w22,  // current row
    output reg              window_valid     // high when full 3x3 is ready
);

    // Two line buffers to store previous rows
    reg [WIDTH-1:0] lb0 [0:IMG_W-1];   // 2 rows ago
    reg [WIDTH-1:0] lb1 [0:IMG_W-1];   // 1 row ago

    // Shift registers for the 3 horizontal pixels in each row
    reg [WIDTH-1:0] sr0_0, sr0_1;      // top row shift register
    reg [WIDTH-1:0] sr1_0, sr1_1;      // middle row shift register
    reg [WIDTH-1:0] sr2_0, sr2_1;      // current row shift register

    // Column counter
    reg [$clog2(IMG_W)-1:0] col;
    // Row counter (need 2 full rows before window is valid)
    reg [7:0] row;
    reg window_valid_pre;

    integer i;

    always @(posedge clk) begin
        if (rst) begin
            col          <= 0;
            row          <= 0;
            window_valid <= 0;
            window_valid_pre <= 0;
            sr0_0 <= 0; sr0_1 <= 0;
            sr1_0 <= 0; sr1_1 <= 0;
            sr2_0 <= 0; sr2_1 <= 0;
            for (i = 0; i < IMG_W; i = i + 1) begin
                lb0[i] <= 0;
                lb1[i] <= 0;
            end
        end else if (pixel_valid) begin

            // --- Shift line buffers ---
            // lb1 holds row N-1, lb0 holds row N-2
            lb0[col] <= lb1[col];       // push lb1 into lb0
            lb1[col] <= pixel_in;       // push current pixel into lb1

            // --- Build sliding window columns ---
            // Top row (oldest): from lb0
            sr0_1 <= sr0_0;
            sr0_0 <= lb0[col];

            // Middle row: from lb1
            sr1_1 <= sr1_0;
            sr1_0 <= lb1[col];

            // Current row: direct pixel input
            sr2_1 <= sr2_0;
            sr2_0 <= pixel_in;

            // --- Output window ---
            // col 0 = newest pixel (right), col 2 = oldest (left)
            w00 <= sr0_1; w01 <= sr0_0; w02 <= lb0[col];
            w10 <= sr1_1; w11 <= sr1_0; w12 <= lb1[col];
            w20 <= sr2_1; w21 <= sr2_0; w22 <= pixel_in;

            // --- Column/row tracking ---
            if (col == IMG_W - 1) begin
                col <= 0;
                row <= row + 1;
            end else begin
                col <= col + 1;
            end

            // Window valid after 2 full rows + 2 extra pixels
            window_valid <= (row >= 2) || (row == 2 && col >= 1);

        end else begin
            window_valid <= 0;
        end
    end

endmodule