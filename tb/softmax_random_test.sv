`ifndef SOFTMAX_RANDOM_TEST_SV
`define SOFTMAX_RANDOM_TEST_SV

class softmax_random_test extends softmax_base_test;

    `uvm_component_utils(softmax_random_test)

    function new(
        string name = "softmax_random_test",
        uvm_component parent = null
    );
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        softmax_random_sequence sequence_h;
        phase.raise_objection(this);
        sequence_h = softmax_random_sequence::type_id::create("sequence_h");
        run_sequence(sequence_h);
        phase.drop_objection(this);
    endtask

endclass

`endif
