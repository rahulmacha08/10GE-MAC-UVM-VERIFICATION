typedef enum {runt, jumbo} frame_type;  // these are worote here to control the frame type for testcase purpose.
typedef enum {TX, RX} agent_mode; // to select which agent has to be used in the agent cuz it has tow agents in it.

class config_object extends uvm_object;

  int disable_compare; // it is for disabling the comparison in the scoreboard. 
  rand int frame_data;  // it is the variable for inserting the randomized data.
  bit [55:0] preamble_cfg = 56'h55555555555555;       // standard value of preamble
  bit [7:0]  sfd_cfg = 8'hD5; //standard value of the SFD

  `uvm_object_utils(config_object)

  agent_mode tx_rx_mode;  

  frame_type frame_typ;               
  uvm_active_passive_enum active_passive;
  bit has_functional_coverage = 1;  // it is for the enableling or disableing the coverage
  bit has_scoreboard = 1;    // it is the enabableing or the diableing the scoreboad itself.

  function new(string name = "config_object");
    super.new(name);
  endfunction

  // Constraint based on frame_typ (used internally)
  constraint con_frame {
    if (frame_typ == runt)
      soft frame_data inside {[0:45]};
    else if (frame_typ == jumbo)
      soft frame_data inside {[1500:$]};
    else
      soft frame_data inside {[47:1500]};
  }

  //  constraint con_frame {soft frame_data inside {[46:1500]};}

endclass


/*
typedef enum {runt, jumbo} frame_type;
typedef enum {TX, RX} agent_mode;

class config_object extends uvm_object;

  int disable_compare;
  rand int frame_data;
  bit [55:0] preamble_cfg = 56'h55555555555555;       
  bit [7:0]  sfd_cfg = 8'hD5;

  `uvm_object_utils(config_object)

  agent_mode tx_rx_mode;

  frame_type frame_typ;               
  uvm_active_passive_enum active_passive;
  bit has_functional_coverage = 1;
  bit has_scoreboard = 1;

 // int eop_count_tx;
 // int eop_count_rx;

  //int sop_count_tx;
  //int sop_count_rx;

  function new(string name = "config_object");
    super.new(name);
  endfunction

  // Constraint based on frame_typ (used internally)
  constraint con_frame {
    if (frame_typ == runt)
      soft frame_data inside {[0:45]};
    else if (frame_typ == jumbo)
      soft frame_data inside {[1500:$]};
    else
      soft frame_data inside {[47:1500]};
  }

endclass
*/
