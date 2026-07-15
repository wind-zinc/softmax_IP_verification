`ifndef SOFTMAX_COVERAGE_SV
`define SOFTMAX_COVERAGE_SV

`uvm_analysis_imp_decl(_softmax_cov_input)
`uvm_analysis_imp_decl(_softmax_cov_output)

class softmax_coverage extends uvm_component;

    `uvm_component_utils(softmax_coverage)

    typedef enum bit [2:0] {
        SIGN_ALL_NEGATIVE,
        SIGN_ALL_POSITIVE,
        SIGN_ALL_ZERO,
        SIGN_MIXED,
        SIGN_NONNEG_WITH_ZERO,
        SIGN_NONPOS_WITH_ZERO
    } sign_class_e;

    typedef enum bit [1:0] {
        RANGE_ZERO,
        RANGE_SMALL,
        RANGE_MEDIUM,
        RANGE_LARGE
    } range_class_e;

    typedef enum bit [1:0] {
        MAX_UNIQUE,
        MAX_SOME_TIED,
        MAX_ALL_TIED
    } max_tie_class_e;

    typedef enum bit [1:0] {
        ORDER_ALL_EQUAL,
        ORDER_NONDECREASING,
        ORDER_NONINCREASING,
        ORDER_UNORDERED
    } order_class_e;

    typedef enum bit [2:0] {
        INPUT_UNIFORM,
        INPUT_TIED_NONUNIFORM,
        INPUT_UNIQUE_SMALL_RANGE,
        INPUT_UNIQUE_MEDIUM_RANGE,
        INPUT_UNIQUE_LARGE_RANGE
    } input_scenario_e;

    typedef enum bit [2:0] {
        BOUNDARY_NONE,
        BOUNDARY_MIN_ONLY,
        BOUNDARY_MAX_ONLY,
        BOUNDARY_BOTH
    } boundary_class_e;

    typedef enum bit [1:0] {
        PEAK_LOW,
        PEAK_MEDIUM,
        PEAK_HIGH,
        PEAK_NEAR_ONE
    } peak_class_e;

    typedef enum bit [1:0] {
        NEAR_ZERO_NONE,
        NEAR_ZERO_SOME,
        NEAR_ZERO_ALL
    } near_zero_class_e;

    typedef enum bit [1:0] {
        SUM_EXACT,
        SUM_NEAR,
        SUM_OUTSIDE
    } sum_class_e;

    typedef enum bit [1:0] {
        OUTPUT_UNIFORM,
        OUTPUT_TIED_NONUNIFORM,
        OUTPUT_DISTRIBUTED,
        OUTPUT_CONCENTRATED
    } output_scenario_e;

    virtual softmax_if #(
        DATA_WIDTH,
        FRACTIONAL_BITS,
        NUM_ELEMENTS
    ) vif;

    uvm_analysis_imp_softmax_cov_input #(
        softmax_transaction,
        softmax_coverage
    ) input_imp;

    uvm_analysis_imp_softmax_cov_output #(
        softmax_transaction,
        softmax_coverage
    ) output_imp;

    localparam longint unsigned TOLERANCE_LSB =
        `SOFTMAX_TOLERANCE_LSB;

    localparam int unsigned EXPECTED_LATENCY_CYCLES =
        `SOFTMAX_EXPECTED_LATENCY_CYCLES;

    time input_time_queue[$];

    int unsigned input_sample_count;
    int unsigned output_sample_count;
    int unsigned unknown_input_count;
    int unsigned unknown_output_count;
    int unsigned input_burst_count;
    int unsigned input_gap_count;
    int unsigned reset_count;
    int unsigned latency_sample_count;

    covergroup input_cg with function sample(
        int unsigned     max_index,
        sign_class_e     sign_kind,
        range_class_e    range_kind,
        max_tie_class_e  tie_kind,
        order_class_e    order_kind,
        input_scenario_e scenario_kind,
        boundary_class_e boundary_kind,
        bit              contains_zero
    );
        option.per_instance = 1;
        option.name = "softmax_input_coverage";

        cp_max_index : coverpoint max_index {
            bins bin_lane[] = {[0:NUM_ELEMENTS-1]};
        }

        cp_sign : coverpoint sign_kind {
            bins bin_all_negative = {SIGN_ALL_NEGATIVE};
            bins bin_all_positive = {SIGN_ALL_POSITIVE};
            bins bin_all_zero = {SIGN_ALL_ZERO};
            bins bin_mixed = {SIGN_MIXED};
            bins bin_nonneg_with_zero = {SIGN_NONNEG_WITH_ZERO};
            bins bin_nonpos_with_zero = {SIGN_NONPOS_WITH_ZERO};
        }

        cp_range : coverpoint range_kind {
            bins bin_range_zero = {RANGE_ZERO};
            bins bin_range_small = {RANGE_SMALL};
            bins bin_range_medium = {RANGE_MEDIUM};
            bins bin_range_large = {RANGE_LARGE};
        }

        cp_max_tie : coverpoint tie_kind {
            bins bin_unique = {MAX_UNIQUE};
            bins bin_some_tied = {MAX_SOME_TIED};
            bins bin_all_tied = {MAX_ALL_TIED};
        }

        cp_order : coverpoint order_kind {
            bins bin_all_equal = {ORDER_ALL_EQUAL};
            bins bin_nondecreasing = {ORDER_NONDECREASING};
            bins bin_nonincreasing = {ORDER_NONINCREASING};
            bins bin_unordered = {ORDER_UNORDERED};
        }

        cp_scenario : coverpoint scenario_kind {
            bins bin_uniform = {INPUT_UNIFORM};
            bins bin_tied_nonuniform = {INPUT_TIED_NONUNIFORM};
            bins bin_unique_small = {INPUT_UNIQUE_SMALL_RANGE};
            bins bin_unique_medium = {INPUT_UNIQUE_MEDIUM_RANGE};
            bins bin_unique_large = {INPUT_UNIQUE_LARGE_RANGE};
        }

        cp_boundary : coverpoint boundary_kind {
            bins bin_boundary_none = {BOUNDARY_NONE};
            bins bin_boundary_min = {BOUNDARY_MIN_ONLY};
            bins bin_boundary_max = {BOUNDARY_MAX_ONLY};
            bins bin_boundary_both = {BOUNDARY_BOTH};
        }

        cp_contains_zero : coverpoint contains_zero {
            bins bin_zero_absent = {1'b0};
            bins bin_zero_present = {1'b1};
        }

        cp_cross_range : coverpoint range_kind
            iff (tie_kind == MAX_UNIQUE) {
            bins bin_cross_small = {RANGE_SMALL};
            bins bin_cross_medium = {RANGE_MEDIUM};
            bins bin_cross_large = {RANGE_LARGE};
            ignore_bins bin_cross_zero = {RANGE_ZERO};
        }

        x_unique_lane_by_range : cross cp_max_index, cp_cross_range;
    endgroup

    covergroup output_cg with function sample(
        int unsigned       max_index,
        peak_class_e       peak_kind,
        near_zero_class_e  near_zero_kind,
        max_tie_class_e    tie_kind,
        sum_class_e        sum_kind,
        output_scenario_e  scenario_kind
    );
        option.per_instance = 1;
        option.name = "softmax_output_coverage";

        cp_max_index : coverpoint max_index {
            bins bin_lane[] = {[0:NUM_ELEMENTS-1]};
        }

        cp_peak : coverpoint peak_kind {
            bins bin_peak_low = {PEAK_LOW};
            bins bin_peak_medium = {PEAK_MEDIUM};
            bins bin_peak_high = {PEAK_HIGH};
            bins bin_peak_near_one = {PEAK_NEAR_ONE};
        }

        cp_near_zero : coverpoint near_zero_kind {
            bins bin_near_zero_none = {NEAR_ZERO_NONE};
            bins bin_near_zero_some = {NEAR_ZERO_SOME};
            illegal_bins bin_near_zero_all = {NEAR_ZERO_ALL};
        }

        cp_max_tie : coverpoint tie_kind {
            bins bin_unique = {MAX_UNIQUE};
            bins bin_some_tied = {MAX_SOME_TIED};
            bins bin_all_tied = {MAX_ALL_TIED};
        }

        cp_sum : coverpoint sum_kind {
            bins bin_sum_exact = {SUM_EXACT};
            bins bin_sum_near = {SUM_NEAR};
            illegal_bins bin_sum_outside = {SUM_OUTSIDE};
        }

        cp_scenario : coverpoint scenario_kind {
            bins bin_uniform = {OUTPUT_UNIFORM};
            bins bin_tied_nonuniform = {OUTPUT_TIED_NONUNIFORM};
            bins bin_distributed = {OUTPUT_DISTRIBUTED};
            bins bin_concentrated = {OUTPUT_CONCENTRATED};
        }

        cp_unique_peak : coverpoint peak_kind
            iff (tie_kind == MAX_UNIQUE) {
            bins bin_unique_low = {PEAK_LOW};
            bins bin_unique_medium = {PEAK_MEDIUM};
            bins bin_unique_high = {PEAK_HIGH};
            bins bin_unique_near_one = {PEAK_NEAR_ONE};
        }

        x_unique_lane_by_peak : cross cp_max_index, cp_unique_peak;
    endgroup

    covergroup burst_cg with function sample(int unsigned burst_length);
        option.per_instance = 1;
        option.name = "softmax_input_burst_coverage";

        cp_burst_length : coverpoint burst_length {
            bins bin_burst_single = {1};
            bins bin_burst_short = {[2:4]};
            bins bin_burst_medium = {[5:16]};
            bins bin_burst_long = {[17:$]};
        }
    endgroup

    covergroup gap_cg with function sample(int unsigned gap_length);
        option.per_instance = 1;
        option.name = "softmax_input_gap_coverage";

        cp_gap_length : coverpoint gap_length {
            bins bin_gap_single = {1};
            bins bin_gap_short = {[2:4]};
            bins bin_gap_long = {[5:$]};
        }
    endgroup

    covergroup reset_cg with function sample(bit reset_after_traffic);
        option.per_instance = 1;
        option.name = "softmax_reset_coverage";

        cp_reset_kind : coverpoint reset_after_traffic {
            bins bin_initial_reset = {1'b0};
            bins bin_runtime_reset = {1'b1};
        }
    endgroup

    covergroup latency_cg with function sample(int unsigned latency_cycles);
        option.per_instance = 1;
        option.name = "softmax_latency_coverage";

        cp_latency : coverpoint latency_cycles {
            bins bin_expected_latency = {EXPECTED_LATENCY_CYCLES};
            illegal_bins bin_too_short =
                {[0:EXPECTED_LATENCY_CYCLES-1]};
            illegal_bins bin_too_long =
                {[EXPECTED_LATENCY_CYCLES+1:$]};
        }
    endgroup

    function new(
        string name = "softmax_coverage",
        uvm_component parent = null
    );
        super.new(name, parent);

        input_imp = new("input_imp", this);
        output_imp = new("output_imp", this);
        input_cg = new();
        output_cg = new();
        burst_cg = new();
        gap_cg = new();
        reset_cg = new();
        latency_cg = new();
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        if (!uvm_config_db#(
            virtual softmax_if#(
                DATA_WIDTH,
                FRACTIONAL_BITS,
                NUM_ELEMENTS
            )
        )::get(this, "", "vif", vif)) begin
            `uvm_fatal("NOVIF", "vif must be set for softmax_coverage")
        end
    endfunction

    function void write_softmax_cov_input(softmax_transaction tr);
        longint signed values[NUM_ELEMENTS];
        longint signed minimum;
        longint signed maximum;
        longint unsigned span;
        longint unsigned one_fixed;
        int unsigned max_index;
        int unsigned max_tie_count;
        int unsigned negative_count;
        int unsigned positive_count;
        int unsigned zero_count;
        bit has_minimum;
        bit has_maximum;
        bit nondecreasing;
        bit nonincreasing;
        sign_class_e sign_kind;
        range_class_e range_kind;
        max_tie_class_e tie_kind;
        order_class_e order_kind;
        input_scenario_e scenario_kind;
        boundary_class_e boundary_kind;

        input_time_queue.push_back($time);

        foreach (tr.data_in[i]) begin
            if ($isunknown(tr.data_in[i])) begin
                unknown_input_count++;
                `uvm_warning(
                    "COV_INPUT_X",
                    $sformatf("data_in[%0d] contains X or Z", i)
                )
                return;
            end
            values[i] = $signed(tr.data_in[i]);
        end

        minimum = values[0];
        maximum = values[0];
        max_index = 0;
        negative_count = 0;
        positive_count = 0;
        zero_count = 0;
        has_minimum = 1'b0;
        has_maximum = 1'b0;
        nondecreasing = 1'b1;
        nonincreasing = 1'b1;

        foreach (values[i]) begin
            if (values[i] < minimum)
                minimum = values[i];

            if (values[i] > maximum) begin
                maximum = values[i];
                max_index = i;
            end

            if (values[i] < 0)
                negative_count++;
            else if (values[i] > 0)
                positive_count++;
            else
                zero_count++;

            if (values[i] == SOFTMAX_INPUT_MIN)
                has_minimum = 1'b1;
            if (values[i] == SOFTMAX_INPUT_MAX)
                has_maximum = 1'b1;

            if (i > 0) begin
                if (values[i] < values[i-1])
                    nondecreasing = 1'b0;
                if (values[i] > values[i-1])
                    nonincreasing = 1'b0;
            end
        end

        max_tie_count = 0;
        foreach (values[i]) begin
            if (values[i] == maximum)
                max_tie_count++;
        end

        span = maximum - minimum;
        one_fixed = 64'd1 << FRACTIONAL_BITS;

        if (span == 0)
            range_kind = RANGE_ZERO;
        else if (span <= one_fixed)
            range_kind = RANGE_SMALL;
        else if (span <= (4 * one_fixed))
            range_kind = RANGE_MEDIUM;
        else
            range_kind = RANGE_LARGE;

        if (max_tie_count == 1)
            tie_kind = MAX_UNIQUE;
        else if (max_tie_count == NUM_ELEMENTS)
            tie_kind = MAX_ALL_TIED;
        else
            tie_kind = MAX_SOME_TIED;

        if (negative_count == NUM_ELEMENTS)
            sign_kind = SIGN_ALL_NEGATIVE;
        else if (positive_count == NUM_ELEMENTS)
            sign_kind = SIGN_ALL_POSITIVE;
        else if (zero_count == NUM_ELEMENTS)
            sign_kind = SIGN_ALL_ZERO;
        else if ((negative_count != 0) && (positive_count != 0))
            sign_kind = SIGN_MIXED;
        else if (negative_count == 0)
            sign_kind = SIGN_NONNEG_WITH_ZERO;
        else
            sign_kind = SIGN_NONPOS_WITH_ZERO;

        if (span == 0)
            order_kind = ORDER_ALL_EQUAL;
        else if (nondecreasing)
            order_kind = ORDER_NONDECREASING;
        else if (nonincreasing)
            order_kind = ORDER_NONINCREASING;
        else
            order_kind = ORDER_UNORDERED;

        if (tie_kind == MAX_ALL_TIED)
            scenario_kind = INPUT_UNIFORM;
        else if (tie_kind == MAX_SOME_TIED)
            scenario_kind = INPUT_TIED_NONUNIFORM;
        else if (range_kind == RANGE_SMALL)
            scenario_kind = INPUT_UNIQUE_SMALL_RANGE;
        else if (range_kind == RANGE_MEDIUM)
            scenario_kind = INPUT_UNIQUE_MEDIUM_RANGE;
        else
            scenario_kind = INPUT_UNIQUE_LARGE_RANGE;

        if (has_minimum && has_maximum)
            boundary_kind = BOUNDARY_BOTH;
        else if (has_minimum)
            boundary_kind = BOUNDARY_MIN_ONLY;
        else if (has_maximum)
            boundary_kind = BOUNDARY_MAX_ONLY;
        else
            boundary_kind = BOUNDARY_NONE;

        input_cg.sample(
            max_index,
            sign_kind,
            range_kind,
            tie_kind,
            order_kind,
            scenario_kind,
            boundary_kind,
            (zero_count != 0)
        );

        input_sample_count++;
    endfunction

    function void write_softmax_cov_output(softmax_transaction tr);
        longint unsigned values[NUM_ELEMENTS];
        longint unsigned maximum;
        longint unsigned sum;
        longint unsigned expected_sum;
        longint unsigned sum_difference;
        int unsigned max_index;
        int unsigned max_tie_count;
        int unsigned near_zero_count;
        int unsigned latency_cycles;
        time input_time;
        peak_class_e peak_kind;
        near_zero_class_e near_zero_kind;
        max_tie_class_e tie_kind;
        sum_class_e sum_kind;
        output_scenario_e scenario_kind;

        if (input_time_queue.size() != 0) begin
            input_time = input_time_queue.pop_front();
            latency_cycles = ($time - input_time) / CLK_PERIOD;
            latency_cg.sample(latency_cycles);
            latency_sample_count++;
        end
        else begin
            `uvm_warning(
                "COV_LATENCY_UNPAIRED",
                "Output arrived without a queued input timestamp"
            )
        end

        if ($isunknown(tr.softmax_array_out)) begin
            unknown_output_count++;
            `uvm_warning(
                "COV_OUTPUT_X",
                "softmax_array_out contains X or Z"
            )
            return;
        end

        foreach (values[i]) begin
            values[i] = tr.softmax_array_out[
                i*DATA_WIDTH +: DATA_WIDTH
            ];
        end

        maximum = values[0];
        max_index = 0;
        near_zero_count = 0;
        sum = 0;

        foreach (values[i]) begin
            sum += values[i];

            if (values[i] <= TOLERANCE_LSB)
                near_zero_count++;

            if (values[i] > maximum) begin
                maximum = values[i];
                max_index = i;
            end
        end

        max_tie_count = 0;
        foreach (values[i]) begin
            if (values[i] == maximum)
                max_tie_count++;
        end

        expected_sum = 64'd1 << FRACTIONAL_BITS;
        if (sum >= expected_sum)
            sum_difference = sum - expected_sum;
        else
            sum_difference = expected_sum - sum;

        if (maximum <= (expected_sum / 4))
            peak_kind = PEAK_LOW;
        else if (maximum <= (expected_sum / 2))
            peak_kind = PEAK_MEDIUM;
        else if (maximum <= ((3 * expected_sum) / 4))
            peak_kind = PEAK_HIGH;
        else
            peak_kind = PEAK_NEAR_ONE;

        if (near_zero_count == 0)
            near_zero_kind = NEAR_ZERO_NONE;
        else if (near_zero_count == NUM_ELEMENTS)
            near_zero_kind = NEAR_ZERO_ALL;
        else
            near_zero_kind = NEAR_ZERO_SOME;

        if (max_tie_count == 1)
            tie_kind = MAX_UNIQUE;
        else if (max_tie_count == NUM_ELEMENTS)
            tie_kind = MAX_ALL_TIED;
        else
            tie_kind = MAX_SOME_TIED;

        if (sum_difference == 0)
            sum_kind = SUM_EXACT;
        else if (sum_difference <= (NUM_ELEMENTS * TOLERANCE_LSB))
            sum_kind = SUM_NEAR;
        else
            sum_kind = SUM_OUTSIDE;

        if (tie_kind == MAX_ALL_TIED)
            scenario_kind = OUTPUT_UNIFORM;
        else if (tie_kind == MAX_SOME_TIED)
            scenario_kind = OUTPUT_TIED_NONUNIFORM;
        else if ((peak_kind == PEAK_LOW) ||
                 (peak_kind == PEAK_MEDIUM))
            scenario_kind = OUTPUT_DISTRIBUTED;
        else
            scenario_kind = OUTPUT_CONCENTRATED;

        output_cg.sample(
            max_index,
            peak_kind,
            near_zero_kind,
            tie_kind,
            sum_kind,
            scenario_kind
        );

        output_sample_count++;
    endfunction

    task run_phase(uvm_phase phase);
        int unsigned current_burst_length;
        int unsigned current_gap_length;
        bit in_reset;
        bit traffic_seen;

        current_burst_length = 0;
        current_gap_length = 0;
        in_reset = 1'b0;
        traffic_seen = 1'b0;

        forever begin
            @(vif.mon_cb);

            if (vif.mon_cb.rst_n === 1'b0) begin
                if (!in_reset) begin
                    if (current_burst_length != 0) begin
                        burst_cg.sample(current_burst_length);
                        input_burst_count++;
                    end

                    current_burst_length = 0;
                    current_gap_length = 0;
                    input_time_queue.delete();
                    reset_cg.sample(traffic_seen);
                    reset_count++;
                    in_reset = 1'b1;
                end
            end
            else if (vif.mon_cb.rst_n === 1'b1) begin
                in_reset = 1'b0;

                if (vif.mon_cb.array_valid === 1'b1) begin
                    if ((current_gap_length != 0) && traffic_seen) begin
                        gap_cg.sample(current_gap_length);
                        input_gap_count++;
                    end

                    current_gap_length = 0;
                    current_burst_length++;
                    traffic_seen = 1'b1;
                end
                else begin
                    if (current_burst_length != 0) begin
                        burst_cg.sample(current_burst_length);
                        input_burst_count++;
                        current_burst_length = 0;
                    end

                    if (traffic_seen)
                        current_gap_length++;
                end
            end
        end
    endtask

    function void report_phase(uvm_phase phase);
        super.report_phase(phase);

        `uvm_info(
            "SOFTMAX_COVERAGE",
            $sformatf(
                {"samples(in/out)=%0d/%0d unknown(in/out)=%0d/%0d ",
                 "bursts=%0d gaps=%0d resets=%0d latency_samples=%0d | ",
                 "input=%0.2f%% output=%0.2f%% burst=%0.2f%% ",
                 "gap=%0.2f%% reset=%0.2f%% latency=%0.2f%%"},
                input_sample_count,
                output_sample_count,
                unknown_input_count,
                unknown_output_count,
                input_burst_count,
                input_gap_count,
                reset_count,
                latency_sample_count,
                input_cg.get_inst_coverage(),
                output_cg.get_inst_coverage(),
                burst_cg.get_inst_coverage(),
                gap_cg.get_inst_coverage(),
                reset_cg.get_inst_coverage(),
                latency_cg.get_inst_coverage()
            ),
            UVM_LOW
        )
    endfunction

endclass

`endif
