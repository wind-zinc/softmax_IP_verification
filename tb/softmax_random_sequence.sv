`ifndef SOFTMAX_RANDOM_SEQUENCE_SV
`define SOFTMAX_RANDOM_SEQUENCE_SV

class softmax_random_sequence extends uvm_sequence #(softmax_transaction);

	`uvm_object_utils(softmax_random_sequence)
	
	function new(string name = "softmax_random_sequence");
		super.new(name);
	endfunction
	
	task body();
		
		softmax_transaction req;
		
		repeat (60) begin
			
			req = softmax_transaction::type_id::create("req");
			
			start_item(req);
			
			if(!req.randomize() with {
				foreach (data_in[i])
					data_in[i] inside {
						[SOFTMAX_INPUT_MIN:SOFTMAX_INPUT_MAX]
					};
			}) begin
				`uvm_fatal("RAND_FAIL", "tr randomize failed")
			end
			
			finish_item(req);
			
		end
		
	endtask
	
endclass

`endif