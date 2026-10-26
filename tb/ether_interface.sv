interface ether_interface(
  
  input bit clk,
  input bit rst,
  input bit clk_156m25,
  input bit clk_xgmii_tx,
  input bit clk_xgmii_rx,
  input bit wb_clk_i,
  input bit reset_156m25,
  input bit reset_xgmii_tx,
  input bit reset_xgmii_rx,
  input bit wb_rst_i);

  //Tx signals
  logic       pkt_tx_val;
  logic       pkt_tx_sop;
  logic       pkt_tx_eop;
  logic [2:0] pkt_tx_mod;
  logic [63:0]pkt_tx_data;
  logic       pkt_tx_full;

  //Rx signals
  logic       pkt_rx_val;
  logic       pkt_rx_sop;
  logic       pkt_rx_eop;
  logic [2:0] pkt_rx_mod;
  logic       pkt_rx_err;
  logic [63:0]pkt_rx_data;
  logic       pkt_rx_avail;
  logic       pkt_rx_ren;

  // XGMII signals
  logic [63:0] xgmii_rxd;
  logic [7:0]  xgmii_rxc;
  logic [63:0] xgmii_txd;
  logic [2:0]  xgmii_txc;

  clocking drv_cb@(posedge clk);
    default input #0 output #0;

	output pkt_tx_val;
	output pkt_tx_sop;
	output pkt_tx_eop;
	output pkt_tx_mod;
	output pkt_tx_data;
	input pkt_tx_full;

	input pkt_rx_val;
	input pkt_rx_sop;
	input pkt_rx_eop;
	input pkt_rx_mod;
	input pkt_rx_err;
	input pkt_rx_data;
	input pkt_rx_avail;
	output pkt_rx_ren;
    
	input xgmii_txd;
	input xgmii_txc;
	input xgmii_rxd;
	input xgmii_rxc;

  endclocking

  clocking mon_cb@(posedge clk);
    default input #0 output #0;

	input pkt_tx_val;
	input pkt_tx_sop;
	input pkt_tx_eop;
	input pkt_tx_mod;
	input pkt_tx_data;
	input pkt_tx_full;

	input pkt_rx_val;
	input pkt_rx_sop;
	input pkt_rx_eop;
	input pkt_rx_mod;
	input pkt_rx_err;
	input pkt_rx_data;
	input pkt_rx_avail;
	input pkt_rx_ren;

	input xgmii_txd;
	input xgmii_txc;
	input xgmii_rxd;
	input xgmii_rxc;
  endclocking

  modport drive(clocking drv_cb);
  modport mont(clocking mon_cb);

endinterface
