`timescale 1ns / 1ps

module divider #(
    parameter DATA_WIDTH      = 32,
    parameter FRACTIONAL_BITS = 16,
    parameter NUM_ELEMENTS    = 8,
    parameter ALIGN_DELAY     =
        (NUM_ELEMENTS <= 1) ? 1 : $clog2(NUM_ELEMENTS),
    parameter SUM_WIDTH       = DATA_WIDTH + ALIGN_DELAY
)(
    input  wire                                  clk,
    input  wire                                  rst_n,
    input  wire [(NUM_ELEMENTS*DATA_WIDTH)-1:0]  exp_array_in,
    input  wire                                  exp_valid,
    input  wire [SUM_WIDTH-1:0]                  sum_in,
    input  wire                                  sum_valid,
    output reg  [(NUM_ELEMENTS*DATA_WIDTH)-1:0]  softmax_array_out,
    output reg                                   softmax_valid
);

    localparam integer BUS_WIDTH = NUM_ELEMENTS * DATA_WIDTH;

    reg [BUS_WIDTH-1:0] exp_delay   [0:ALIGN_DELAY-1];
    reg                 valid_delay [0:ALIGN_DELAY-1];

    integer delay_index;
    integer result_index;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (delay_index = 0;
                 delay_index < ALIGN_DELAY;
                 delay_index = delay_index + 1) begin
                exp_delay[delay_index]   <= {BUS_WIDTH{1'b0}};
                valid_delay[delay_index] <= 1'b0;
            end
        end else begin
            exp_delay[0]   <= exp_array_in;
            valid_delay[0] <= exp_valid;

            for (delay_index = 1;
                 delay_index < ALIGN_DELAY;
                 delay_index = delay_index + 1) begin
                exp_delay[delay_index]   <= exp_delay[delay_index-1];
                valid_delay[delay_index] <= valid_delay[delay_index-1];
            end
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            softmax_array_out <= {BUS_WIDTH{1'b0}};
            softmax_valid     <= 1'b0;
        end else begin
            softmax_valid <= 1'b0;

            if (sum_valid && valid_delay[ALIGN_DELAY-1]) begin
                if (sum_in != {SUM_WIDTH{1'b0}}) begin
                    for (result_index = 0;
                         result_index < NUM_ELEMENTS;
                         result_index = result_index + 1) begin
                        softmax_array_out[
                            (result_index*DATA_WIDTH) +: DATA_WIDTH
                        ] <= (
                            {{DATA_WIDTH{1'b0}},
                             exp_delay[ALIGN_DELAY-1][
                                 (result_index*DATA_WIDTH) +: DATA_WIDTH
                             ]}
                            << FRACTIONAL_BITS
                        ) / sum_in;
                    end
                end else begin
                    softmax_array_out <= {BUS_WIDTH{1'b0}};
                end

                softmax_valid <= 1'b1;
            end
        end
    end

    initial begin
        if (NUM_ELEMENTS < 1)
            $error("divider: NUM_ELEMENTS must be at least 1");
        if (FRACTIONAL_BITS < 0 || FRACTIONAL_BITS > DATA_WIDTH)
            $error("divider: invalid FRACTIONAL_BITS");
    end

endmodule
