class seq_item extends uvm_sequence_item;

  // TX side
   rand bit pkt_tx_val;
   bit pkt_tx_sop;
   bit pkt_tx_eop;
   bit [2:0] pkt_tx_mod;
   rand bit [63:0] pkt_tx_data[$];  // it is the actual signal driving to dut
   bit pkt_tx_full;

  // RX side
  bit pkt_rx_val;
  bit pkt_rx_sop;
  bit pkt_rx_eop;
  bit [2:0] pkt_rx_mod;
  bit pkt_rx_err;
  bit [63:0] pkt_rx_data[$];
  bit pkt_rx_avail;
  rand bit pkt_rx_ren;


    int sop_count_tx; 
    int sop_count_rx;
    int eop_count_tx;
    int eop_count_rx;

  // Ethernet Frame Fields
  bit [55:0] preamble;       // 7 bytes
  bit [7:0]  sfd;            // 1 byte
  rand bit [47:0] mac_dst_addr;   // 6 bytes
  rand bit [47:0] mac_src_addr;   // 6 bytes
  rand bit [15:0] ether_type;     // 2 bytes
  rand bit [7:0] payload[];      // Random data is generated here like how many packets of data has to be uploaded to pkt and appended into pkt_tx_data
// lets say it radomized like 20 , then 20 packets of data is generated and sent to pkt_tx_data.
    `uvm_object_utils_begin(seq_item)
    `uvm_field_int(pkt_tx_val, UVM_ALL_ON)
    `uvm_field_int(pkt_tx_sop, UVM_ALL_ON)
    `uvm_field_int(pkt_tx_eop, UVM_ALL_ON)
    `uvm_field_int(pkt_tx_mod, UVM_ALL_ON)
    `uvm_field_queue_int(pkt_tx_data, UVM_ALL_ON)
    `uvm_field_int(pkt_rx_ren, UVM_ALL_ON)
    `uvm_field_int(preamble, UVM_ALL_ON)
    `uvm_field_int(sfd, UVM_ALL_ON)
    `uvm_field_int(mac_dst_addr, UVM_ALL_ON)
    `uvm_field_int(mac_src_addr, UVM_ALL_ON)
    `uvm_field_int(ether_type, UVM_ALL_ON)
    `uvm_field_array_int(payload, UVM_ALL_ON)
    `uvm_field_int(eop_count_tx,UVM_ALL_ON)
    `uvm_field_int(eop_count_rx,UVM_ALL_ON)
    `uvm_field_int(sop_count_tx,UVM_ALL_ON)
    `uvm_field_int(sop_count_rx,UVM_ALL_ON)

  `uvm_object_utils_end

  function new(string name = "seq_item");
    super.new(name);
  endfunction
//constraint size_c {pkt_tx_data.size() inside {[1:64]};}
  

  // Distributive constraint for MAC addresses
  constraint mac_addr_distribution {
    mac_src_addr dist {
      [48'h0000_0000_0000 : 48'h1FFF_FFFF_FFFF] :/ 30,
      [48'h2000_0000_0000 : 48'h7FFF_FFFF_FFFF] :/ 50,
      [48'h8000_0000_0000 : 48'hEFFF_FFFF_FFFF] :/ 15,
      [48'hF000_0000_0000 : 48'hFFFF_FFFF_FFFF] :/ 5
    };
    mac_dst_addr dist {
      [48'h0000_0000_0000 : 48'h1FFF_FFFF_FFFF] :/ 30,
      [48'h2000_0000_0000 : 48'h7FFF_FFFF_FFFF] :/ 50,
      [48'h8000_0000_0000 : 48'hEFFF_FFFF_FFFF] :/ 15,
      [48'hF000_0000_0000 : 48'hFFFF_FFFF_FFFF] :/ 5
    };
  }


  constraint payload_con{soft payload.size() inside {[46:1518]};}  // here we used soft for it , because we will controlling it from test for testcases

endclass

