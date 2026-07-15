`timescale 1ns/1ps

module tb_top;

    import uvm_pkg::*;
    import softmax_pkg::*;

    logic clk;

    softmax_if #(
        DATA_WIDTH,
        FRACTIONAL_BITS,
        NUM_ELEMENTS
    ) softmax_vif(.clk(clk));

    softmax_complete_top #(
        .DATA_WIDTH(DATA_WIDTH),
        .FRACTIONAL_BITS(FRACTIONAL_BITS),
        .NUM_ELEMENTS(NUM_ELEMENTS)
    ) dut (
        .clk(clk),
        .rst_n(softmax_vif.rst_n),
        .array_in(softmax_vif.array_in),
        .array_valid(softmax_vif.array_valid),
        .softmax_array_out(softmax_vif.softmax_array_out),
        .softmax_valid(softmax_vif.softmax_valid)
    );

    initial begin
        clk = 1'b0;
        forever #(CLK_PERIOD / 2) clk = ~clk;
    end

    initial begin
        uvm_config_db#(
            virtual softmax_if#(
                DATA_WIDTH,
                FRACTIONAL_BITS,
                NUM_ELEMENTS
            )
        )::set(null, "*", "vif", softmax_vif);
        run_test();
    end

    initial begin
        repeat (TEST_TIMEOUT_CYCLES + 1000) @(posedge clk);
        `uvm_fatal("GLOBAL_TIMEOUT", "global testbench timeout")
    end

`ifdef FSDB
    initial begin
        string fsdb_file;
        if (!$value$plusargs("FSDB_FILE=%s", fsdb_file))
            fsdb_file = "waves/softmax.fsdb";
        $fsdbDumpfile(fsdb_file);
        $fsdbDumpvars(0, tb_top);
    end
`endif

endmodule
