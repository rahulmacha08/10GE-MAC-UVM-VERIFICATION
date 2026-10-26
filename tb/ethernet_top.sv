

`include "uvm_macros.svh"
import uvm_pkg::*;

`include"assertions.sv"
`include"config_object.sv"
`include"dut.sv"
`include"ether_interface.sv"
`include"seq_item.sv"
`include"sequencer.sv"
`include"ether_sequence.sv"
/*
`include"ethernet_runt_sequence.sv"
`include"ethernet_jumbo_sequence.sv"
`include"reset_sequence.sv"
`include"ethernet_incr_sequence.sv"
`include"error_sequence.sv" */

`include"driver.sv"
`include"ethernet_monitor.sv"
`include"ethernet_agent.sv"
`include"scoreboard.sv"
`include"subscriber.sv"
`include"environment.sv"
`include"ethernet_base_test.sv"
`include"test1.sv"

`include"ethernet_runt_test.sv"

`include"ethernet_jumbo_test.sv"
/*
`include"ethernet_incr_test.sv"
`include"reset_test.sv"
`include"error_test.sv" */

module top;
 bit clk,rst,reset_xgmii_rx_n, reset_xgmii_tx_n, wb_clk_i ,wb_rst_i;
 bit wb_cyc_i; 
 bit wb_stb_i;
 bit wb_we_i;

 bit[7:0] wb_adr_i;
 bit[31:0] wb_dat_i;
 bit[31:0] wb_dat_o;

 bit wb_act_o;
 bit wb_int_o;

 bit[63:0] xgmii_rxd;
 bit[7:0]  xgmii_rxc;
 bit[63:0] xgmii_txd;
 bit[7:0]  xgmii_txc;

 bind d1 assertions assertion_ethernet (
              .clk(intf.clk),
			  .pkt_tx_val(intf.pkt_tx_val),
			  .pkt_tx_sop(intf.pkt_tx_sop),
			  .pkt_tx_eop(intf.pkt_tx_eop),
			  .pkt_tx_mod(intf.pkt_tx_mod),
			  .pkt_tx_data(intf.pkt_tx_data),
			  .pkt_rx_data(intf.pkt_rx_data),
			  .pkt_tx_full(intf.pkt_tx_full),
			  .pkt_rx_ren (intf.pkt_rx_ren),
			  .pkt_rx_val(intf.pkt_rx_val),

			  .pkt_rx_sop(intf.pkt_rx_sop),
			  .pkt_rx_eop(intf.pkt_rx_eop),
			  .pkt_rx_mod(intf.pkt_rx_mod)
			  );

ether_interface intf( clk,rst,reset_xgmii_rx_n,
                     reset_xgmii_tx_n, wb_rst_i);

//connect interface to DUT using modpot dut

  xge_mac d1(
          .clk_156m25(intf.clk),
          .reset_156m25_n(rst),
          .clk_xgmii_rx(intf.clk),
          .clk_xgmii_tx(intf.clk),
          .reset_xgmii_rx_n(reset_xgmii_rx_n),
          .reset_xgmii_tx_n(reset_xgmii_tx_n),
		  .wb_rst_i(wb_rst_i),
          .wb_clk_i(intf.clk),
          .pkt_tx_val(intf.pkt_tx_val),
          .pkt_tx_sop(intf.pkt_tx_sop),
          .pkt_tx_eop(intf.pkt_tx_eop),
          .pkt_tx_mod(intf.pkt_tx_mod),
          .pkt_tx_data(intf.pkt_tx_data),
          .pkt_tx_full(intf.pkt_tx_full),

		  .wb_cyc_i(wb_cyc_i), .wb_stb_i(wb_stb_i), .wb_we_i(wb_wr_i),
		  .wb_adr_i(wb_adr_i), .wb_dat_i(wb_dat_i), .wb_dat_o(wb_dat_o), .wb_ack_o(wb_ack_o), .wb_int_o(wb_int_o), 

		  .pkt_rx_val(intf.pkt_rx_val),
		  .pkt_rx_sop(intf.pkt_rx_sop),
		  .pkt_rx_eop(intf.pkt_rx_eop),
		  .pkt_rx_mod(intf.pkt_rx_mod),
		  .pkt_rx_err(intf.pkt_rx_err),
		  .pkt_rx_data(intf.pkt_rx_data),
		  .pkt_rx_avail(intf.pkt_rx_avail),
		  .pkt_rx_ren(intf.pkt_rx_ren),
		  .xgmii_rxd(intf.xgmii_rxd), .xgmii_rxc(intf.xgmii_rxc) ,.xgmii_txd(intf.xgmii_txd), .xgmii_txc(intf.xgmii_txc) 
		  );
   
     assign intf.xgmii_rxd = intf.xgmii_txd;
     assign intf.xgmii_rxc = intf.xgmii_txc;
	 
	 always #5 clk = ~clk;

	 initial begin 
	  clk = 1;
	  rst = 0;
	  reset_xgmii_rx_n = 0;
	  reset_xgmii_tx_n = 0;
	  wb_rst_i = 1;
	  #100;

	  rst = 1;
	  reset_xgmii_rx_n = 1;
	  reset_xgmii_tx_n = 1;
	  wb_rst_i = 0;
	 end 
	 
	 initial begin 
	    run_test("runt_test");
	 end 
	 
	 initial begin
	  uvm_config_db#(virtual ether_interface)::set(null,"*","intf",intf);
	 end

	 initial begin 
	 //set an integer value directly in config_db
	 uvm_config_db#(int)::set(null,"*","my_value",7);
	 end

	 initial begin 
	 // 1) for the driver (uses.drive modport)
	 uvm_config_db#(virtual ether_interface.drive)::set(null,"*","intf",intf);
	 //2) for both monitors (they use .mont modport)
	 uvm_config_db#(virtual ether_interface.mont)::set(null,"*","intf",intf);
	 end 

endmodule




