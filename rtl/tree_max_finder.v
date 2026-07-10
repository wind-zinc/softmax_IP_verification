`timescale 1ns / 1ps

module tree_max_finder #(
    parameter DATA_WIDTH = 32,
    parameter NUM_ELEMENTS = 8
)(
    input  wire                               clk,
    input  wire                               rst_n,
    input  wire                               valid_in,
    input  wire [(NUM_ELEMENTS*DATA_WIDTH)-1:0] array_in,  
    output reg  signed [DATA_WIDTH-1:0]       max_out,
    output reg                                valid_out
);

    wire signed [DATA_WIDTH-1:0] node_level_0 [0:7];
    
    genvar i;
    generate
        for (i = 0; i < 8; i = i + 1) begin : unpack_loop
            assign node_level_0[i] = array_in[(i*DATA_WIDTH) +: DATA_WIDTH];
        end
    endgenerate

    wire signed [DATA_WIDTH-1:0] node_level_1 [0:3];
    assign node_level_1[0] = (node_level_0[0] > node_level_0[1]) ? node_level_0[0] : node_level_0[1];
    assign node_level_1[1] = (node_level_0[2] > node_level_0[3]) ? node_level_0[2] : node_level_0[3];
    assign node_level_1[2] = (node_level_0[4] > node_level_0[5]) ? node_level_0[4] : node_level_0[5];
    assign node_level_1[3] = (node_level_0[6] > node_level_0[7]) ? node_level_0[6] : node_level_0[7];

    wire signed [DATA_WIDTH-1:0] node_level_2 [0:1];
    assign node_level_2[0] = (node_level_1[0] > node_level_1[1]) ? node_level_1[0] : node_level_1[1];
    assign node_level_2[1] = (node_level_1[2] > node_level_1[3]) ? node_level_1[2] : node_level_1[3];

    wire signed [DATA_WIDTH-1:0] final_max_comb;
    assign final_max_comb = (node_level_2[0] > node_level_2[1]) ? node_level_2[0] : node_level_2[1];

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            max_out   <= 0;
            valid_out <= 0;
        end else begin
            max_out   <= final_max_comb;
            valid_out <= valid_in; 
        end
    end

endmodule