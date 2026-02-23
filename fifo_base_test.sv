
class fifo_base_test extends uvm_test;
  `uvm_component_utils(fifo_base_test)


  fifo_env env;       
  fifo_seq_base seq;
  uvm_report_server svr;

  function new(string name = "fifo_base_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new


  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    uvm_top.set_report_id_action("RegModel", UVM_NO_ACTION);
  uvm_top.set_report_id_action("UVM/CONFIGDB/SPELLCHK", UVM_NO_ACTION);
  uvm_top.set_report_id_action("UVM/RSRC/NOREGEX", UVM_NO_ACTION);

    env = fifo_env::type_id::create("env", this);
    if (env == null)
      `uvm_fatal(get_type_name(), "Failed to create fifo_env via factory")
  endfunction : build_phase

task run_phase(uvm_phase phase); 
    phase.raise_objection(this); 
    
    seq = fifo_seq_random::type_id::create("seq"); 
    seq.reg_env = env.reg_env; 
    seq.start(env.agt.sqr);
    
    phase.drop_objection(this); 
endtask


  function void report_phase(uvm_phase phase);
    super.report_phase(phase);

    svr = uvm_report_server::get_server();

    if ((svr.get_severity_count(UVM_FATAL) + svr.get_severity_count(UVM_ERROR)) > 0) begin
      `uvm_info(get_type_name(), "┌───────────────────────────────────────────┐", UVM_NONE)
      `uvm_info(get_type_name(), "│              ✘ TEST FAILED ✘             │", UVM_NONE)
      `uvm_info(get_type_name(), "│   Fatal or Error messages were detected   │", UVM_NONE)
      `uvm_info(get_type_name(), "└───────────────────────────────────────────┘", UVM_NONE)
    end else begin
      `uvm_info(get_type_name(), "┌───────────────────────────────────────────┐", UVM_NONE)
      `uvm_info(get_type_name(), "│              ✓ TEST PASSED ✓             │", UVM_NONE)
      `uvm_info(get_type_name(), "│     No fatal or error messages reported   │", UVM_NONE)
      `uvm_info(get_type_name(), "└───────────────────────────────────────────┘", UVM_NONE)
    end
  endfunction : report_phase

endclass : fifo_base_test
