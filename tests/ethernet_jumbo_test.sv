class jumbo_test extends ethernet_base_test;
 
  `uvm_component_utils(test1)
     ether_sequence eth_seq;

	 function new(string name, uvm_component parent);
	 super.new(name,parent);
	 endfunction

	  task run_phase(uvm_phase phase);
	  eth_seq = ether_sequence ::type_id :: create("eth_seq");
	  tx_cfg.frame_typ = 1580;
	  phase.raise_objection(this);
	  repeat(1)begin
	 // tx_cfg.frame_data =0;  // its because if its zero then only it will randomize
	  eth_seq.start(env.eth_tx_agent.sqr);
	  end

	  `uvm_info("TEST_TX","TX is starting",UVM_LOW)

	  phase.drop_objection(this);
	  phase.phase_done.set_drain_time(this,1000);
	  `uvm_info(get_full_name(),"message from [TESTCASE][RUN phase] from uvm none",UVM_NONE)
	  endtask
endclass
