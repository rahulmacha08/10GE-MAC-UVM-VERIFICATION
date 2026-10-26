module assertions (
    input logic        clk,
    input logic        rst_n,        // active low reset
    // TX side
    input logic        pkt_tx_val,
    input logic        pkt_tx_sop,
    input logic        pkt_tx_eop,
    input logic [63:0] pkt_tx_data,
    input logic [2:0]  pkt_tx_mod,
    input logic        pkt_tx_full,
    // RX side
    input logic        pkt_rx_val,
    input logic        pkt_rx_sop,
    input logic        pkt_rx_eop,
    input logic [63:0] pkt_rx_data,
    input logic [2:0]  pkt_rx_mod,
    input logic        pkt_rx_err,
    input logic        pkt_rx_ren
);

  property p_tx_valid_data;
    @(posedge clk)
      pkt_tx_val |-> (pkt_tx_data != 64'b0 && !$isunknown(pkt_tx_data));
  endproperty
  assert property (p_tx_valid_data)
    else $error("[ASSERT] p_tx_valid_data : pkt_tx_data is zero or X/Z when pkt_tx_val=1");

  property p_tx_not_full;
    @(posedge clk)
      pkt_tx_val |-> !pkt_tx_full;
  endproperty
  assert property (p_tx_not_full)
    else $error("[ASSERT] p_tx_not_full : pkt_tx_val asserted while pkt_tx_full=1");

  property pkt_sop;
    @(posedge clk)
      $rose(pkt_tx_val) |-> pkt_tx_sop;
  endproperty
  assert property (pkt_sop)
    else $error("[ASSERT] p_first_beat_has_sop : SOP not high on first pkt_tx_val cycle");

  // 4. Last beat of every frame must assert EOP
  property pkt_eop;
    @(posedge clk)
      $fell(pkt_tx_val) |-> $past(pkt_tx_eop);
  endproperty
  assert property (pkt_eop)
    else $error("[ASSERT] p_last_beat_has_eop : EOP not high on final pkt_tx_val cycle");

  // 5. SOP and EOP must never both be 1 in the same cycle
  property p_sop_eop_mutually_exclusive;
    @(posedge clk)
      (!$isunknown(pkt_tx_sop) && !$isunknown(pkt_tx_eop))
      |-> !(pkt_tx_sop && pkt_tx_eop);
  endproperty
  assert property (p_sop_eop_mutually_exclusive)
    else $error("[ASSERT] p_sop_eop_mutually_exclusive : SOP and EOP both 1");

  // 6. When RX is 'valid & readEnable', data must be non-zero
  property p_rx_ren_has_data;
    @(posedge clk)
      pkt_rx_val |-> pkt_rx_ren;
  endproperty
  assert property (p_rx_ren_has_data)
    else $error("[ASSERT] p_rx_ren_has_data : pkt_rx_ren should be high pkt_rx_val");

  // 7. RX MOD bits legal only alongside EOP
  property p_rx_mod_only_at_eop;
    @(posedge clk)
      !pkt_rx_eop |-> (pkt_rx_mod == 3'b0);
  endproperty
  assert property (p_rx_mod_only_at_eop)
    else $error("[ASSERT] p_rx_mod_only_at_eop : pkt_rx_mod non-zero while pkt_rx_eop=0");

  // pkt_rx_mod should be zero when EOP low
  property mod_only_at_eop;
    @(posedge clk)
      !pkt_rx_eop |-> (pkt_rx_mod == 3'b000);
  endproperty
  assert property (mod_only_at_eop)
    else $error("[ASSERT] mod_only_at_eop : pkt_rx_mod active without EOP");

endmodule
