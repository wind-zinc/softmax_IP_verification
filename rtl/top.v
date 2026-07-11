`timescale 1ns / 1ps

module softmax_complete_top #(
    parameter DATA_WIDTH      = 32,
    parameter FRACTIONAL_BITS = 16,
    parameter NUM_ELEMENTS    = 8
)(
    input  wire                                  clk,
    input  wire                                  rst_n,
    input  wire [(NUM_ELEMENTS*DATA_WIDTH)-1:0]  array_in,
    input  wire                                  array_valid,
    output wire [(NUM_ELEMENTS*DATA_WIDTH)-1:0]  softmax_array_out,
    output wire                                  softmax_valid
);

    localparam integer TREE_LEVELS =
        (NUM_ELEMENTS <= 1) ? 1 : $clog2(NUM_ELEMENTS);
    localparam integer SUM_WIDTH = DATA_WIDTH + TREE_LEVELS;

    wire [(NUM_ELEMENTS*DATA_WIDTH)-1:0] exp_array_out;
    wire                                 exp_valid;
    wire [SUM_WIDTH-1:0]                 sum_out;
    wire                                 done;

    softmax_top_parallel #(
        .DATA_WIDTH   (DATA_WIDTH),
        .NUM_ELEMENTS (NUM_ELEMENTS),
        .TREE_LEVELS  (TREE_LEVELS),
        .SUM_WIDTH    (SUM_WIDTH)
    ) u_softmax_top_parallel (
        .clk           (clk),
        .rst_n         (rst_n),
        .array_in      (array_in),
        .array_valid   (array_valid),
        .exp_array_out (exp_array_out),
        .exp_valid     (exp_valid),
        .sum_out       (sum_out),
        .done          (done)
    );

    divider #(
        .DATA_WIDTH      (DATA_WIDTH),
        .FRACTIONAL_BITS (FRACTIONAL_BITS),
        .NUM_ELEMENTS    (NUM_ELEMENTS),
        .ALIGN_DELAY     (TREE_LEVELS),
        .SUM_WIDTH       (SUM_WIDTH)
    ) u_divider (
        .clk               (clk),
        .rst_n             (rst_n),
        .exp_array_in      (exp_array_out),
        .exp_valid         (exp_valid),
        .sum_in            (sum_out),
        .sum_valid         (done),
        .softmax_array_out (softmax_array_out),
        .softmax_valid     (softmax_valid)
    );

endmodule
