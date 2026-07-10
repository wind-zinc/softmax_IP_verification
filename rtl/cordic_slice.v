`timescale 1ns / 1ps

module cordic_slice #(
    parameter DATA_WIDTH = 32,
    parameter SHIFT_AMT  = 1
)(
    input  wire                    clk,
    input  wire                    rst_n,
    input  wire signed [DATA_WIDTH-1:0] x_in,
    input  wire signed [DATA_WIDTH-1:0] y_in,
    input  wire signed [DATA_WIDTH-1:0] z_in,
    input  wire signed [DATA_WIDTH-1:0] angle_val,
    output reg  signed [DATA_WIDTH-1:0] x_out,
    output reg  signed [DATA_WIDTH-1:0] y_out,
    output reg  signed [DATA_WIDTH-1:0] z_out
);

    reg signed [DATA_WIDTH-1:0] x_next;
    reg signed [DATA_WIDTH-1:0] y_next;
    reg signed [DATA_WIDTH-1:0] z_next;
    
    wire signed [DATA_WIDTH-1:0] x_shifted;
    wire signed [DATA_WIDTH-1:0] y_shifted;
    
    assign x_shifted = x_in >>> SHIFT_AMT;
    assign y_shifted = y_in >>> SHIFT_AMT;
    
    always @(*) begin
        if (z_in[DATA_WIDTH-1] == 1'b0) begin 
            x_next = x_in + y_shifted;
            y_next = y_in + x_shifted;
            z_next = z_in - angle_val;
        end else begin
            x_next = x_in - y_shifted;
            y_next = y_in - x_shifted;
            z_next = z_in + angle_val;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            x_out <= {DATA_WIDTH{1'b0}};
            y_out <= {DATA_WIDTH{1'b0}};
            z_out <= {DATA_WIDTH{1'b0}};
        end else begin
            x_out <= x_next;
            y_out <= y_next;
            z_out <= z_next;
        end
    end

endmodule