`ifndef SOFTMAX_OUTPUT_MONITOR_SV
`define SOFTMAX_OUTPUT_MONITOR_SV

class softmax_output_monitor extends uvm_monitor;

	`uvm_component_utils(softmax_output_monitor)
	
	virtual softmax_if #(
	DATA_WIDTH     ,
    FRACTIONAL_BITS, 
    NUM_ELEMENTS
	) vif;
	
	uvm_analysis_port #(softmax_transaction) oap;
	
	function new(
		string 		  name 	 = "softmax_output_monitor",
		uvm_component parent = null
	);
		super.new(name, parent);
	endfunction
	
	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		
		if(!uvm_config_db#(virtual softmax_if#(DATA_WIDTH, FRACTIONAL_BITS, NUM_ELEMENTS))::get(
		this,
		"",
		"vif",
		vif
		)) begin
			`uvm_fatal("NOVIF","vif must be set for output_monitor")
		end
		
		oap = new("oap", this);
	endfunction
	
	function void sample(softmax_transaction tr);
	
		tr.softmax_array_out = vif.mon_cb.softmax_array_out;
		
	endfunction
	
	task run_phase(uvm_phase phase);
	
		softmax_transaction tr;
		
		forever begin
			
			@(vif.mon_cb);
			
			if(vif.mon_cb.softmax_valid === 1'b1 && vif.mon_cb.rst_n === 1'b1) begin
			
				tr = softmax_transaction::type_id::create("tr");	
				
				sample(tr);
				
				oap.write(tr);
				
			end
			
		end
		
	endtask
	
endclass
			
`endif
