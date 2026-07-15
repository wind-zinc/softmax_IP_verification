`ifndef SOFTMAX_STREAM_SEQUENCE_SV
`define SOFTMAX_STREAM_SEQUENCE_SV

class softmax_stream_sequence extends uvm_sequence #(softmax_transaction);

    `uvm_object_utils(softmax_stream_sequence)

    int unsigned item_id;

    function new(string name = "softmax_stream_sequence");
        super.new(name);
    endfunction

    task send_random_item(softmax_op operation);
        softmax_transaction req;

        req = softmax_transaction::type_id::create(
            $sformatf("stream_item_%0d", item_id++)
        );
        start_item(req);

        if (!req.randomize() with {
            foreach (data_in[i])
                data_in[i] inside {
                    [SOFTMAX_INPUT_MIN:SOFTMAX_INPUT_MAX]
                };
        }) begin
            `uvm_fatal("RAND_FAIL", "stream transaction failed")
        end

        req.op = operation;
        req.reset_cycles = 0;
        finish_item(req);
    endtask

    task send_burst(
        int unsigned burst_length,
        int unsigned gap_length
    );
        repeat (burst_length)
            send_random_item(op_normal);

        repeat (gap_length)
            send_random_item(op_idle);
    endtask

    task body();
        item_id = 0;

        send_burst(1, 1);
        send_burst(3, 2);
        send_burst(8, 5);
        send_burst(20, 1);

        repeat (4)
            send_burst(1, 1);
    endtask

endclass

`endif
