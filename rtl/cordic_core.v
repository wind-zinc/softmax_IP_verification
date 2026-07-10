`timescale 1ns / 1ps
module cordic_core #(
    parameter DATA_WIDTH = 32
)(
    input  wire                    clk,
    input  wire                    rst_n, 
    input  wire signed [DATA_WIDTH-1:0] z_in,
    input  wire signed [DATA_WIDTH-1:0] INIT_X_VAL,
    input  wire                    valid_in,
    output wire signed [DATA_WIDTH-1:0] exp_out,
    output wire                         valid_out
);

    wire signed [DATA_WIDTH-1:0] x_wires [0:16];
    wire signed [DATA_WIDTH-1:0] y_wires [0:16];
    wire signed [DATA_WIDTH-1:0] z_wires [0:16];

    wire [DATA_WIDTH*16-1 : 0] angle_bus_full;

    cordic_rom #(
        .DATA_WIDTH(DATA_WIDTH),
        .PIPELINE_DEPTH(16)
    ) u_rom (
        .clk      (clk),
        .angle_bus(angle_bus_full)
    );

    assign x_wires[0] = INIT_X_VAL; 
    assign y_wires[0] = {DATA_WIDTH{1'b0}}; 
    assign z_wires[0] = z_in;

    function integer get_shift_amt;
        input integer stage_index;
        begin
            case (stage_index)
                0:  get_shift_amt = 1;
                1:  get_shift_amt = 2;
                2:  get_shift_amt = 3;
                3:  get_shift_amt = 4;
                4:  get_shift_amt = 4;
                5:  get_shift_amt = 5;
                6:  get_shift_amt = 6;
                7:  get_shift_amt = 7;
                8:  get_shift_amt = 8;
                9:  get_shift_amt = 9;
                10: get_shift_amt = 10;
                11: get_shift_amt = 11;
                12: get_shift_amt = 12;
                13: get_shift_amt = 13;
                14: get_shift_amt = 13;
                15: get_shift_amt = 14;
                default: get_shift_amt = 1;
            endcase
        end
    endfunction

    genvar i;
    generate
        for (i = 0; i < 16; i = i + 1) begin : pipe_stage

            wire signed [DATA_WIDTH-1:0] current_angle;
            assign current_angle = angle_bus_full[(i+1)*DATA_WIDTH-1 : i*DATA_WIDTH];

            cordic_slice #(
                .DATA_WIDTH(DATA_WIDTH),
                .SHIFT_AMT (get_shift_amt(i)) 
            ) u_slice (
                .clk      (clk),
                .rst_n    (rst_n),
                .x_in     (x_wires[i]),
                .y_in     (y_wires[i]),
                .z_in     (z_wires[i]),
                .angle_val(current_angle),
                .x_out    (x_wires[i+1]),
                .y_out    (y_wires[i+1]),
                .z_out    (z_wires[i+1])
            );
        end
    endgenerate

    assign exp_out = x_wires[16] + y_wires[16];
    
    reg [15:0] valid_pipe;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) 
            valid_pipe <= 16'b0;
        else 
            valid_pipe <= {valid_pipe[14:0], valid_in}; 
    end
    assign valid_out = valid_pipe[15];

endmodule