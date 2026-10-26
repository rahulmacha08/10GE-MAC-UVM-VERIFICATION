class subscriber extends uvm_subscriber#(seq_item);
   `uvm_component_utils(subscriber)
     
 localparam int D = 8;

 logic pkt_tx_val;
 logic pkt_tx_sop;
 logic pkt_tx_eop;
 logic [2:0] pkt_tx_mod;

 bit [55:0] preamble;
 bit [7:0]  sfd;
 bit [47:0] mac_dst_addr;
 bit [47:0] mac_src_addr;
 bit [15:0] ether_type;
 bit [7:0] payload[];
   
    covergroup tx_cg1;
	   coverpoint pkt_tx_val { bins valid = {[1:0]};}
	   coverpoint pkt_tx_sop { bins sop = {[1:0]};}
	   coverpoint pkt_tx_eop { bins eop = {[1:0]};}
	   coverpoint pkt_tx_mod { bins mod = {[0:(D-1)]};}
	endgroup

	 covergroup eth_frame_cg;
	    
		 coverpoint preamble{  
		 bins standard = {56'h55555555555555};
		 bins invalid = default;
		 }

		 coverpoint sfd{
		  bins standard = {8'hD5};
		  bins invalid = default;
		  }

		 coverpoint mac_dst_addr{
		  bins dst_small = {[48'h0000_0000_0000 : 48'h5555_5555_5554]};
		  bins dst_medium = {[48'h5555_5555_5555 : 48'hAAAA_AAAA_AAAA]};
		  bins dst_big = {[48'hAAAA_AAAA_AAAB : 48'hFFFF_FFFF_FFFF]}; }

		  coverpoint mac_src_addr{
		  bins src_small = {[48'h0000_0000_0000 : 48'h5555_5555_5554]};
		  bins src_medium = {[48'h5555_5555_5555 : 48'hAAAA_AAAA_AAAA]};
		  bins src_big = {[48'hAAAA_AAAA_AAAB : 48'hFFFF_FFFF_FFFF]}; }

		  coverpoint ether_type {
		  bins length_small = {[16'h0000 : 16'h002D]};  // PAYLOAD size 0 - 45 bytes 
		  bins length_normal = {[16'h002E : 16'h05DC]}; // 46 - 1500 bytes 
		  bins length_jumbo = {[16'h05DD : 16'h2328]};}  //1501 - 9000 bytes
          
		  coverpoint payload.size() {
		   bins runt = {[0:45]};
		   bins normal ={[46:1500]};
		   bins jumbo = {[1501:9000]};
		   illegal_bins oversize = {[9001:$]};
		   }
	 endgroup

	 function new(string name = "subscriber",uvm_component parent = null);
	  super.new(name,parent);

	  tx_cg1 = new();
	  eth_frame_cg = new();
	  endfunction

	  function void write(seq_item t);
	  logic [15:0] zero_pad;

	  //DIRECTLY acces first 3 words from pkt_tx_data

	  preamble = t.pkt_tx_data[0][63:8];
	  sfd      = t.pkt_tx_data[0][7:0];

	  mac_dst_addr          = t.pkt_tx_data[1][63:16];
	  mac_src_addr[47:32]   = t.pkt_tx_data[1][15:0];
      
	  mac_src_addr[31:0]    = t.pkt_tx_data[2][63:32];
	  ether_type            = t.pkt_tx_data[2][32:16];
     //zero_pad = t.pkt_tx_data[2][15:0];

	 //transaction signals
	 pkt_tx_val = t.pkt_tx_val;
	 pkt_tx_sop = t.pkt_tx_sop;
	 pkt_tx_eop = t.pkt_tx_eop;
	 pkt_tx_mod = t.pkt_tx_mod;
	 
	 //payload data 
	 payload = t.payload;

	 //sample covergroups
	 tx_cg1.sample();
	 eth_frame_cg.sample();
	  
	  endfunction
endclass
