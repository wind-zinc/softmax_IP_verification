`ifndef SOFTMAX_ENV_SV
`define SOFTMAX_ENV_SV

class softmax_env extends uvm_env;

    `uvm_component_utils(softmax_env)

    softmax_agent agent;
    softmax_reference_model ref_model;
    softmax_scoreboard scoreboard;
    softmax_coverage coverage;

    function new(
        string name = "softmax_env",
        uvm_component parent = null
    );
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        agent = softmax_agent::type_id::create("agent", this);
        ref_model = softmax_reference_model::type_id::create(
            "ref_model", this
        );
        scoreboard = softmax_scoreboard::type_id::create(
            "scoreboard", this
        );
        coverage = softmax_coverage::type_id::create("coverage", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        agent.input_ap.connect(ref_model.input_imp);
        agent.input_ap.connect(coverage.input_imp);
        ref_model.expected_ap.connect(scoreboard.expected_imp);
        agent.output_ap.connect(scoreboard.actual_imp);
        agent.output_ap.connect(coverage.output_imp);
    endfunction

endclass

`endif
