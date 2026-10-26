class ethernet_agent extends uvm_agent;

 `uvm_component_utils(ethernet_agent)
    sequencer sqr;
	driver drv;
	ethernet_monitor eth_mon;
	config_object cfg;

	function new(string name, uvm_component parent);
	super.new(name,parent);
	endfunction
	 
	  function void build_phase(uvm_phase phase);
	   if(!uvm_config_db#(config_object)::get(this,"","cfg",cfg))
	   `uvm_fatal("ethernet_agent","not able to get the agent config in AGENT")
  // here if this agent is selected then only the memeory creation for all the components in the agents happens.
	   if(cfg.active_passive == UVM_ACTIVE) begin 
			  sqr = sequencer :: type_id :: create("sqr",this);
	          drv =  driver :: type_id :: create("drv",this);
	          eth_mon  = ethernet_monitor :: type_id :: create("eth_mon",this);
			 end 
		else begin 
		      eth_mon = ethernet_monitor :: type_id :: create("eth_mon",this);
			  end 
	  endfunction
	   
	  function void connect_phase(uvm_phase phase);
	    if(cfg.active_passive == UVM_ACTIVE) begin
		  drv.seq_item_port.connect(sqr.seq_item_export);
		end 
	  endfunction

endclass
