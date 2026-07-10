`timescale 1ns / 1ps

module divider #(
    parameter DATA_WIDTH      = 32,
    parameter FRACTIONAL_BITS = 16,
    parameter NUM_ELEMENTS    = 8
)(
    input  wire                                      clk,
    input  wire                                      rst_n,
    input  wire [(NUM_ELEMENTS*DATA_WIDTH)-1:0]      exp_array_in,
    input  wire                                      exp_valid,
    input  wire [DATA_WIDTH-1:0]                     sum_in,
    input  wire                                      sum_valid,
    output reg  [(NUM_ELEMENTS*DATA_WIDTH)-1:0]      softmax_array_out,
    output reg                                       softmax_valid
);

    localparam BUS_WIDTH = NUM_ELEMENTS * DATA_WIDTH;

    reg [BUS_WIDTH-1:0] exp_delay_d1;
    reg [BUS_WIDTH-1:0] exp_delay_d2;
    reg [BUS_WIDTH-1:0] exp_delay_d3;

    reg                 valid_delay_d1;
    reg                 valid_delay_d2;
    reg                 valid_delay_d3;

    integer i;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            exp_delay_d1 <= {BUS_WIDTH{1'b0}};
            exp_delay_d2 <= {BUS_WIDTH{1'b0}};
            exp_delay_d3 <= {BUS_WIDTH{1'b0}};

            valid_delay_d1 <= 1'b0;
            valid_delay_d2 <= 1'b0;
            valid_delay_d3 <= 1'b0;
        end else begin
            exp_delay_d1 <= exp_array_in;
            exp_delay_d2 <= exp_delay_d1;
            exp_delay_d3 <= exp_delay_d2;

            valid_delay_d1 <= exp_valid;
            valid_delay_d2 <= valid_delay_d1;
            valid_delay_d3 <= valid_delay_d2;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            softmax_array_out <= {BUS_WIDTH{1'b0}};
            softmax_valid     <= 1'b0;
        end else begin
            softmax_valid <= 1'b0;
            if (sum_valid && valid_delay_d3) begin
                if (sum_in != {DATA_WIDTH{1'b0}}) begin
                    for (i = 0; i < NUM_ELEMENTS; i = i + 1) begin
                        softmax_array_out[(i*DATA_WIDTH) +: DATA_WIDTH]
                            <= ({{DATA_WIDTH{1'b0}},
                                 exp_delay_d3[(i*DATA_WIDTH) +: DATA_WIDTH]}
                                << FRACTIONAL_BITS) / sum_in;
                    end
                end else begin
                    softmax_array_out <= {BUS_WIDTH{1'b0}};
                end
                softmax_valid <= 1'b1;
            end
        end
    end

endmodule
