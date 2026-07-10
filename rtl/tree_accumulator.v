`timescale 1ns / 1ps

module tree_accumulator #(
    parameter DATA_WIDTH = 32,
    parameter NUM_ELEMENTS = 8
)(
    input  wire                               clk,
    input  wire                               rst_n,
    input  wire                               valid_in,
    input  wire [(NUM_ELEMENTS*DATA_WIDTH)-1:0] array_in,   
    output reg  signed [DATA_WIDTH-1:0]       sum_out,
    output reg                                valid_out
);

    wire signed [DATA_WIDTH-1:0] node_in [0:7];
    genvar i;
    generate
        for (i = 0; i < 8; i = i + 1) begin : unpack_loop
            assign node_in[i] = array_in[(i*DATA_WIDTH) +: DATA_WIDTH];
        end
    endgenerate

    reg signed [DATA_WIDTH-1:0] sum_l1 [0:3];
    reg valid_l1;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sum_l1[0] <= 0; sum_l1[1] <= 0;
            sum_l1[2] <= 0; sum_l1[3] <= 0;
            valid_l1  <= 0;
        end else begin
            sum_l1[0] <= node_in[0] + node_in[1];
            sum_l1[1] <= node_in[2] + node_in[3];
            sum_l1[2] <= node_in[4] + node_in[5];
            sum_l1[3] <= node_in[6] + node_in[7];
            valid_l1  <= valid_in;
        end
    end

    reg signed [DATA_WIDTH-1:0] sum_l2 [0:1];
    reg valid_l2;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sum_l2[0] <= 0; sum_l2[1] <= 0;
            valid_l2  <= 0;
        end else begin
            sum_l2[0] <= sum_l1[0] + sum_l1[1];
            sum_l2[1] <= sum_l1[2] + sum_l1[3];
            valid_l2  <= valid_l1;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sum_out   <= 0;
            valid_out <= 0;
        end else begin
            sum_out   <= sum_l2[0] + sum_l2[1];
            valid_out <= valid_l2;
        end
    end

endmodule