`timescale 1ns/1ps
`include "uvm_macros.svh"
import uvm_pkg::*;


`include "fifo_if.sv"
`include "fifo_item.sv"
`include "fifo_sequencer.sv"
`include "fifo_driver_base.sv"
`include "fifo_monitor.sv"
`include "fifo_agent.sv"
`include "fifo_scoreboard.sv"

`include "fifo_reg_model.sv"  
`include "fifo_reg_adapter.sv" 
`include "fifo_env.sv"


`include "fifo_seq_base.sv"     
`include "fifo_random_seq.sv"
`include "fifo_seq_corner.sv"

`include "fifo_base_test.sv"
`include "fifo_test_corner.sv"
`include "fifo_test_random.sv"


module top_tb;

  logic clk;
  logic reset_n;

  initial begin
    clk = 0;
    forever #5 clk = ~clk; 
  end

  initial begin
    reset_n = 0;
    #20;
    reset_n = 1;        
  end

  apb_sync_fifo_if fifo_if(clk, reset_n);

  apb_sync_fifo #(
    .WIDTH(8),
    .DEPTH(16)
  ) dut (
    .PCLK    (clk),
    .PRESETn (reset_n),
    .PSEL    (fifo_if.PSEL),
    .PENABLE (fifo_if.PENABLE),
    .PWRITE  (fifo_if.PWRITE),
    .PADDR   (fifo_if.PADDR),
    .PWDATA  (fifo_if.PWDATA),
    .PRDATA  (fifo_if.PRDATA),
    .PREADY  (fifo_if.PREADY),
    .PSLVERR (fifo_if.PSLVERR)
  );
  
  logic [7:0] mem0_monitor;
  logic [3:0] wptr_monitor;
  logic [3:0] rptr_monitor;

  assign mem0_monitor = dut.mem[0];   
  assign wptr_monitor = dut.wptr;
  assign rptr_monitor = dut.rptr;

  initial begin
    $dumpfile("dump.vcd");
    $dumpvars(0, top_tb);
    $dumpvars(0, mem0_monitor);  
    $dumpvars(0, wptr_monitor);
    $dumpvars(0, rptr_monitor);
  end

  initial begin
  	uvm_config_db#(virtual apb_sync_fifo_if)::set(null, "*", "vif", fifo_if);
	uvm_top.set_report_verbosity_level(UVM_NONE);
    run_test("fifo_base_test");  
  end

endmodule
