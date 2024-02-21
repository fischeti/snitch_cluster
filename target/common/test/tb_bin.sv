// Copyright 2020 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

/// RTL Top-level for DRAMSys simulation.
module tb_bin;
  import "DPI-C" function void dram_load_elf(input int dram_id, input longint dram_base_addr, input string app_path);

  // This can't have an explicit type, otherwise the simulation will not advance
  // for whatever reason.
  // verilog_lint: waive explicit-parameter-storage-type
  localparam TCK = 1ns;

  logic rst_n, clk;

  testharness i_dut (
    .clk_i(clk),
    .rst_ni(rst_n)
  );

  clk_rst_gen #(
    .ClkPeriod    ( TCK ),
    .RstClkCycles ( 5   )
  ) i_clk_gen (
    .clk_o  ( clk   ),
    .rst_no ( rst_n )
  );

  dram_sim_engine #(
    .ClkPeriodNs  ( int'(TCK) )
  ) i_dram_sim_engine (
    .clk_i  ( clk   ),
    .rst_ni ( rst_n )
  );

  string binary;

  initial begin
    // Check if `BINARY` is defined
    if (!$value$plusargs("BINARY=%s", binary)) begin
      $error("BINARY not defined");
    end else begin
      // Preload the binary
      $display("Preloading binary %s", binary);
      dram_load_elf(0, 'h8000_0000, binary);
    end

    $readmemh("test/bootrom.memh", i_dut.i_bootrom_sim_mem.mem, 'h10000);
  end

endmodule
