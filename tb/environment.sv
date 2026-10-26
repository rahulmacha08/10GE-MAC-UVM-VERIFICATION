//`include "subscriber.sv"

class environment extends uvm_env;

  `uvm_component_utils(environment)

 virtual ether_interface intf;
  ethernet_agent eth_tx_agent,eth_rx_agent;
  scoreboard scbd;
  subscriber sbscr;
  config_object config_scr_cov;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction 


  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    config_scr_cov=config_object::type_id::create("config_scr_cov");
        if (!uvm_config_db#(virtual ether_interface)::get(this, "", "intf", intf)) begin
      `uvm_error(get_type_name(), "Failed to get interface")
    end
    `uvm_info(get_type_name(), " build phase completed", UVM_LOW)

    eth_tx_agent = ethernet_agent::type_id::create("eth_tx_agent", this);
    eth_rx_agent = ethernet_agent::type_id::create("eth_rx_agent", this);

 //       config_scr_cov.has_scoreboard=1'b1;
//	config_scr_cov.has_functional_coverage=1'b1;
if(config_scr_cov.has_scoreboard==1'b1)
    scbd  = scoreboard::type_id::create("scbd", this);
    if(config_scr_cov.has_functional_coverage==1'b1)
    sbscr = subscriber::type_id::create("sbscr", this);

    `uvm_info("environment", "message in build_phase", UVM_LOW)
  endfunction 

function void connect_phase(uvm_phase phase);
if(config_scr_cov.has_scoreboard==1'b1)
   eth_tx_agent.eth_mon.ethernet_tx_mon_ap.connect(scbd.ethernet_tx_scbd_ap);
  `uvm_info("environment", "monitor1 connect with scoreboard", UVM_LOW)
  if(config_scr_cov.has_scoreboard==1'b1)

  eth_rx_agent.eth_mon.ethernet_rx_mon_ap.connect(scbd.ethernet_rx_scbd_ap);
  `uvm_info("environment", "monitor2 connect with scoreboard", UVM_LOW)

  if(config_scr_cov.has_functional_coverage==1'b1)

  eth_tx_agent.eth_mon.ethernet_tx_mon_ap.connect(sbscr.analysis_export);
  `uvm_info("environment", "monitor1 connect with subscriber", UVM_LOW)
endfunction 
 
  function void end_of_elaboration_phase(uvm_phase phase);
    `uvm_info("environment", "message in end_of_elaboration_phase", UVM_LOW)
    uvm_top.print_topology();
  endfunction 

endclass
