
 `uvm_analysis_imp_decl(_tx_monitor)
 `uvm_analysis_imp_decl(_rx_monitor)

class scoreboard extends uvm_scoreboard;
  
  `uvm_component_utils(scoreboard)
   
   seq_item ref_data;
   seq_item dut_data;
   
   config_object cfg;

   int total_rx_size;  // here it is just to keep the size of the packets.

   virtual ether_interface intf;

   uvm_analysis_imp_tx_monitor#(seq_item,scoreboard) ethernet_tx_scbd_ap;
   uvm_analysis_imp_rx_monitor#(seq_item,scoreboard) ethernet_rx_scbd_ap;

   seq_item tx_q[$];
   seq_item rx_q[$];

   function new(string name, uvm_component parent);
   super.new(name,parent);
   endfunction

   virtual function void build_phase(uvm_phase phase);
   super.build_phase(phase);
   ref_data = new();
   dut_data = new();
   ethernet_tx_scbd_ap = new("ethernet_tx_scbd_ap",this);
   ethernet_rx_scbd_ap = new("ethernet_rx_scbd_ap",this);
   cfg  = config_object :: type_id :: create("cfg");
   void'(uvm_config_db#(config_object)::get(this,"","config_object",cfg));

   if(!uvm_config_db#(virtual ether_interface)::get(this,"","intf",intf))begin
   `uvm_error(get_type_name(),"failed to get interface in scoreboard")
   end
   endfunction   

   task write_tx_monitor(seq_item tx_data);
    tx_q.push_back(tx_data);
   endtask

   task write_rx_monitor(seq_item rx_data);
     rx_q.push_back(rx_data);
	    
		if(intf.rst ==0) begin
	     tx_q.delete();
		 rx_q.delete();
		 `uvm_info(get_type_name(),"RESET DETECTED - scoreboard queues cleared",UVM_LOW)
		 return;
	    end

		if(rx_data.pkt_rx_err)begin 
		  cfg.disable_compare = 1;
		  `uvm_error(get_type_name(),"ERROR FRAME DETECTED")
		end 

		total_rx_size = rx_data.pkt_rx_data.size() * 8;
        
		if(total_rx_size < 65)begin
		   `uvm_error(get_type_name(),$sformatf("RUNT FRAME DETECTED"))
		   cfg.disable_compare = 1; end

		else if(total_rx_size >1520) begin
		`uvm_warning(get_name(),$sformatf("OVERSIZED FRAME : total_rx_size = %0d > 1518 bytes",total_rx_size)) end

		else begin
		 `uvm_info(get_name(),$sformatf("VALID FRAME : total_rx_size = %0d bytes",total_rx_size),UVM_LOW) end 

		for (int i =0; i < total_rx_size ; i++)begin 
            if (tx_q.size() > 0 && rx_q.size() > 0) begin
			  ref_data = tx_q.pop_front();
			  dut_data = rx_q.pop_front();

			  if(ref_data.pkt_tx_data.size() ==0)begin
			  `uvm_error(get_name(),"tx data is empty")
			end
		end

             if(!cfg.disable_compare && (dut_data.pkt_rx_data[i] == ref_data.pkt_tx_data[i]))begin
			    `uvm_info(get_name(),$sformatf("ref_data.pkt_tx_data = %0p , dut_data.pkt_rx_data=%0p",
				 ref_data.pkt_tx_data ,dut_data.pkt_rx_data), UVM_MEDIUM)
				 `uvm_info(get_name(),"<------------TEST PASSED--------->",UVM_LOW)
			 end
			 else begin 
			      `uvm_info(get_name(),$sformatf("ref_data.pkt_tx_data = %0p , dut_data.pkt_rx_data=%0p",
				 ref_data.pkt_tx_data ,dut_data.pkt_rx_data), UVM_MEDIUM)
				 `uvm_info(get_name(),"<------------TEST FAILED--------->",UVM_LOW)
			 end
		end 
   endtask
endclass
