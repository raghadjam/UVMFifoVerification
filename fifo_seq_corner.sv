`ifndef FIFO_SEQ_CORNER_SV
`define FIFO_SEQ_CORNER_SV

class fifo_seq_corner extends fifo_seq_base;
  `uvm_object_utils(fifo_seq_corner)
  
  function new(string name="fifo_seq_corner");
    super.new(name);
  endfunction
  
  virtual task body();
    bit [31:0] status_data;
    
    // Test EN=0 behavior 
    init_fifo();
    reg_env.reg_block.fifo.ctrl.en.write(status, 0);
    do_push(); // ignored
    do_pop();  // ignored
    reg_env.reg_block.fifo.ctrl.en.write(status, 1);
    
    // Disable mid operation 
    init_fifo();
    repeat(5) do_push();
    reg_env.reg_block.fifo.ctrl.en.write(status, 0);
    do_push(); // ignored
    do_pop();  // ignored
    reg_env.reg_block.fifo.status.read(status, status_data);
    if (status_data[8:5] != 5) 
      `uvm_error("SEQ", "Count changed when EN=0!")
    reg_env.reg_block.fifo.ctrl.en.write(status, 1);
    
    // Clear when empty
    init_fifo();
    reg_env.reg_block.fifo.ctrl.clr.write(status, 1);
    reg_env.reg_block.fifo.status.read(status, status_data);
    if (status_data[8:5] != 0) 
      `uvm_error("SEQ", "Count not 0 after clear on empty")
    
    // Clear when partially filled
    init_fifo();
    repeat(5) do_push();
    reg_env.reg_block.fifo.ctrl.clr.write(status, 1);
    reg_env.reg_block.fifo.status.read(status, status_data);
    if (status_data[8:5] != 0) 
      `uvm_error("SEQ", "Count not 0 after clear on partial")
    
    // Clear when full
    init_fifo();
    fill_to_full();
    reg_env.reg_block.fifo.ctrl.clr.write(status, 1);
    reg_env.reg_block.fifo.status.read(status, status_data);
    if (status_data[8:5] != 0 || status_data[1] != 0) 
      `uvm_error("SEQ", "Not empty after clear on full")
    
    // Sticky overflow flag 
    init_fifo();
    fill_to_full();
    reg_env.reg_block.fifo.ctrl.drop_on_full.write(status, 0);
    do_push(); // overflow
    
    reg_env.reg_block.fifo.status.read(status, status_data);
    if (status_data[3] != 1) 
      `uvm_error("SEQ", "Overflow flag not set")
    
    // Verify sticky through operations
    do_pop();
    do_push();
    reg_env.reg_block.fifo.status.read(status, status_data);
    if (status_data[3] != 1) 
      `uvm_error("SEQ", "Overflow flag not sticky")
    
    // Clear and verify overflow cleared
    reg_env.reg_block.fifo.ctrl.clr.write(status, 1);
    reg_env.reg_block.fifo.status.read(status, status_data);
    if (status_data[3] != 0) 
      `uvm_error("SEQ", "Overflow flag not cleared by CLR")
    
    // Sticky underflow flag 
    init_fifo();
    do_pop(); // underflow on empty
    
    reg_env.reg_block.fifo.status.read(status, status_data);
    if (status_data[4] != 1) 
      `uvm_error("SEQ", "Underflow flag not set")
    
    // Verify sticky through operations
    do_push();
    do_pop();
    reg_env.reg_block.fifo.status.read(status, status_data);
    if (status_data[4] != 1) 
      `uvm_error("SEQ", "Underflow flag NOT sticky")
    
    // Clear and verify underflow cleared
    reg_env.reg_block.fifo.ctrl.clr.write(status, 1);
    reg_env.reg_block.fifo.status.read(status, status_data);
    if (status_data[4] != 0) 
      `uvm_error("SEQ", "Underflow flag not cleared by CLR")
    
    // DROP_ON_FULL behavior 
    init_fifo();
    fill_to_full();
    
    // Test DROP_ON_FULL=0
    reg_env.reg_block.fifo.ctrl.drop_on_full.write(status, 0);
    do_push();
    reg_env.reg_block.fifo.status.read(status, status_data);
    if (status_data[3] != 1) 
      `uvm_error("SEQ", "Overflow not set with DROP_ON_FULL=0")
    
    // Clear and test DROP_ON_FULL=1
    init_fifo();
    fill_to_full();
    reg_env.reg_block.fifo.ctrl.drop_on_full.write(status, 1);
    do_push(); 
    reg_env.reg_block.fifo.status.read(status, status_data);
    if (status_data[3] != 0) 
      `uvm_error("SEQ", "Overflow set with DROP_ON_FULL=1")
    
    // Threshold testing 
    init_fifo();
    
    reg_env.reg_block.fifo.thresh.almost_full_th.write(status, depth-2);
    reg_env.reg_block.fifo.thresh.almost_empty_th.write(status, 2);
    
    // Push to almost_full threshold
    repeat(depth-2) do_push();
    reg_env.reg_block.fifo.status.read(status, status_data);
    if (status_data[2] != 1) 
      `uvm_error("SEQ", "Almost flag not set at almost_full_th")
    
    // Push to full
    repeat(2) do_push();
    
    // Pop to almost_empty threshold
    repeat(depth-2) do_pop();
    reg_env.reg_block.fifo.status.read(status, status_data);
    if (status_data[2] != 1) 
      `uvm_error("SEQ", "Almost flag not set at almost_empty_th")
    
    // Threshold changes 
    init_fifo();
    
    reg_env.reg_block.fifo.thresh.almost_full_th.write(status, 10);
    reg_env.reg_block.fifo.thresh.almost_empty_th.write(status, 3);
    
    repeat(8) do_push();
    reg_env.reg_block.fifo.status.read(status, status_data);
    if (status_data[2] != 0) 
      `uvm_error("SEQ", "Almost should be 0 at count=8")
    
    reg_env.reg_block.fifo.thresh.almost_full_th.write(status, 7);
    reg_env.reg_block.fifo.status.read(status, status_data);
    if (status_data[2] != 1) 
      `uvm_error("SEQ", "Almost should be 1 after lowering threshold")
    
    random_operations();
      endtask
  
endclass : fifo_seq_corner

`endif