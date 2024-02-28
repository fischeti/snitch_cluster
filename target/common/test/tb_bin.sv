// Copyright 2020 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

/// RTL Top-level for DRAMSys simulation.
module tb_bin;
  import "DPI-C" function int fesvr_tick();
  import "DPI-C" function void fesvr_cleanup();

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
    .ClkPeriodNs  ( int'(TCK) ),
    .ReturnSymbol ( "tohost"  )
  ) i_dram_sim_engine (
    .clk_i  ( clk   ),
    .rst_ni ( rst_n )
  );

  // Start `fesvr`
  initial begin
    automatic int exit_code;
    while ((exit_code = fesvr_tick()) == 0) #200ns;
    // Cleanup C++ simulation objects before $finish is called
    fesvr_cleanup();
    exit_code >>= 1;
    if (exit_code > 0) begin
      $error("[FAILURE] Finished with exit code %2d", exit_code);
    end else begin
      $info("[SUCCESS] Program finished successfully");
    end
    $finish;
  end

endmodule
