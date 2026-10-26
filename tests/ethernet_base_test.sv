class ethernet_base_test extends uvm_test;
`uvm_component_utils(ethernet_base_test)
  config_object tx_cfg, rx_cfg;
  environment env;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

function void build_phase(uvm_phase phase);
  super.build_phase(phase);

  tx_cfg = config_object::type_id::create("tx_cfg");
  tx_cfg.active_passive = UVM_ACTIVE;
  tx_cfg.tx_rx_mode = TX;
  uvm_config_db#(config_object)::set(this, "env.eth_tx_agent*", "cfg", tx_cfg);

  rx_cfg = config_object::type_id::create("rx_cfg");
  rx_cfg.active_passive = UVM_PASSIVE;
  rx_cfg.tx_rx_mode = RX;
  uvm_config_db#(config_object)::set(this, "env.eth_rx_agent*", "cfg", rx_cfg);

  env = environment::type_id::create("env", this);
  uvm_config_db#(config_object)::set(null,"*","config_object",tx_cfg);
  endfunction

  task run_phase(uvm_phase phase);
      `uvm_info(get_name(), "----------BASE TEST RUN PHASE---------", UVM_NONE)
      endtask
      endclass

