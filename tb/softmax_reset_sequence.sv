`ifndef SOFTMAX_RESET_SEQUENCE_SV
`define SOFTMAX_RESET_SEQUENCE_SV

class softmax_reset_sequence extends uvm_sequence #(softmax_transaction);

	`uvm_object_utils(softmax_reset_sequence)
	
	function new(string name = "softmax_reset_sequence");
		super.new(name);
	endfunction
	
	task send_tag();
		softmax_transaction req;
		req = softmax_transaction::type_id::create("tag_req");
		start_item(req);
		req.op 				 = op_normal;
		req.reset_cycles	 = 0;
		req.data_in 		 = '{default:32'sh0001_0000};
		finish_item(req);
	endtask
	
	task send_random_normal();
		softmax_transaction req;
		req = softmax_transaction::type_id::create("random_normal_req");
		start_item(req);
		req.op 				 = op_normal;
		req.reset_cycles	 = 0;
		
	    if (!req.randomize() with {
	        foreach (data_in[i])
	            data_in[i] inside {
	                [SOFTMAX_INPUT_MIN:SOFTMAX_INPUT_MAX]
	            };
	    }) begin
	        `uvm_fatal(
	            "RAND_FAIL",
	            "normal transaction randomize failed"
	        )
	    end
	    
		finish_item(req);
	endtask
	
	task send_reset(int unsigned reset_length);
		softmax_transaction req;
		req = softmax_transaction::type_id::create("reset_req");
		start_item(req);
		req.op 				 = op_reset;
		req.reset_cycles	 = reset_length;
		req.data_in 		 = '{default:'0};
		finish_item(req);
	endtask
	
	task body();
	
		repeat(16) begin
			send_random_normal();
		end
		
		send_reset(5);
		
		send_tag();
		
		repeat(16) begin
			send_random_normal();
		end
		
	endtask
	
endclass

`endif