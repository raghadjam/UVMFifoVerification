`ifndef FIFO_TEST_RANDOM_SV
`define FIFO_TEST_RANDOM_SV

`include "uvm_macros.svh"
import uvm_pkg::*;
class fifo_test_random extends fifo_base_test;
  `uvm_component_utils(fifo_test_random)

  function new(string name = "fifo_test_random", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    fifo_seq_base::type_id::set_inst_override(
        fifo_seq_random::get_type(),        
        "env.agt.sqr.main_phase.default_sequence");
  endfunction
endclass : fifo_test_random
`endif 