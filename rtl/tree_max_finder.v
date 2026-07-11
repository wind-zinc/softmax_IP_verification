`timescale 1ns / 1ps

module tree_max_finder #(
    parameter DATA_WIDTH   = 32,
    parameter NUM_ELEMENTS = 8
)(
    input  wire                                  clk,
    input  wire                                  rst_n,
    input  wire                                  valid_in,
    input  wire [(NUM_ELEMENTS*DATA_WIDTH)-1:0]  array_in,
    output reg  signed [DATA_WIDTH-1:0]          max_out,
    output reg                                   valid_out
);

    localparam integer TREE_LEVELS =
        (NUM_ELEMENTS <= 1) ? 1 : $clog2(NUM_ELEMENTS);
    localparam integer PADDED_ELEMENTS = 1 << TREE_LEVELS;
    localparam signed [DATA_WIDTH-1:0] MIN_VALUE =
        {1'b1, {(DATA_WIDTH-1){1'b0}}};

    wire signed [DATA_WIDTH-1:0]
        max_tree [0:TREE_LEVELS][0:PADDED_ELEMENTS-1];

    genvar leaf;
    generate
        for (leaf = 0; leaf < PADDED_ELEMENTS; leaf = leaf + 1) begin : gen_leaf
            if (leaf < NUM_ELEMENTS) begin : gen_real_leaf
                assign max_tree[0][leaf] =
                    $signed(array_in[(leaf*DATA_WIDTH) +: DATA_WIDTH]);
            end else begin : gen_padding_leaf
                assign max_tree[0][leaf] = MIN_VALUE;
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
                assign max_tree[level+1][node] =
                    (max_tree[level][2*node] > max_tree[level][2*node+1])
                    ? max_tree[level][2*node]
                    : max_tree[level][2*node+1];
            end
        end
    endgenerate

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            max_out   <= {DATA_WIDTH{1'b0}};
            valid_out <= 1'b0;
        end else begin
            max_out   <= max_tree[TREE_LEVELS][0];
            valid_out <= valid_in;
        end
    end

    initial begin
        if (NUM_ELEMENTS < 1)
            $error("tree_max_finder: NUM_ELEMENTS must be at least 1");
    end

endmodule
