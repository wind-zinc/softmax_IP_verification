`timescale 1ns / 1ps

module cordic_top #(
    parameter DATA_WIDTH = 32
)(
    input  wire                    clk,
    input  wire                    rst_n,

    input  wire                    valid_in,
    input  wire signed [DATA_WIDTH-1:0] x_in,
    
    output wire                    valid_out,
    output wire signed [DATA_WIDTH-1:0] exp_out
);

    localparam [DATA_WIDTH-1:0] INV_LN2_VAL = 32'h00017154;
    localparam [DATA_WIDTH-1:0] LN2_VAL     = 32'h0000B172;
    localparam [DATA_WIDTH-1:0] INIT_X_VAL  = 32'h0001351E;

    wire signed [DATA_WIDTH-1:0] r_wire;
    wire signed [7:0]            k_wire;
    wire                         valid_pre;

    wire signed [7:0]            k_delayed;
    wire signed [DATA_WIDTH-1:0] exp_core_res;
    wire                         valid_core;

    pre_process #(
        .DATA_WIDTH(DATA_WIDTH)
    ) u_pre_process (
        .clk        (clk),
        .rst_n      (rst_n),
        .valid_in   (valid_in),
        .x_in       (x_in),
        .INV_LN2_VAL(INV_LN2_VAL),
        .LN2_VAL    (LN2_VAL),
        .r_out      (r_wire),
        .k_out      (k_wire),
        .valid_out  (valid_pre)
    );

    cordic_core #(
        .DATA_WIDTH(DATA_WIDTH)
    ) u_cordic_core (
        .clk        (clk),
        .rst_n      (rst_n),
        .valid_in   (valid_pre),
        .z_in       (r_wire),
        .INIT_X_VAL (INIT_X_VAL),
        .exp_out    (exp_core_res),
        .valid_out  (valid_core)
    );

    delay_unit #(
        .DATA_WIDTH(8),
        .DELAY_CYCLES(16)
    ) u_delay_k (
        .clk     (clk),
        .rst_n   (rst_n),
        .data_in (k_wire),
        .data_out(k_delayed)
    );

    post_process #(
        .DATA_WIDTH(DATA_WIDTH)
    ) u_post_process (
        .clk         (clk),
        .rst_n       (rst_n),
        .valid_in    (valid_core),
        .exp_in      (exp_core_res),
        .k_in        (k_delayed),
        .final_result(exp_out),
        .valid_out   (valid_out)
    );

endmodule