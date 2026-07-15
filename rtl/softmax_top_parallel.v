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

    localparam integer INPUT_BUS_WIDTH =
        NUM_ELEMENTS * DATA_WIDTH;

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

    reg [INPUT_BUS_WIDTH-1:0]
        data_delay_pipeline [0:TREE_LEVELS-1];

    integer delay_index;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (delay_index = 0;
                 delay_index < TREE_LEVELS;
                 delay_index = delay_index + 1) begin
                data_delay_pipeline[delay_index] <=
                    {INPUT_BUS_WIDTH{1'b0}};
            end
        end
        else begin
            data_delay_pipeline[0] <= array_in;
            for (delay_index = 1;
                 delay_index < TREE_LEVELS;
                 delay_index = delay_index + 1) begin
                data_delay_pipeline[delay_index] <=
                    data_delay_pipeline[delay_index-1];
            end
        end
    end

    reg signed [DATA_WIDTH-1:0]
        cordic_in_data [0:NUM_ELEMENTS-1];
    reg cordic_in_valid;
    integer input_index;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cordic_in_valid <= 1'b0;
            for (input_index = 0;
                 input_index < NUM_ELEMENTS;
                 input_index = input_index + 1) begin
                cordic_in_data[input_index] <=
                    {DATA_WIDTH{1'b0}};
            end
        end
        else begin
            cordic_in_valid <= max_valid;
            if (max_valid) begin
                for (input_index = 0;
                     input_index < NUM_ELEMENTS;
                     input_index = input_index + 1) begin
                    cordic_in_data[input_index] <=
                        $signed(data_delay_pipeline[TREE_LEVELS-1][
                            (input_index*DATA_WIDTH) +: DATA_WIDTH
                        ]) - global_max;
                end
            end
        end
    end

    wire signed [DATA_WIDTH-1:0]
        cordic_out_data [0:NUM_ELEMENTS-1];
    wire [NUM_ELEMENTS-1:0] cordic_out_valid;

    genvar lane;
    generate
        for (lane = 0;
             lane < NUM_ELEMENTS;
             lane = lane + 1) begin : gen_cordic_lane
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
    assign exp_valid = cluster_valid;

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
