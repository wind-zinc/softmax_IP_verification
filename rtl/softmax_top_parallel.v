`timescale 1ns / 1ps

module softmax_top_parallel #(
    parameter DATA_WIDTH   = 32,
    parameter NUM_ELEMENTS = 8,
    parameter TREE_LEVELS  =
        (NUM_ELEMENTS <= 1) ? 1 : $clog2(NUM_ELEMENTS),
    parameter SUM_WIDTH    = DATA_WIDTH + TREE_LEVELS
)(
    input  wire                                  clk,
    input  wire                                  rst_n,
    input  wire [(NUM_ELEMENTS*DATA_WIDTH)-1:0]  array_in,
    input  wire                                  array_valid,
    output wire [(NUM_ELEMENTS*DATA_WIDTH)-1:0]  exp_array_out,
    output wire                                  exp_valid,
    output wire [SUM_WIDTH-1:0]                  sum_out,
    output wire                                  done
);

    wire signed [DATA_WIDTH-1:0] global_max;
    wire                         max_valid;

    tree_max_finder #(
        .DATA_WIDTH   (DATA_WIDTH),
        .NUM_ELEMENTS (NUM_ELEMENTS)
    ) u_tree_max (
        .clk       (clk),
        .rst_n     (rst_n),
        .valid_in  (array_valid),
        .array_in  (array_in),
        .max_out   (global_max),
        .valid_out (max_valid)
    );

    reg signed [DATA_WIDTH-1:0] data_delay_reg [0:NUM_ELEMENTS-1];
    reg signed [DATA_WIDTH-1:0] cordic_in_data  [0:NUM_ELEMENTS-1];
    reg                         cordic_in_valid;
    integer i;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < NUM_ELEMENTS; i = i + 1)
                data_delay_reg[i] <= {DATA_WIDTH{1'b0}};
        end else if (array_valid) begin
            for (i = 0; i < NUM_ELEMENTS; i = i + 1)
                data_delay_reg[i] <=
                    array_in[(i*DATA_WIDTH) +: DATA_WIDTH];
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cordic_in_valid <= 1'b0;
            for (i = 0; i < NUM_ELEMENTS; i = i + 1)
                cordic_in_data[i] <= {DATA_WIDTH{1'b0}};
        end else begin
            cordic_in_valid <= max_valid;
            if (max_valid) begin
                for (i = 0; i < NUM_ELEMENTS; i = i + 1)
                    cordic_in_data[i] <= data_delay_reg[i] - global_max;
            end
        end
    end

    wire signed [DATA_WIDTH-1:0] cordic_out_data [0:NUM_ELEMENTS-1];
    wire [NUM_ELEMENTS-1:0]      cordic_out_valid;

    genvar lane;
    generate
        for (lane = 0; lane < NUM_ELEMENTS; lane = lane + 1) begin : gen_cordic_lane
            cordic_top #(
                .DATA_WIDTH (DATA_WIDTH)
            ) u_cordic_top (
                .clk       (clk),
                .rst_n     (rst_n),
                .valid_in  (cordic_in_valid),
                .x_in      (cordic_in_data[lane]),
                .valid_out (cordic_out_valid[lane]),
                .exp_out   (cordic_out_data[lane])
            );

            assign exp_array_out[(lane*DATA_WIDTH) +: DATA_WIDTH] =
                cordic_out_data[lane];
        end
    endgenerate

    wire cluster_valid;
    assign cluster_valid = cordic_out_valid[0];
    assign exp_valid     = cluster_valid;

    tree_accumulator #(
        .DATA_WIDTH   (DATA_WIDTH),
        .NUM_ELEMENTS (NUM_ELEMENTS),
        .TREE_LEVELS  (TREE_LEVELS),
        .SUM_WIDTH    (SUM_WIDTH)
    ) u_tree_accumulator (
        .clk       (clk),
        .rst_n     (rst_n),
        .valid_in  (cluster_valid),
        .array_in  (exp_array_out),
        .sum_out   (sum_out),
        .valid_out (done)
    );

endmodule
