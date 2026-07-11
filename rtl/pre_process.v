`timescale 1ns / 1ps

module pre_process #(
    parameter DATA_WIDTH = 32
)(
    input  wire                    clk,
    input  wire                    rst_n,
    input  wire                    valid_in, 
    input  wire signed [DATA_WIDTH-1:0] x_in,     
    
    input  wire signed [DATA_WIDTH-1:0] INV_LN2_VAL, 
    input  wire signed [DATA_WIDTH-1:0] LN2_VAL,

    output reg  signed [DATA_WIDTH-1:0] r_out,    
    output reg  signed [7:0]            k_out,    
    output reg                          valid_out 
);

    reg signed [2*DATA_WIDTH-1:0] mult_res_raw;
    reg signed [DATA_WIDTH-1:0]   x_d1;
    reg                           val_d1;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mult_res_raw <= 0;
            x_d1         <= 0;
            val_d1       <= 0;
        end else begin
            mult_res_raw <= x_in * INV_LN2_VAL;
            x_d1         <= x_in;
            val_d1       <= valid_in;
        end
    end
    
    reg signed [DATA_WIDTH-1:0] k_round_reg;
    reg signed [DATA_WIDTH-1:0] x_d2;
    reg                         val_d2;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            k_round_reg <= 0;
            x_d2        <= 0;
            val_d2      <= 0;
        end else begin
            k_round_reg <= ($signed(mult_res_raw) + $signed({32'd0, 1'b1, 31'd0})) >>> 32;
            x_d2        <= x_d1;
            val_d2      <= val_d1;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            r_out     <= 0;
            k_out     <= 0;
            valid_out <= 0;
        end else begin
            r_out     <= x_d2 - (k_round_reg * LN2_VAL);
            k_out     <= k_round_reg[7:0];
            valid_out <= val_d2;
        end
    end

endmodule