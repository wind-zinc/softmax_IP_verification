`timescale 1ns / 1ps

module cordic_rom #(
    parameter DATA_WIDTH = 32,
    parameter PIPELINE_DEPTH = 16
)(
    input  wire clk,
    output wire [DATA_WIDTH*PIPELINE_DEPTH-1 : 0] angle_bus
);

    reg [DATA_WIDTH-1:0] rom_memory [0:PIPELINE_DEPTH-1];
    
    initial begin
        $readmemh("cordic_angle.mem", rom_memory);
    end

    genvar i;
    generate
        for (i = 0; i < PIPELINE_DEPTH; i = i + 1) begin : rom_read
            assign angle_bus[(i+1)*DATA_WIDTH-1 : i*DATA_WIDTH] = rom_memory[i];
        end
    endgenerate

endmodule