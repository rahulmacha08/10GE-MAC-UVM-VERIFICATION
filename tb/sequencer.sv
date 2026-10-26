class sequencer extends uvm_sequencer#(seq_item);
	`uvm_component_utils(sequencer)
	config_object cfg;

	function new(string name, uvm_component parent);
		super.new(name,parent);
	endfunction

	virtual function void build_phase(uvm_phase phase);
		super.build_phase(phase);

		if(!uvm_config_db#(config_object)::get(this,"","cfg",cfg))
			`uvm_error(get_type_name,"Not able to get config in the sequencer")
			`uvm_info(get_name(),"--------SEQUENCER BUILD PHASE--------",UVM_NONE)
	endfunction
endclass
