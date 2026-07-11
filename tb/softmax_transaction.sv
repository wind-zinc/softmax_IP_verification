`ifndef SOFTMAX_TRANSACTION_SV
`define SOFTMAX_TRANSACTION_SV

typedef enum bit [1:0] {
		op_normal = 2'b00,
		op_idle   = 2'b01,
		op_reset  = 2'b10
} softmax_op;

class softmax_transaction extends uvm_sequence_item;

	rand logic signed [DATA_WIDTH-1:0] data_in [NUM_ELEMENTS];
	
	softmax_op op;
	logic 								  rst_n; // for monitor
	int unsigned 						  reset_cycles;
	logic [(NUM_ELEMENTS*DATA_WIDTH)-1:0] softmax_array_out;
	
	`uvm_object_utils_begin(softmax_transaction)
		`uvm_field_sarray_int(data_in, 		UVM_ALL_ON)
		`uvm_field_enum(softmax_op, op, 	UVM_ALL_ON)
		`uvm_field_int(rst_n, 				UVM_ALL_ON)
		`uvm_field_int(softmax_array_out, 	UVM_ALL_ON)
		`uvm_field_int(reset_cycles,  		UVM_ALL_ON)
	`uvm_object_utils_end
	
	function new(string name = "softmax_transaction");
        super.new(name);
        op           = op_normal;
        reset_cycles = 3;
    endfunction
    
endclass

`endif
