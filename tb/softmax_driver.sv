`ifndef SOFTMAX_DRIVER_SV
`define SOFTMAX_DRIVER_SV

class softmax_driver extends uvm_driver #(softmax_transaction);

	`uvm_component_utils(softmax_driver)
	
	virtual softmax_if #(DATA_WIDTH,FRACTIONAL_BITS,NUM_ELEMENTS) vif;
	
	function new(string name = "softmax_driver", uvm_component parent = null);
		super.new(name, parent);
	endfunction
	
	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		if(!uvm_config_db#(virtual softmax_if#(DATA_WIDTH,FRACTIONAL_BITS,NUM_ELEMENTS))::get(this, "", "vif", vif)) begin
			`uvm_fatal("NOVIF", "virtual interface must be set for driver")
		end
	endfunction
	
	task drive_idle();
		vif.drv_cb.array_valid  <= 1'b0;
		vif.drv_cb.array_in 	<= '{default:'0};
	endtask
	
    task drive_normal_item(softmax_transaction tr);
    	logic [(NUM_ELEMENTS*DATA_WIDTH)-1:0] packed_data;
    	
    	packed_data = '0;
    	
    	foreach (tr.data_in[i]) begin
            packed_data[i*DATA_WIDTH +: DATA_WIDTH] = tr.data_in[i];
        end

        vif.drv_cb.array_valid  <= 1'b1;
        vif.drv_cb.array_in 	<= packed_data;
    endtask	
    
    task apply_reset(int unsigned requested_cycles);
        int unsigned actual_cycles;
        actual_cycles = (requested_cycles == 0) ? 1 : requested_cycles;

        vif.drv_cb.rst_n <= 1'b0;
        drive_idle();

        repeat (actual_cycles) begin
            @(vif.drv_cb);

        end

        vif.drv_cb.rst_n <= 1'b1;
        drive_idle();
    endtask
    
    task reset_dut();
        `uvm_info("DRV", "Start initial reset", UVM_LOW)
        @(vif.drv_cb);
        apply_reset(3);
        `uvm_info("DRV", "Initial reset finished", UVM_LOW)
    endtask

	task run_phase(uvm_phase phase);
		softmax_transaction req;
		
		reset_dut();

		forever begin
			@(vif.drv_cb);
			
			req = null;
			seq_item_port.try_next_item(req);
			
			if(req == null) begin
				drive_idle();
			end
			else begin
				case(req.op)
					op_normal: begin
						drive_normal_item(req);
						seq_item_port.item_done();
					end
					
					op_idle: begin
						drive_idle();
						seq_item_port.item_done();
					end
					
					op_reset: begin
						apply_reset(req.reset_cycles);
						seq_item_port.item_done();
					end
					
					default: begin
						`uvm_error("OP_UNDEFINED", $sformatf("error op value: %0d", req.op))
						drive_idle();
						seq_item_port.item_done();
					end
				endcase
			end
		end
	endtask
	
endclass
`endif