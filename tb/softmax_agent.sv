`ifndef SOFTMAX_AGENT_SV
`define SOFTMAX_AGENT_SV

class softmax_agent extends uvm_agent;

    `uvm_component_utils(softmax_agent)

    softmax_sequencer sequencer;
    softmax_driver driver;
    softmax_input_monitor input_monitor;
    softmax_output_monitor output_monitor;

    uvm_analysis_port #(softmax_transaction) input_ap;
    uvm_analysis_port #(softmax_transaction) output_ap;

    function new(
        string name = "softmax_agent",
        uvm_component parent = null
    );
        super.new(name, parent);
        input_ap = new("input_ap", this);
        output_ap = new("output_ap", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        input_monitor = softmax_input_monitor::type_id::create(
            "input_monitor", this
        );
        output_monitor = softmax_output_monitor::type_id::create(
            "output_monitor", this
        );

        if (get_is_active() == UVM_ACTIVE) begin
            sequencer = softmax_sequencer::type_id::create(
                "sequencer", this
            );
            driver = softmax_driver::type_id::create("driver", this);
        end
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        input_monitor.ap.connect(input_ap);
        output_monitor.oap.connect(output_ap);

        if (get_is_active() == UVM_ACTIVE)
            driver.seq_item_port.connect(sequencer.seq_item_export);
    endfunction

endclass

`endif
