`ifndef SOFTMAX_CORNER_SEQUENCE_SV
`define SOFTMAX_CORNER_SEQUENCE_SV

class softmax_corner_sequence extends uvm_sequence #(softmax_transaction);

    `uvm_object_utils(softmax_corner_sequence)

    typedef logic signed [DATA_WIDTH-1:0] data_t;

    function new(string name = "softmax_corner_sequence");
        super.new(name);
    endfunction

    function data_t from_longint(longint signed value);
        return value[DATA_WIDTH-1:0];
    endfunction

    task send_vector(
        input data_t values[NUM_ELEMENTS],
        input string item_name
    );
        softmax_transaction req;

        req = softmax_transaction::type_id::create(item_name);
        start_item(req);
        req.op = op_normal;
        req.reset_cycles = 0;
        req.data_in = values;
        finish_item(req);
    endtask

    task send_lane_sweep(
        input longint signed low_value,
        input longint signed high_value,
        input string sweep_name
    );
        data_t values[NUM_ELEMENTS];

        for (int lane = 0; lane < NUM_ELEMENTS; lane++) begin
            foreach (values[i])
                values[i] = from_longint(low_value);

            values[lane] = from_longint(high_value);
            send_vector(
                values,
                $sformatf("%s_lane_%0d", sweep_name, lane)
            );
        end
    endtask

    task body();
        data_t values[NUM_ELEMENTS];
        longint signed one_fixed;
        longint signed step_value;

        one_fixed = 64'sd1 <<< FRACTIONAL_BITS;

        foreach (values[i])
            values[i] = '0;
        send_vector(values, "all_zero");

        foreach (values[i])
            values[i] = from_longint(one_fixed);
        send_vector(values, "all_positive_equal");

        foreach (values[i])
            values[i] = from_longint(-one_fixed);
        send_vector(values, "all_negative_equal");

        foreach (values[i])
            values[i] = from_longint(one_fixed);
        values[NUM_ELEMENTS-1] = from_longint(2 * one_fixed);
        send_vector(values, "all_positive_unique_max");

        foreach (values[i])
            values[i] = from_longint(-2 * one_fixed);
        values[0] = from_longint(-one_fixed);
        send_vector(values, "all_negative_unique_max");

        foreach (values[i])
            values[i] = from_longint(-one_fixed);
        values[0] = '0;
        send_vector(values, "nonpositive_with_zero");

        foreach (values[i])
            values[i] = from_longint(-one_fixed);
        values[0] = from_longint(one_fixed);
        if (NUM_ELEMENTS > 1)
            values[1] = from_longint(one_fixed);
        send_vector(values, "two_tied_maxima");

        send_lane_sweep(
            0,
            one_fixed / 2,
            "small_range"
        );

        send_lane_sweep(
            0,
            one_fixed,
            "small_range_medium_peak"
        );

        send_lane_sweep(
            -one_fixed,
            one_fixed,
            "medium_range"
        );

        send_lane_sweep(
            SOFTMAX_INPUT_MIN,
            SOFTMAX_INPUT_MAX,
            "large_range"
        );

        if (NUM_ELEMENTS > 1) begin
            step_value =
                (SOFTMAX_INPUT_MAX - SOFTMAX_INPUT_MIN) /
                (NUM_ELEMENTS - 1);

            foreach (values[i]) begin
                values[i] = from_longint(
                    SOFTMAX_INPUT_MIN + i * step_value
                );
            end
            send_vector(values, "nondecreasing_boundary_vector");

            foreach (values[i]) begin
                values[i] = from_longint(
                    SOFTMAX_INPUT_MAX - i * step_value
                );
            end
            send_vector(values, "nonincreasing_boundary_vector");
        end

        foreach (values[i])
            values[i] = '0;
        values[0] = from_longint(SOFTMAX_INPUT_MIN);
        send_vector(values, "contains_minimum_only");

        foreach (values[i])
            values[i] = '0;
        values[0] = from_longint(SOFTMAX_INPUT_MAX);
        send_vector(values, "contains_maximum_only");

        if (NUM_ELEMENTS > 1) begin
            foreach (values[i])
                values[i] = '0;
            values[0] = from_longint(SOFTMAX_INPUT_MIN);
            values[1] = from_longint(SOFTMAX_INPUT_MAX);
            send_vector(values, "contains_both_boundaries");
        end
    endtask

endclass

`endif
