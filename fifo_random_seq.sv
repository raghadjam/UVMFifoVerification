`ifndef FIFO_SEQ_RANDOM_SV
`define FIFO_SEQ_RANDOM_SV
`include "uvm_macros.svh"
import uvm_pkg::*;

class fifo_seq_random extends fifo_seq_base;
  `uvm_object_utils(fifo_seq_random)
  
  function new(string name="fifo_seq_random");
    super.new(name);
  endfunction
  
  virtual task body();
    int op;
    bit [31:0] status_data;
     
    // Initialize FIFO
    init_fifo();
    
    // Randomly configure DROP_ON_FULL
    reg_env.reg_block.fifo.ctrl.drop_on_full.write(status, $urandom_range(0,1));
    
    // Randomly configure thresholds
    reg_env.reg_block.fifo.thresh.almost_full_th.write(status, $urandom_range(1, depth));
    reg_env.reg_block.fifo.thresh.almost_empty_th.write(status, $urandom_range(0, depth-1));
    
    // Random EN=0 edge case
    if ($urandom_range(0,2) == 0) begin
      reg_env.reg_block.fifo.ctrl.en.write(status, 0);
      repeat($urandom_range(1,5)) do_push();
      repeat($urandom_range(1,5)) do_pop();
      reg_env.reg_block.fifo.ctrl.en.write(status, 1);
    end
    
    // Random fill scenarios
    case($urandom_range(0,3))
      0: begin
        fill_to_full();
        // Random push on full
        if ($urandom_range(0,1)) begin
          repeat($urandom_range(1,3)) do_push();
        end
      end
      1: begin
        repeat($urandom_range(1, depth-1)) do_push();
      end
      2: begin
        // Trigger underflow
        repeat($urandom_range(1,3)) do_pop();
      end
      3: begin
        fill_to_full();
        drain_to_empty();
        repeat($urandom_range(1,3)) do_pop(); // underflow
      end
    endcase
    
    // Random CLR 
    repeat($urandom_range(2,5)) begin
      if ($urandom_range(0,3) == 0) begin
        reg_env.reg_block.fifo.ctrl.clr.write(status, 1);
        reg_env.reg_block.fifo.ctrl.en.write(status, 1);
      end
    end
    
    // Random operations
    repeat(n_ops) begin
      op = $urandom_range(0,6);
      case(op)
        0: do_push();
        1: do_pop();
        2: do_both();
        
        3: begin // Random ctrl changes
          case($urandom_range(0,2))
            0: reg_env.reg_block.fifo.ctrl.en.write(status, $urandom_range(0,1));
            1: reg_env.reg_block.fifo.ctrl.clr.write(status, 1);
            2: reg_env.reg_block.fifo.ctrl.drop_on_full.write(status, $urandom_range(0,1));
          endcase
        end
        
        4: begin // Random threshold changes
          reg_env.reg_block.fifo.thresh.almost_full_th.write(status, $urandom_range(1, depth));
          reg_env.reg_block.fifo.thresh.almost_empty_th.write(status, $urandom_range(0, depth-1));
        end
        
        5: check_status();
        
        6: begin // Random operations
          if ($urandom_range(0,1)) begin
            repeat($urandom_range(1, depth+5)) do_push();
          end else begin
            repeat($urandom_range(1, depth+5)) do_pop();
          end
        end
      endcase
      
      // Randomly check status during operations
      if ($urandom_range(0,9) == 0) begin
        check_status();
      end
    end
    
    // rapid enable/disable
    repeat(10) begin
      reg_env.reg_block.fifo.ctrl.en.write(status, 0);
      if ($urandom_range(0,1)) do_push();
      reg_env.reg_block.fifo.ctrl.en.write(status, 1);
      if ($urandom_range(0,1)) do_push();
    end
    
    // change thresholds randomly
    init_fifo();
    reg_env.reg_block.fifo.thresh.almost_full_th.write(status, depth/2);
    reg_env.reg_block.fifo.thresh.almost_empty_th.write(status, depth/4);
    
    repeat(20) begin
      if ($urandom_range(0,1)) begin
        repeat($urandom_range(1,3)) do_push();
      end else begin
        repeat($urandom_range(1,3)) do_pop();
      end
      check_status();
    end
        check_status();
  endtask
  
endclass

`endif