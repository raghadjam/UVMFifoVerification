class fifo_test_corner extends fifo_base_test;
  `uvm_component_utils(fifo_test_corner)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    fifo_seq_base::type_id::set_inst_override(
        fifo_seq_corner::get_type(),  
        "env.agt.sqr.main_phase.default_sequence"
    );
  endfunction
endclass
