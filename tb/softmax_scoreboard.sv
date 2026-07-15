`ifndef SOFTMAX_SCOREBOARD_SV
`define SOFTMAX_SCOREBOARD_SV

`uvm_analysis_imp_decl(_softmax_expected)
`uvm_analysis_imp_decl(_softmax_actual)

class softmax_scoreboard extends uvm_scoreboard;

    `uvm_component_utils(softmax_scoreboard)

    typedef enum bit [2:0] {
        ERROR_EXACT,
        ERROR_1_TO_4,
        ERROR_5_TO_16,
        ERROR_17_TO_32,
        ERROR_33_TO_LIMIT,
        ERROR_OUTSIDE_LIMIT
    } error_class_e;

    virtual softmax_if #(
        DATA_WIDTH,
        FRACTIONAL_BITS,
        NUM_ELEMENTS
    ) vif;

    uvm_analysis_imp_softmax_expected #(
        softmax_transaction,
        softmax_scoreboard
    ) expected_imp;

    uvm_analysis_imp_softmax_actual #(
        softmax_transaction,
        softmax_scoreboard
    ) actual_imp;

    softmax_transaction expected_queue[$];
    softmax_transaction actual_queue[$];

    int unsigned expected_received;
    int unsigned actual_received;
    int unsigned compared_count;
    int unsigned passed_count;
    int unsigned failed_count;
    int unsigned lane_mismatch_count;
    int unsigned reset_flush_count;
    int unsigned reset_dropped_expected;
    int unsigned reset_dropped_actual;
    longint unsigned maximum_observed_error;

    covergroup lane_error_cg with function sample(
        int unsigned lane,
        error_class_e error_kind
    );
        option.per_instance = 1;
        option.name = "softmax_lane_error_coverage";

        cp_lane : coverpoint lane {
            bins bin_lane[] = {[0:NUM_ELEMENTS-1]};
        }

        cp_error : coverpoint error_kind {
            bins bin_exact = {ERROR_EXACT};
            bins bin_1_to_4 = {ERROR_1_TO_4};
            bins bin_5_to_16 = {ERROR_5_TO_16};
            bins bin_17_to_32 = {ERROR_17_TO_32};
            bins bin_33_to_limit = {ERROR_33_TO_LIMIT};
            illegal_bins bin_outside_limit = {ERROR_OUTSIDE_LIMIT};
        }
    endgroup

    covergroup transaction_error_cg with function sample(
        error_class_e maximum_error_kind
    );
        option.per_instance = 1;
        option.name = "softmax_transaction_error_coverage";

        cp_maximum_error : coverpoint maximum_error_kind {
            bins bin_exact = {ERROR_EXACT};
            bins bin_1_to_4 = {ERROR_1_TO_4};
            bins bin_5_to_16 = {ERROR_5_TO_16};
            bins bin_17_to_32 = {ERROR_17_TO_32};
            bins bin_33_to_limit = {ERROR_33_TO_LIMIT};
            illegal_bins bin_outside_limit = {ERROR_OUTSIDE_LIMIT};
        }
    endgroup

    function new(
        string name = "softmax_scoreboard",
        uvm_component parent = null
    );
        super.new(name, parent);
        lane_error_cg = new();
        transaction_error_cg = new();
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        expected_imp = new("expected_imp", this);
        actual_imp = new("actual_imp", this);

        if (!uvm_config_db#(
            virtual softmax_if#(
                DATA_WIDTH,
                FRACTIONAL_BITS,
                NUM_ELEMENTS
            )
        )::get(this, "", "vif", vif)) begin
            `uvm_fatal("NOVIF", "vif must be set for softmax_scoreboard")
        end
    endfunction

    function error_class_e classify_error(longint unsigned error_lsb);
        if (error_lsb == 0)
            return ERROR_EXACT;
        if (error_lsb <= 4)
            return ERROR_1_TO_4;
        if (error_lsb <= 16)
            return ERROR_5_TO_16;
        if (error_lsb <= 32)
            return ERROR_17_TO_32;
        if (error_lsb <= TOLERANCE_LSB)
            return ERROR_33_TO_LIMIT;
        return ERROR_OUTSIDE_LIMIT;
    endfunction

    function void write_softmax_expected(softmax_transaction tr);
        softmax_transaction copy_tr;
        $cast(copy_tr, tr.clone());
        expected_queue.push_back(copy_tr);
        expected_received++;
        compare_available();
    endfunction

    function void write_softmax_actual(softmax_transaction tr);
        softmax_transaction copy_tr;
        $cast(copy_tr, tr.clone());
        actual_queue.push_back(copy_tr);
        actual_received++;
        compare_available();
    endfunction

    function void compare_available();
        softmax_transaction expected_tr;
        softmax_transaction actual_tr;
        longint unsigned expected_value;
        longint unsigned actual_value;
        longint unsigned difference;
        longint unsigned transaction_maximum_error;
        bit transaction_pass;

        while ((expected_queue.size() != 0) &&
               (actual_queue.size() != 0)) begin
            expected_tr = expected_queue.pop_front();
            actual_tr = actual_queue.pop_front();
            compared_count++;
            transaction_pass = 1'b1;
            transaction_maximum_error = 0;

            if ($isunknown(actual_tr.softmax_array_out)) begin
                transaction_pass = 1'b0;
                lane_mismatch_count += NUM_ELEMENTS;
                `uvm_error(
                    "SOFTMAX_X",
                    $sformatf(
                        "Transaction %0d output contains X or Z: 0x%0h",
                        compared_count,
                        actual_tr.softmax_array_out
                    )
                )
            end
            else begin
                for (int lane = 0; lane < NUM_ELEMENTS; lane++) begin
                    expected_value = expected_tr.softmax_array_out[
                        lane*DATA_WIDTH +: DATA_WIDTH
                    ];
                    actual_value = actual_tr.softmax_array_out[
                        lane*DATA_WIDTH +: DATA_WIDTH
                    ];

                    if (actual_value >= expected_value)
                        difference = actual_value - expected_value;
                    else
                        difference = expected_value - actual_value;

                    lane_error_cg.sample(lane, classify_error(difference));

                    if (difference > transaction_maximum_error)
                        transaction_maximum_error = difference;
                    if (difference > maximum_observed_error)
                        maximum_observed_error = difference;

                    if (difference > TOLERANCE_LSB) begin
                        transaction_pass = 1'b0;
                        lane_mismatch_count++;
                        `uvm_error(
                            "SOFTMAX_MISMATCH",
                            $sformatf(
                                {"transaction=%0d lane=%0d expected=%0d ",
                                 "actual=%0d error=%0d LSB tolerance=%0d LSB"},
                                compared_count,
                                lane,
                                expected_value,
                                actual_value,
                                difference,
                                TOLERANCE_LSB
                            )
                        )
                    end
                end
                transaction_error_cg.sample(
                    classify_error(transaction_maximum_error)
                );
            end

            if (transaction_pass)
                passed_count++;
            else
                failed_count++;
        end
    endfunction

    function void flush_on_reset();
        reset_dropped_expected += expected_queue.size();
        reset_dropped_actual += actual_queue.size();
        expected_queue.delete();
        actual_queue.delete();
        reset_flush_count++;
    endfunction

    task run_phase(uvm_phase phase);
        forever begin
            @(negedge vif.rst_n);
            flush_on_reset();
        end
    endtask

    function void report_phase(uvm_phase phase);
        super.report_phase(phase);

        if (expected_queue.size() != 0)
            `uvm_error("MISSING_OUTPUT", $sformatf(
                "%0d expected results remain", expected_queue.size()))
        if (actual_queue.size() != 0)
            `uvm_error("EXTRA_OUTPUT", $sformatf(
                "%0d actual results remain", actual_queue.size()))

        `uvm_info(
            "SOFTMAX_SUMMARY",
            $sformatf(
                {"expected=%0d actual=%0d compared=%0d passed=%0d ",
                 "failed=%0d lane_mismatches=%0d maximum_error=%0d LSB ",
                 "reset_flushes=%0d dropped_expected=%0d dropped_actual=%0d ",
                 "lane_error_cov=%0.2f%% transaction_error_cov=%0.2f%%"},
                expected_received,
                actual_received,
                compared_count,
                passed_count,
                failed_count,
                lane_mismatch_count,
                maximum_observed_error,
                reset_flush_count,
                reset_dropped_expected,
                reset_dropped_actual,
                lane_error_cg.get_inst_coverage(),
                transaction_error_cg.get_inst_coverage()
            ),
            UVM_LOW
        )
    endfunction

endclass

`endif
