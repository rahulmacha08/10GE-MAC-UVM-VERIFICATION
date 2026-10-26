class driver extends uvm_driver#(seq_item);
`uvm_component_utils(driver)
 virtual ether_interface.drive intf;

  function new(string name, uvm_component parent);
   super.new(name,parent);
  endfunction

   virtual function void build_phase(uvm_phase phase);
   super.build_phase(phase);
   if(!uvm_config_db#(virtual ether_interface.drive)::get(this,"","intf",intf))begin 
   `uvm_error(get_type_name(),"failed to get interface")
   end
    `uvm_info(get_type_name(),"Driver build phase completed",UVM_LOW)
   endfunction

    virtual task run_phase(uvm_phase phase);
	super.run_phase(phase);
	 
	 @(intf.drv_cb);
	 repeat(10) @(intf.drv_cb);
            
		 forever begin 
		    seq_item_port.get_next_item(req);
            req.print();
			// BLOCK 1 : data driving logic and error detection. 
			 wait(!intf.drv_cb.pkt_tx_full);
			  
			 if(req.pkt_tx_val && !intf.drv_cb.pkt_tx_full) begin 
			      
				   int unsigned pkt_len_in_bytes; // to calculate the how many no.of packets of data is going.
				   int unsigned num_of_pkts;   // this is to increment the size of the packets , like to keep a count for our understanding
				   bit [2:0] last_bytes_mod; // it will have the no. of packets of data has there
				   bit [2:0] last_mod_to_send; // it will have the calucalted mod value.

				 pkt_len_in_bytes = 8 + 6 + 6 + 2 + req.payload.size();   // here we are appending the frame format until the payload size.
				 num_of_pkts      = pkt_len_in_bytes / 8; 
				 if(pkt_len_in_bytes %8 !=0)  
				   num_of_pkts++;
				 last_bytes_mod   =pkt_len_in_bytes %8;  // here we are giving this because we have to calucalte the mod value and will be stored here 
				 last_mod_to_send = (last_bytes_mod ==0) ? 3'd0 : last_bytes_mod; // here if the mod is zero then zero ,  else the value generated  in the prevoius line.

				  `uvm_info(get_type_name() ,$sformatf( 
				    "pkt_len_in_bytes = %0d ,num_of_pkts =%0d, last_bytes_mod = %0d ,last_mod_to_send=%0d",
					pkt_len_in_bytes ,num_of_pkts ,last_bytes_mod ,last_mod_to_send) ,UVM_MEDIUM)
                  // here comes the error condition it only enters this block when the if is true.
				 if(req.pkt_tx_data.size() < num_of_pkts) begin 
				    `uvm_error(get_type_name(), $sformatf("pkt_tx_data size =(%0d) < num_of_Pkts (%0d).aborting time",
					 req.pkt_tx_data.size(), num_of_pkts));
					 seq_item_port.item_done();
					 continue;
				 end 
                 //BLOCK2 : packet to pin conversion and control signals operation
				 for(int i=0; i<num_of_pkts; i++) begin 
				   @(intf.drv_cb);

				   intf.drv_cb.pkt_tx_data <= req.pkt_tx_data[i]; // each index value will be given to the interface signals 
				   intf.drv_cb.pkt_tx_sop <= (i==0) ? req.pkt_tx_sop : 1'b0; // here we are telling like if the index is at 0 then that is the start of the packet otherwise 0.
        // then it is for the eop caluculation
				   if(i == (num_of_pkts -1)) begin  
				        intf.drv_cb.pkt_tx_eop <= req.pkt_tx_eop;
                        intf.drv_cb.pkt_tx_mod <= last_mod_to_send;
				   end 
				   else begin 
				        intf.drv_cb.pkt_tx_eop <=1'b0;  // here we are deasserting the values to zero
						intf.drv_cb.pkt_tx_mod <=3'b0;
				   end 

				   intf.drv_cb.pkt_tx_val <= req.pkt_tx_val;
				   intf.drv_cb.pkt_rx_ren <= req.pkt_rx_ren;   // here it is the i am ready to recive signal
                    
					`uvm_info(get_type_name(), $sformatf(
					 "flit %0d/%0d:val =%0d ,sop=%0d, eop=%0d, mod=%0d ,data=0x%0p",i+1,num_of_pkts,
					  intf.drv_cb.pkt_tx_val,
					  intf.drv_cb.pkt_tx_sop,
					  intf.drv_cb.pkt_tx_eop,
					  intf.drv_cb.pkt_tx_mod,
					  intf.drv_cb.pkt_tx_data), UVM_MEDIUM);
                end 
				 // BLOCK 3. desserting the signals to zero
				 @(intf.drv_cb);
				 intf.drv_cb.pkt_tx_val <=0;
				 intf.drv_cb.pkt_tx_sop <=0;
				 intf.drv_cb.pkt_tx_eop <=0;
				 intf.drv_cb.pkt_tx_data <=0;
				 intf.drv_cb.pkt_tx_mod <=0;
			 end 
			 seq_item_port.item_done();

		 end 
	endtask  
	   // here it is to control the driver to reset when ever we are doing the fresh code execution , if it has not done then it will have 
	   //the last executed values in it , then that will be a mess  
	   function reset_driver;
	             intf.drv_cb.pkt_tx_val <=0;
				 intf.drv_cb.pkt_tx_sop <=0;
				 intf.drv_cb.pkt_tx_eop <=0;
				 intf.drv_cb.pkt_tx_data <=0;
				 intf.drv_cb.pkt_tx_mod <=0;
	   endfunction

endclass
