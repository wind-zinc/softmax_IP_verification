`ifndef SOFTMAX_IF_SV
`define SOFTMAX_IF_SV

`timescale 1ns/1ps

interface softmax_if #(
	parameter int DATA_WIDTH      = 32,
    parameter int FRACTIONAL_BITS = 16,
    parameter int NUM_ELEMENTS    = 8
)(
	input logic clk
);

	logic 								  rst_n;
	logic [(NUM_ELEMENTS*DATA_WIDTH)-1:0] array_in;
	logic 							      array_valid;
	logic [(NUM_ELEMENTS*DATA_WIDTH)-1:0] softmax_array_out;
	logic 							      softmax_valid;
	
	clocking drv_cb @(negedge clk);
		default input #1step output #1step;
		
		output rst_n;
		output array_in;
		output array_valid;
		
		//input softmax_array_out;
		//input softmax_valid;
	endclocking
	
	clocking mon_cb @(posedge clk);
		default input #1step;
		
		input rst_n;
		input array_in;
		input array_valid;
		input softmax_array_out;
		input softmax_valid;
	endclocking
	
	modport DUT (
		input clk,
		input rst_n,
		input array_in,
		input array_valid,
		output softmax_array_out,
		output softmax_valid
	);
	
	modport DRIVER (
		input clk,
		clocking drv_cb
	);
	
	modport MONITOR (
		input clk,
		clocking mon_cb
	);

endinterface

`endif