`timescale 1ns / 1ps

module delay_unit #(
    parameter DATA_WIDTH  = 8,
    parameter DELAY_CYCLES = 16
)(
    input  wire                  clk,
    input  wire                  rst_n,
    input  wire [DATA_WIDTH-1:0] data_in,
    output wire [DATA_WIDTH-1:0] data_out
);

    reg [DATA_WIDTH-1:0] shift_reg [0:DELAY_CYCLES-1];
    
    integer i;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < DELAY_CYCLES; i = i + 1) begin
                shift_reg[i] <= {DATA_WIDTH{1'b0}};
            end
        end else begin
            shift_reg[0] <= data_in;
            
            for (i = 1; i < DELAY_CYCLES; i = i + 1) begin
                shift_reg[i] <= shift_reg[i-1];
            end
        end
    end

    assign data_out = shift_reg[DELAY_CYCLES-1];

endmodule