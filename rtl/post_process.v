`timescale 1ns / 1ps

module post_process #(
    parameter DATA_WIDTH = 32
)(
    input  wire                    clk,
    input  wire                    rst_n,
    
    input  wire                    valid_in,
    input  wire signed [DATA_WIDTH-1:0] exp_in,
    input  wire signed [7:0]            k_in,
    
    output reg  signed [DATA_WIDTH-1:0] final_result,
    output reg                          valid_out
);
    
    reg [4:0] shift_amt;
    
    always @(*) begin
        if (k_in[7] == 1'b1) 
            shift_amt = (~k_in[4:0]) + 1'b1;
        else 
            shift_amt = 5'd0;
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            final_result <= 0;
            valid_out    <= 0;
        end else begin
            if (valid_in) begin
                final_result <= exp_in >> shift_amt;
                valid_out    <= 1'b1;
            end else begin
                valid_out    <= 1'b0;
            end
        end
    end

endmodule