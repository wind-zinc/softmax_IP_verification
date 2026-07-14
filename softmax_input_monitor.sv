`ifndef SOFTMAX_INPUT_MONITOR_SV
`define SOFTMAX_INPUT_MONITOR_SV

class softmax_input_monitor extends uvm_monitor;

	`uvm_component_utils(softmax_input_monitor)
	
	virtual softmax_if #(
	DATA_WIDTH     ,
    FRACTIONAL_BITS,
    NUM_ELEMENTS
	) vif;
	
	uvm_analysis_port #(softmax_transaction) ap;
	
	function new(
		string 		  name 	 = "softmax_input_monitor",
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
			`uvm_fatal("NOVIF","vif must be set for input_monitor")
		end
		
		ap = new("ap", this);
	endfunction
	
	function void sample(softmax_transaction tr);
	
		tr.rst_n = vif.mon_cb.rst_n;
		foreach (tr.data_in[i]) begin
			tr.data_in[i] = vif.mon_cb.array_in[i*DATA_WIDTH +: DATA_WIDTH];
		end
		
	endfunction
	
	task run_phase(uvm_phase phase);
	
		softmax_transaction tr;
		
		forever begin
			
			@(vif.mon_cb);
			
			if(vif.mon_cb.rst_n === 1'b1 && vif.mon_cb.array_valid === 1'b1) begin
			
				tr = softmax_transaction::type_id::create("tr");	
				
				sample(tr);
				
				ap.write(tr);
				
			end
			
		end
		
	endtask
	
endclass
			
`endif
