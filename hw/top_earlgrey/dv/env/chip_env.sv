// Copyright lowRISC contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

class chip_env extends cip_base_env #(
    .CFG_T              (chip_env_cfg),
    .COV_T              (chip_env_cov),
    .VIRTUAL_SEQUENCER_T(chip_virtual_sequencer),
    .SCOREBOARD_T       (chip_scoreboard)
  );
  `uvm_component_utils(chip_env)

  uart_agent          m_uart_agent;
  jtag_agent          m_jtag_agent;
  spi_agent           m_spi_agent;

  `uvm_component_new

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    // configure the cpu d tl agent
    // get the vifs from config db
    if (!uvm_config_db#(virtual clk_rst_if)::get(this, "", "usb_clk_rst_vif",
        cfg.usb_clk_rst_vif)) begin
      `uvm_fatal(`gfn, "failed to get usb_clk_rst_vif from uvm_config_db")
    end

    if (!uvm_config_db#(gpio_vif)::get(this, "", "gpio_vif", cfg.gpio_vif)) begin
      `uvm_fatal(`gfn, "failed to get gpio_vif from uvm_config_db")
    end

    if (!uvm_config_db#(virtual pins_if#(1))::get(this, "", "srst_n_vif", cfg.srst_n_vif)) begin
      `uvm_fatal(`gfn, "failed to get srst_n_vif from uvm_config_db")
    end

    if (!uvm_config_db#(virtual pins_if#(1))::get(this, "", "jtag_spi_n_vif",
        cfg.jtag_spi_n_vif)) begin
      `uvm_fatal(`gfn, "failed to get jtag_spi_n_vif from uvm_config_db")
    end

    if (!uvm_config_db#(virtual pins_if#(1))::get(this, "", "bootstrap_vif",
        cfg.bootstrap_vif)) begin
      `uvm_fatal(`gfn, "failed to get bootstrap_vif from uvm_config_db")
    end

    foreach (cfg.mem_bkdr_vifs[mem]) begin
      if (!uvm_config_db#(mem_bkdr_vif)::get(this, "", $sformatf("mem_bkdr_vifs[%0s]", mem.name),
                                             cfg.mem_bkdr_vifs[mem])) begin
        `uvm_fatal(`gfn, $sformatf("failed to get mem_bkdr_vifs[%0s] from uvm_config_db", mem.name))
      end
    end

    // get the handle to the sw log monitor for available sw_types
    foreach (cfg.sw_types[i]) begin
      if (!uvm_config_db#(sw_logger_vif)::get(this, "",
                                              $sformatf("sw_logger_vif[%0s]", cfg.sw_types[i]),
                                              cfg.sw_logger_vif[cfg.sw_types[i]])) begin
          `uvm_fatal(`gfn, $sformatf("failed to get sw_logger_vif[%0s] from uvm_config_db",
                                     cfg.sw_types[i]))
      end
    end

    if (!uvm_config_db#(virtual sw_test_status_if)::get(this, "", "sw_test_status_vif",
        cfg.sw_test_status_vif)) begin
      `uvm_fatal(`gfn, "failed to get sw_test_status_vif from uvm_config_db")
    end

    // create components
    m_uart_agent = uart_agent::type_id::create("m_uart_agent", this);
    uvm_config_db#(uart_agent_cfg)::set(this, "m_uart_agent*", "cfg", cfg.m_uart_agent_cfg);

    m_jtag_agent = jtag_agent::type_id::create("m_jtag_agent", this);
    uvm_config_db#(jtag_agent_cfg)::set(this, "m_jtag_agent*", "cfg", cfg.m_jtag_agent_cfg);

    m_spi_agent = spi_agent::type_id::create("m_spi_agent", this);
    uvm_config_db#(spi_agent_cfg)::set(this, "m_spi_agent*", "cfg", cfg.m_spi_agent_cfg);

  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    if (cfg.en_scb) begin
      m_uart_agent.monitor.tx_analysis_port.connect(scoreboard.uart_tx_fifo.analysis_export);
      m_uart_agent.monitor.rx_analysis_port.connect(scoreboard.uart_rx_fifo.analysis_export);
      m_jtag_agent.monitor.analysis_port.connect(scoreboard.jtag_fifo.analysis_export);
    end
    if (cfg.is_active && cfg.m_uart_agent_cfg.is_active) begin
      virtual_sequencer.uart_sequencer_h = m_uart_agent.sequencer;
    end
    if (cfg.is_active && cfg.m_jtag_agent_cfg.is_active) begin
      virtual_sequencer.jtag_sequencer_h = m_jtag_agent.sequencer;
    end
    if (cfg.is_active && cfg.m_spi_agent_cfg.is_active) begin
      virtual_sequencer.spi_sequencer_h = m_spi_agent.sequencer;
    end
  endfunction

  virtual function void end_of_elaboration_phase(uvm_phase phase);
    super.end_of_elaboration_phase(phase);
  endfunction : end_of_elaboration_phase

endclass
