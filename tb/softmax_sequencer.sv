`ifndef SOFTMAX_SEQUENCER_SV
`define SOFTMAX_SEQUENCER_SV

class softmax_sequencer extends uvm_sequencer #(softmax_transaction);
   
   function new(string name, uvm_component parent);
      super.new(name, parent);
   endfunction 
   
   `uvm_component_utils(softmax_sequencer)
endclass

`endif