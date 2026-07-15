`ifndef SOFTMAX_STREAM_TEST_SV
`define SOFTMAX_STREAM_TEST_SV

class softmax_stream_test extends softmax_base_test;

    `uvm_component_utils(softmax_stream_test)

    function new(
        string name = "softmax_stream_test",
        uvm_component parent = null
    );
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        softmax_stream_sequence sequence_h;
        phase.raise_objection(this);
        sequence_h = softmax_stream_sequence::type_id::create("sequence_h");
        run_sequence(sequence_h);
        phase.drop_objection(this);
    endtask

endclass

`endif
