// tb/fifo_agent.sv
`ifndef FIFO_AGENT_SV
`define FIFO_AGENT_SV
`include "uvm_macros.svh"
import uvm_pkg::*;

class fifo_agent extends uvm_component;
  `uvm_component_utils(fifo_agent)

  fifo_sequencer sqr;
  fifo_driver_base drv;
  fifo_monitor mon;
  uvm_analysis_port#(fifo_item)  ap;

  function new(string n="fifo_agent", uvm_component p=null);
    super.new(n,p);
  endfunction

  function void build_phase(uvm_phase phase);
    sqr = fifo_sequencer::type_id::create("sqr", this);
    drv = fifo_driver_base::type_id::create("drv", this);
    mon = fifo_monitor::type_id::create("mon", this);
    ap  = new("ap", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    drv.seq_item_port.connect(sqr.seq_item_export);
    mon.ap.connect(ap);
  endfunction
endclass 

`endif
