
class ether_sequence extends uvm_sequence #(seq_item);
  `uvm_object_utils(ether_sequence)
`uvm_declare_p_sequencer(sequencer)


  int random_delay;

  function new(string name = "ether_sequence");
    super.new(name);
  endfunction

  virtual task body();
          bit [63:0] word;
      bit [63:0] temp_payload;

    if (p_sequencer.cfg.frame_data == 0) begin
      if (!p_sequencer.cfg.randomize()) begin
        `uvm_error(get_type_name(), "Randomization failed for config_object")
      end
      `uvm_info(get_type_name(), $sformatf("Randomized p_sequencer.cfg.frame_data = %0d", p_sequencer.cfg.frame_data), UVM_LOW)
    end else begin
      `uvm_info(get_type_name(), $sformatf("Using p_sequencer.cfg.frame_data overridden in TEST = %0d", p_sequencer.cfg.frame_data), UVM_LOW)
    end

  //  repeat (10)
  //  begin

      req = seq_item::type_id::create("req");
      start_item(req);

      if (!req.randomize()) begin
        `uvm_error("ETHER_SEQUENCE", "Randomization failed for seq_item")
      end

      // Ethernet header fields
      req.preamble     = p_sequencer.cfg.preamble_cfg;  //passing from p_sequencer.cfg
      req.sfd          = p_sequencer.cfg.sfd_cfg;       //passing from p_sequencer.cfg
      req.ether_type   = p_sequencer.cfg.frame_data;

      req.payload = new[p_sequencer.cfg.frame_data];
      for (int i = 0; i < p_sequencer.cfg.frame_data; i++) begin
        req.payload[i] = i;
        `uvm_info("get_name()", $sformatf("req.payload[%0d]=%0d", i, req.payload[i]), UVM_MEDIUM);
      end

      req.pkt_tx_data = {};
      req.pkt_tx_data.push_back({req.preamble, req.sfd});
      word = {req.mac_dst_addr, req.mac_src_addr[47:32]};
      req.pkt_tx_data.push_back(word);
    //  word = {req.mac_src_addr[31:0], req.ether_type, 16'h0000};
    //  req.pkt_tx_data.push_back(word);
    if (req.payload.size() >= 2) begin
    word = {req.mac_src_addr[31:0], req.ether_type, 
            req.payload[0], req.payload[1]};
    end else if (req.payload.size() == 1) begin
    word = {req.mac_src_addr[31:0],req.ether_type, 
            req.payload[0], 8'h00};
    end else begin
    word = {req.mac_src_addr[31:0],req.ether_type, 16'h0000};
    end
    req.pkt_tx_data.push_back(word);
      for (int i = 2; i < req.payload.size(); i += 8) begin
        temp_payload = 64'd0;

          if (i+0 < req.payload.size()) temp_payload[63:56]   = req.payload[i+0];
        if (i+1 < req.payload.size()) temp_payload[55:48]  = req.payload[i+1];
        if (i+2 < req.payload.size()) temp_payload[47:40] = req.payload[i+2];
        if (i+3 < req.payload.size()) temp_payload[39:32] = req.payload[i+3];
        if (i+4 < req.payload.size()) temp_payload[31:24] = req.payload[i+4];
        if (i+5 < req.payload.size()) temp_payload[23:16] = req.payload[i+5];
        if (i+6 < req.payload.size()) temp_payload[15:8] = req.payload[i+6];
        if (i+7 < req.payload.size()) temp_payload[7:0] = req.payload[i+7];



        req.pkt_tx_data.push_back(temp_payload);
        `uvm_info(get_type_name(), $sformatf("sequence_transmission: temp_payload=%0h", temp_payload), UVM_MEDIUM);
      end

      `uvm_info("get_name()", $sformatf("req.pkt_tx_data=%0p", req.pkt_tx_data), UVM_MEDIUM);

      // Control flags
      req.pkt_tx_sop  = 1;
      req.pkt_tx_eop  = 1;
      req.pkt_tx_val  = 1;
     // req.pkt_tx_full = 0;
     // req.pkt_rx_ren  = 1;

      finish_item(req);
      random_delay = $urandom_range(20,40);
      `uvm_info(get_type_name(),$sformatf("randomization of delay=%0d",random_delay),UVM_MEDIUM);
      #random_delay;
    //end
  endtask
endclass








