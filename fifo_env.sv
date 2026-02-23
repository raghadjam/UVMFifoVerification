`ifndef FIFO_ENV_SV
`define FIFO_ENV_SV


class fifo_env extends uvm_env;
  `uvm_component_utils(fifo_env)

  fifo_agent       agt;
  fifo_scoreboard  sb;
  fifo_reg_env     reg_env;

  function new(string name="fifo_env", uvm_component parent=null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    agt = fifo_agent::type_id::create("agt", this);
    sb  = fifo_scoreboard::type_id::create("sb", this);
    reg_env = fifo_reg_env::type_id::create("reg_env", this);
  endfunction

function void connect_phase(uvm_phase phase);
  super.connect_phase(phase);

  agt.mon.ap.connect(reg_env.predictor.bus_in);
  agt.mon.ap.connect(sb.monitor_imp);

  reg_env.reg_block.default_map.set_sequencer(agt.sqr, reg_env.adapter);
endfunction


endclass

`endif
