`ifndef SOFTMAX_PKG_SV
`define SOFTMAX_PKG_SV

`include "uvm_macros.svh"
`include "softmax_cfg.svh"

package softmax_pkg;

    import uvm_pkg::*;

    parameter int DATA_WIDTH = `SOFTMAX_DATA_WIDTH;
    parameter int FRACTIONAL_BITS = `SOFTMAX_FRACTIONAL_BITS;
    parameter int NUM_ELEMENTS = `SOFTMAX_NUM_ELEMENTS;

    parameter longint signed SOFTMAX_INPUT_MIN =
        `SOFTMAX_INPUT_MIN_INTEGER *
        (64'sd1 <<< FRACTIONAL_BITS);

    parameter longint signed SOFTMAX_INPUT_MAX =
        `SOFTMAX_INPUT_MAX_INTEGER *
        (64'sd1 <<< FRACTIONAL_BITS);

    parameter longint unsigned TOLERANCE_LSB =
        `SOFTMAX_TOLERANCE_LSB;

    parameter int unsigned RANDOM_TRANSACTION_COUNT =
        `SOFTMAX_RANDOM_TRANSACTION_COUNT;

    parameter int unsigned RESET_TRAFFIC_COUNT =
        `SOFTMAX_RESET_TRAFFIC_COUNT;

    parameter int unsigned TEST_TIMEOUT_CYCLES =
        `SOFTMAX_TEST_TIMEOUT_CYCLES;

    parameter int unsigned DRAIN_QUIET_CYCLES =
        `SOFTMAX_DRAIN_QUIET_CYCLES;

    parameter time CLK_PERIOD = `SOFTMAX_CLOCK_PERIOD;

    `include "softmax_transaction.sv"
    `include "softmax_random_sequence.sv"
    `include "softmax_corner_sequence.sv"
    `include "softmax_stream_sequence.sv"
    `include "softmax_reset_sequence.sv"
    `include "softmax_sequencer.sv"
    `include "softmax_driver.sv"
    `include "softmax_input_monitor.sv"
    `include "softmax_output_monitor.sv"
    `include "softmax_reference_model.sv"
    `include "softmax_scoreboard.sv"
    `include "softmax_coverage.sv"
    `include "softmax_agent.sv"
    `include "softmax_env.sv"
    `include "softmax_base_test.sv"
    `include "softmax_random_test.sv"
    `include "softmax_corner_test.sv"
    `include "softmax_stream_test.sv"
    `include "softmax_runtime_reset_test.sv"

endpackage

`endif
