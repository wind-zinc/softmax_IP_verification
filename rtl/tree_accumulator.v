`timescale 1ns / 1ps

module tree_accumulator #(
    parameter DATA_WIDTH   = 32,
    parameter NUM_ELEMENTS = 8,
    parameter TREE_LEVELS  =
        (NUM_ELEMENTS <= 1) ? 1 : $clog2(NUM_ELEMENTS),
    parameter SUM_WIDTH    = DATA_WIDTH + TREE_LEVELS
)(
    input  wire                                  clk,
    input  wire                                  rst_n,
    input  wire                                  valid_in,
    input  wire [(NUM_ELEMENTS*DATA_WIDTH)-1:0]  array_in,
    output wire [SUM_WIDTH-1:0]                  sum_out,
    output wire                                  valid_out
);

    localparam integer PADDED_ELEMENTS = 1 << TREE_LEVELS;

    wire signed [SUM_WIDTH-1:0]
        sum_tree [0:TREE_LEVELS][0:PADDED_ELEMENTS-1];

    genvar leaf;
    generate
        for (leaf = 0; leaf < PADDED_ELEMENTS; leaf = leaf + 1) begin : gen_leaf
            if (leaf < NUM_ELEMENTS) begin : gen_real_leaf
                assign sum_tree[0][leaf] = {
                    {(SUM_WIDTH-DATA_WIDTH){
                        array_in[(leaf*DATA_WIDTH)+DATA_WIDTH-1]
                    }},
                    array_in[(leaf*DATA_WIDTH) +: DATA_WIDTH]
                };
            end else begin : gen_padding_leaf
                assign sum_tree[0][leaf] = {SUM_WIDTH{1'b0}};
            end
        end
    endgenerate

    genvar level;
    genvar node;
    generate
        for (level = 0; level < TREE_LEVELS; level = level + 1) begin : gen_level
            for (node = 0;
                 node < (PADDED_ELEMENTS >> (level + 1));
                 node = node + 1) begin : gen_node
                reg signed [SUM_WIDTH-1:0] sum_reg;

                always @(posedge clk or negedge rst_n) begin
                    if (!rst_n)
                        sum_reg <= {SUM_WIDTH{1'b0}};
                    else
                        sum_reg <= sum_tree[level][2*node]
                                 + sum_tree[level][2*node+1];
                end

                assign sum_tree[level+1][node] = sum_reg;
            end
        end
    endgenerate

    reg [TREE_LEVELS-1:0] valid_pipe;
    integer valid_index;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_pipe <= {TREE_LEVELS{1'b0}};
        end else begin
            valid_pipe[0] <= valid_in;
            for (valid_index = 1;
                 valid_index < TREE_LEVELS;
                 valid_index = valid_index + 1)
                valid_pipe[valid_index] <= valid_pipe[valid_index-1];
        end
    end

    assign sum_out   = sum_tree[TREE_LEVELS][0];
    assign valid_out = valid_pipe[TREE_LEVELS-1];

    initial begin
        if (NUM_ELEMENTS < 1)
            $error("tree_accumulator: NUM_ELEMENTS must be at least 1");
        if (SUM_WIDTH < DATA_WIDTH + TREE_LEVELS)
            $error("tree_accumulator: SUM_WIDTH is too small");
    end

endmodule
