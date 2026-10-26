class ethernet_monitor extends uvm_monitor;
  `uvm_component_utils(ethernet_monitor)

  bit packet_error;
  uvm_analysis_port#(seq_item) ethernet_tx_mon_ap;
  uvm_analysis_port#(seq_item) ethernet_rx_mon_ap;

  bit[31:0] qsize;

  virtual ether_interface intf;
  seq_item tx_req, rx_req;
  config_object cfg;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction


  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    ethernet_tx_mon_ap = new("ethernet_tx_mon_ap", this);
    ethernet_rx_mon_ap = new("ethernet_rx_mon_ap", this);

    if (!uvm_config_db#(virtual ether_interface.mont)::get(this, "", "intf", intf)) begin
      `uvm_error(get_type_name(), "Failed to get interface")
    end
    `uvm_info(get_full_name(), "Monitor build phase completed", UVM_MEDIUM)

    if (!uvm_config_db#(config_object)::get(this, "", "cfg", cfg))
      `uvm_error(get_type_name(), "Not able to get config in the monitor")

    `uvm_info(get_name(),"-----------MONITOR BUILD PHASE-----------",UVM_NONE)
  endfunction


  task tx_monitor();
    
    // @(posedge intf.clk);
    wait (intf.mon_cb.pkt_tx_val && intf.mon_cb.pkt_tx_sop);
    // Capture first word (SOP)
    tx_req.pkt_tx_data.push_back(intf.mon_cb.pkt_tx_data);
    tx_req.pkt_tx_val = intf.mon_cb.pkt_tx_val;
    tx_req.pkt_tx_sop = intf.mon_cb.pkt_tx_sop;
    if (intf.mon_cb.pkt_tx_sop)
      tx_req.sop_count_tx++;
    `uvm_info("MON_tx_sop_count", $sformatf("tx_monitor sop count=%0d", tx_req.sop_count_tx), UVM_NONE)

    
    // Collect rest of the packet until EOP
    do begin
      @(intf.mon_cb);
      if (intf.mon_cb.pkt_tx_val && !intf.mon_cb.pkt_tx_sop) begin
        tx_req.pkt_tx_data.push_back(intf.mon_cb.pkt_tx_data);
      end
    end while (!(intf.mon_cb.pkt_tx_val && intf.mon_cb.pkt_tx_eop));

    // Capture control signals
    tx_req.pkt_tx_mod = intf.mon_cb.pkt_tx_mod;
    tx_req.pkt_tx_eop = intf.mon_cb.pkt_tx_eop;
    if (intf.mon_cb.pkt_tx_eop)
      tx_req.eop_count_tx++;
    `uvm_info("MON_tx_eop_count", $sformatf("tx_monitor eop count=%0d", tx_req.eop_count_tx), UVM_NONE)


    // Send packet through analysis port
    ethernet_tx_mon_ap.write(tx_req);
    `uvm_info("MON_INTF_VALUE", $sformatf("VALUE OF EOP IN INTERFACE IS %d,%t", intf.pkt_tx_eop,$time), UVM_NONE)
    tx_req.print();
  //#5;
    `uvm_info("tx_monitor", $sformatf(
       " pkt_tx_val=%0d, sop=%0d, eop=%0d, mod=%0d, pkt_tx_data=%0p",
       tx_req.pkt_tx_val, tx_req.pkt_tx_sop, tx_req.pkt_tx_eop, tx_req.pkt_tx_mod, tx_req.pkt_tx_data
    ), UVM_MEDIUM);
  endtask
  
  task rx_monitor();
    // @(posedge intf.clk);
    if (intf.mon_cb.pkt_rx_val && intf.mon_cb.pkt_rx_sop) begin
       `uvm_info("MON_PKT_ENTRY", $sformatf("IN THE VALID BLOCK"), UVM_NONE)

       rx_req.pkt_tx_full = intf.mon_cb.pkt_tx_full;
       rx_req.pkt_rx_val  = intf.mon_cb.pkt_rx_val;
       if(intf.mon_cb.pkt_rx_val)
         intf.pkt_rx_ren=1;
       rx_req.pkt_rx_sop  = intf.mon_cb.pkt_rx_sop;
       if (intf.mon_cb.pkt_rx_sop)
         rx_req.sop_count_rx++;
       `uvm_info("MON_rx_sop_count", $sformatf("rx_monitor sop count=%0d", rx_req.sop_count_rx), UVM_NONE)

       rx_req.pkt_rx_eop   = intf.mon_cb.pkt_rx_eop;
       rx_req.pkt_rx_mod   = intf.mon_cb.pkt_rx_mod;
       rx_req.pkt_rx_err   = intf.mon_cb.pkt_rx_err;
       rx_req.pkt_rx_avail = intf.mon_cb.pkt_rx_avail;

       `uvm_info("MON_DATA_PKT", $sformatf("RX_MONITOR VALUE OF VALID id %d and sequence item valid is %d", intf.pkt_rx_val,rx_req.pkt_rx_val), UVM_NONE)
       rx_req.print();
       
    // packet_error = 0;
       
       if (intf.mon_cb.pkt_rx_err) begin
         packet_error = 1;
         rx_req.pkt_rx_err = intf.mon_cb.pkt_rx_err;
         `uvm_error(get_type_name(), "RX ERROR detected at SOP. Dropping frame.")
       end else begin
         rx_req.pkt_rx_data.push_back(intf.mon_cb.pkt_rx_data);
       end
       
       do begin
         @(intf.mon_cb);
         
         if (intf.mon_cb.pkt_rx_val) begin
           rx_req.pkt_rx_data.push_back(intf.mon_cb.pkt_rx_data);
           if (intf.mon_cb.pkt_rx_eop) begin
             rx_req.pkt_rx_eop = intf.mon_cb.pkt_rx_eop;
             break;
           end
         end
       end while (!intf.mon_cb.pkt_rx_eop);
       
       if (rx_req.pkt_rx_eop && !packet_error)
         rx_req.eop_count_rx++;
       `uvm_info("MON_rx_eop_count", $sformatf("rx_monitor eop count=%0d", rx_req.eop_count_rx), UVM_NONE)

       if (!packet_error) begin
         `uvm_info("MON_PKT_ERROR", $sformatf("RX_MONITOR sending to scoreboard: pkt_rx_err=%0d", rx_req.pkt_rx_err), UVM_LOW)
         ethernet_rx_mon_ap.write(rx_req);
         qsize = rx_req.pkt_rx_data.size();
         `uvm_info("MON_QUE_SIZE", $sformatf("RX_MONITOR NO OF ENTIRIES IN QUE %d", qsize), UVM_NONE)
         
         //rx_req.print();
         
         `uvm_info("rx_monitor",
                 $sformatf("rx_req.pkt_tx_full=%0d, rx_req.pkt_rx_val=%0d, rx_req.pkt_rx_sop=%0d, rx_req.pkt_rx_eop=%0d, rx_req.pkt_rx_mod=%0d, rx_req.pkt_rx_err=%0d, rx_req.pkt_rx_data=%0p, rx_req.pkt_rx_avail=%0d",
                 rx_req.pkt_tx_full, rx_req.pkt_rx_val, rx_req.pkt_rx_sop, rx_req.pkt_rx_eop,
                 rx_req.pkt_rx_mod, rx_req.pkt_rx_err, rx_req.pkt_rx_data, rx_req.pkt_rx_avail),
                 UVM_LOW)
       end
    end
  endtask
  
  task run_phase(uvm_phase phase);
    tx_req = seq_item::type_id::create("tx_req", this);
    rx_req = seq_item::type_id::create("rx_req", this);
    
    forever begin
      @(posedge intf.clk);
      
      if (intf.rst == 0) begin
        tx_req.pkt_tx_data.delete();
        rx_req.pkt_rx_data.delete();
        `uvm_info(get_type_name(), "Reset is LOW - cleared tx_req and rx_req queues", UVM_LOW);
      end
      else begin
        
        if (cfg.tx_rx_mode == TX)
          tx_monitor();
        if (cfg.tx_rx_mode == RX)
          rx_monitor();
      end
    end
  endtask

  function reset_monitor;
    tx_req.pkt_tx_data.delete();
    rx_req.pkt_rx_data.delete();
  endfunction

endclass
