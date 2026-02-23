`ifndef FIFO_SEQ_BASE_SV
`define FIFO_SEQ_BASE_SV
`include "uvm_macros.svh"
import uvm_pkg::*;

class fifo_seq_base extends uvm_sequence #(fifo_item);
  `uvm_object_utils(fifo_seq_base)
  
  rand int unsigned n_ops = 100;   
  rand int unsigned depth = 16;   
  fifo_reg_env reg_env;
  uvm_status_e status;
  
  function new(string name="fifo_seq_base");
    super.new(name);
  endfunction
  
  virtual function void set_env(fifo_reg_env env);
    reg_env = env;
  endfunction
  
  
 virtual task init_fifo();
    
    // Clear
    reg_env.reg_block.fifo.ctrl.write(status, 32'h2);
    
    // Enable
    reg_env.reg_block.fifo.ctrl.write(status, 32'h1);
endtask
  
  virtual task enable_fifo();
    bit [31:0] ctrl_val;
    reg_env.reg_block.fifo.ctrl.read(status, ctrl_val);
    ctrl_val[0] = 1;  // Set EN bit
    reg_env.reg_block.fifo.ctrl.write(status, ctrl_val);
    `uvm_info("SEQ", "FIFO enabled", UVM_MEDIUM);
  endtask
  
  virtual task disable_fifo();
    bit [31:0] ctrl_val;
    reg_env.reg_block.fifo.ctrl.read(status, ctrl_val);
    ctrl_val[0] = 0;  // Clear EN bit
    reg_env.reg_block.fifo.ctrl.write(status, ctrl_val);
    `uvm_info("SEQ", "FIFO disabled", UVM_MEDIUM);
  endtask
  
  virtual task clear_fifo();
    bit [31:0] ctrl_val;
    reg_env.reg_block.fifo.ctrl.read(status, ctrl_val);
    ctrl_val[1] = 1;  // Set CLR bit
    reg_env.reg_block.fifo.ctrl.write(status, ctrl_val);
    `uvm_info("SEQ", "FIFO cleared", UVM_MEDIUM);
  endtask
  
  
  virtual task configure_drop_on_full(bit enable);
    bit [31:0] ctrl_val;
    reg_env.reg_block.fifo.ctrl.read(status, ctrl_val);
    ctrl_val[2] = enable;  // Set/clear DROP_ON_FULL bit
    reg_env.reg_block.fifo.ctrl.write(status, ctrl_val);
    `uvm_info("SEQ", $sformatf("DROP_ON_FULL=%0b", enable), UVM_MEDIUM);
  endtask
  
  virtual task configure_thresholds(int almost_full, int almost_empty);
    bit [31:0] thresh_val;
    thresh_val[7:0] = almost_full;
    thresh_val[15:8] = almost_empty;
    reg_env.reg_block.fifo.thresh.write(status, thresh_val);
    `uvm_info("SEQ", $sformatf("Thresholds: AF=%0d AE=%0d", almost_full, almost_empty), UVM_MEDIUM);
  endtask
  
  virtual task random_configure();
    configure_drop_on_full($urandom_range(0,1));
    configure_thresholds($urandom_range(1, depth), $urandom_range(0, depth-1));
  endtask
  
  
  virtual task do_push(bit [7:0] data = $urandom());
    bit [31:0] ctrl_val;
    reg_env.reg_block.fifo.ctrl.read(status, ctrl_val);
    
    if (ctrl_val[0] == 0) begin
        `uvm_info("SEQ", "CTRL.EN=0, cannot push", UVM_MEDIUM)
        return;
    end
    
    reg_env.reg_block.fifo.data.write(status, {24'h0, data});
    if (status != UVM_IS_OK) begin
        `uvm_error("SEQ", $sformatf("DATA write failed for 0x%0h", data));
    end else begin
        `uvm_info("SEQ", $sformatf("Pushed 0x%0h to FIFO", data), UVM_MEDIUM);
    end
  endtask
  
  virtual task do_pop();
    bit [31:0] read_data;
    bit [31:0] ctrl_val;
    reg_env.reg_block.fifo.ctrl.read(status, ctrl_val);
    
    if (ctrl_val[0] == 0) begin
        `uvm_info("SEQ", "CTRL.EN=0, cannot pop", UVM_MEDIUM)
        return;
    end
    
    reg_env.reg_block.fifo.data.read(status, read_data);
    if (status != UVM_IS_OK) begin
        `uvm_error("SEQ", "DATA read failed");
    end else begin
        `uvm_info("SEQ", $sformatf("Popped 0x%0h from FIFO", read_data[7:0]), UVM_MEDIUM);
    end
  endtask
  
  virtual task do_both();
    do_push();
    do_pop();
  endtask
    
  virtual task fill_to_full();
    repeat(depth) begin
      do_push();
    end
  endtask
  
  virtual task drain_to_empty();
    repeat(depth) begin
      do_pop();
    end
  endtask
  
  virtual task fill_to_count(int target_count);
    repeat(target_count) begin
      do_push();
    end
  endtask
  
  virtual task drain_to_count(int target_count);
    int current_count;
    current_count = depth - target_count;
    repeat(current_count) begin
      do_pop();
    end
  endtask
  
  
  virtual task push_to_overflow();
    fill_to_full();
    do_push();
    `uvm_info("SEQ", "Pushed to full FIFO - overflow expected", UVM_MEDIUM);
  endtask
  
  virtual task pop_to_underflow();
    drain_to_empty();
    do_pop();
    `uvm_info("SEQ", "Popped from empty FIFO - underflow expected", UVM_MEDIUM);
  endtask
  
  virtual task burst_push(int n);
    repeat(n) do_push();
  endtask
  
  virtual task burst_pop(int n);
    repeat(n) do_pop();
  endtask
    
  virtual task check_status();
    bit [31:0] status_val;
    reg_env.reg_block.fifo.status.read(status, status_val);
    `uvm_info("SEQ", $sformatf("STATUS: 0x%0h", status_val), UVM_MEDIUM);
  endtask
  
  virtual task check_empty_flag(bit expected);
    bit [31:0] status_val;
    reg_env.reg_block.fifo.status.read(status, status_val);
    if (status_val[0] != expected) begin
      `uvm_error("SEQ", $sformatf("Empty flag mismatch: expected=%0b got=%0b", expected, status_val[0]));
    end
  endtask
  
  virtual task check_full_flag(bit expected);
    bit [31:0] status_val;
    reg_env.reg_block.fifo.status.read(status, status_val);
    if (status_val[1] != expected) begin
      `uvm_error("SEQ", $sformatf("Full flag mismatch: expected=%0b got=%0b", expected, status_val[1]));
    end
  endtask
  
  virtual task check_overflow_flag(bit expected);
    bit [31:0] status_val;
    reg_env.reg_block.fifo.status.read(status, status_val);
    if (status_val[4] != expected) begin
      `uvm_error("SEQ", $sformatf("Overflow flag mismatch: expected=%0b got=%0b", expected, status_val[4]));
    end else begin
      `uvm_info("SEQ", $sformatf("Overflow flag = %0b", expected), UVM_LOW);
    end
  endtask
  
  virtual task check_underflow_flag(bit expected);
    bit [31:0] status_val;
    reg_env.reg_block.fifo.status.read(status, status_val);
    if (status_val[5] != expected) begin
      `uvm_error("SEQ", $sformatf("Underflow flag mismatch: expected=%0b got=%0b", expected, status_val[5]));
    end else begin
      `uvm_info("SEQ", $sformatf("Underflow flag = %0b", expected), UVM_LOW);
    end
  endtask
  
  virtual task check_count(int expected);
    bit [31:0] status_val;
    int actual_count;  
    reg_env.reg_block.fifo.status.read(status, status_val);
    actual_count = status_val[13:6]; 
    if (actual_count != expected) begin
      `uvm_error("SEQ", $sformatf("Count mismatch: expected=%0d got=%0d", expected, actual_count));
    end
  endtask
    
  virtual task toggle_enable(int n_times);
    repeat(n_times) begin
      disable_fifo();
      enable_fifo();
    end
  endtask
  
  virtual task random_operations();
    bit do_push_op;
    repeat(n_ops) begin
      do_push_op = $urandom_range(0,1);
      if (do_push_op) begin
        do_push();
      end else begin
        do_pop();
      end
    end
  endtask
  
  virtual task stress_thresholds();
    configure_thresholds(depth/2, depth/4);
    repeat(10) begin
      if ($urandom_range(0,1)) begin
        burst_push($urandom_range(1,3));
      end else begin
        burst_pop($urandom_range(1,3));
      end
      check_status();
    end
  endtask
  
endclass

`endif