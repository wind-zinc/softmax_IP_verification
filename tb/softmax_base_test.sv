`ifndef SOFTMAX_BASE_TEST_SV
`define SOFTMAX_BASE_TEST_SV

class softmax_base_test extends uvm_test;

    `uvm_component_utils(softmax_base_test)

    softmax_env env;

    virtual softmax_if #(
        DATA_WIDTH,
        FRACTIONAL_BITS,
        NUM_ELEMENTS
    ) vif;

    function new(
        string name = "softmax_base_test",
        uvm_component parent = null
    );
        super.new(name, parent);
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
            `uvm_fatal("NOVIF", "vif must be set for softmax_base_test")
        end

        uvm_config_db#(uvm_active_passive_enum)::set(
            this,
            "env.agent",
            "is_active",
            UVM_ACTIVE
        );

        env = softmax_env::type_id::create("env", this);
    endfunction

    task wait_for_scoreboard_drain();
        int unsigned elapsed_cycles;
        int unsigned quiet_cycles;

        elapsed_cycles = 0;
        quiet_cycles = 0;

        while ((elapsed_cycles < TEST_TIMEOUT_CYCLES) &&
               (quiet_cycles < DRAIN_QUIET_CYCLES)) begin
            @(vif.mon_cb);
            elapsed_cycles++;

            if ((env.scoreboard.expected_queue.size() == 0) &&
                (env.scoreboard.actual_queue.size() == 0))
                quiet_cycles++;
            else
                quiet_cycles = 0;
        end

        if (quiet_cycles < DRAIN_QUIET_CYCLES) begin
            `uvm_fatal(
                "TEST_TIMEOUT",
                $sformatf(
                    {"scoreboard did not drain after %0d cycles: ",
                     "expected_queue=%0d actual_queue=%0d"},
                    elapsed_cycles,
                    env.scoreboard.expected_queue.size(),
                    env.scoreboard.actual_queue.size()
                )
            )
        end
    endtask

    task run_sequence(uvm_sequence #(softmax_transaction) sequence_h);
        sequence_h.start(env.agent.sequencer);
        wait_for_scoreboard_drain();
    endtask

endclass

`endif
