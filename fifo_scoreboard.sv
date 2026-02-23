`ifndef FIFO_SCOREBOARD_UPGRADE_SV
`define FIFO_SCOREBOARD_UPGRADE_SV

class fifo_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(fifo_scoreboard)

  uvm_analysis_imp #(fifo_item, fifo_scoreboard) monitor_imp;

  // Reference FIFO model
  bit [7:0] ref_fifo_queue[$];
  int ref_count = 0;
  bit ref_empty = 1;
  bit ref_full = 0;
  bit ref_almost = 0;
  bit ref_overflow = 0;  
  bit ref_underflow = 0;  
  int max_depth = 16;
  
  bit fifo_enabled = 0;
  bit drop_on_full = 0;

  int ref_almost_full_th = 0;
  int ref_almost_empty_th = 0;
  
  int en_toggle_count = 0;
  int en_disabled_ops = 0;
  int clr_count = 0;
  int push_count = 0;
  int pop_count = 0;
  int overflow_triggered = 0;
  int underflow_triggered = 0;
  int drop_on_full_toggles = 0;
  int threshold_configs = 0;
  int status_checks = 0;
  
  int status_errors = 0;
  int data_errors = 0;

  function new(string name="fifo_scoreboard", uvm_component parent=null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    monitor_imp = new("monitor_imp", this);
  endfunction

  function void write(fifo_item tr);
    `uvm_info(get_type_name(),
              $sformatf("SB RX: addr=0x%0h write=%0b data=0x%0h",
                        tr.addr, tr.is_write, tr.data),
              UVM_LOW)
    check_transaction(tr);
  endfunction

  function void check_transaction(fifo_item tr);
    case(tr.addr)
      8'h00: handle_ctrl_reg(tr);
      8'h04: handle_thresh_reg(tr);
      8'h08: handle_status_reg(tr);
      8'h0C: handle_data_reg(tr);
      default: `uvm_error(get_type_name(), $sformatf("Unknown address: 0x%0h", tr.addr))
    endcase
  endfunction

  function void handle_ctrl_reg(fifo_item tr);
    if (tr.is_write) begin
      // Track enable/disable
      if (tr.enable != fifo_enabled) begin
        en_toggle_count++;
        `uvm_info(get_type_name(), 
                  $sformatf("EN toggled to %0b (count=%0d)", tr.enable, en_toggle_count),
                  UVM_MEDIUM)
      end
      fifo_enabled = tr.enable;
      
      // Clear handling
      if (tr.clear) begin
        clr_count++;
        ref_fifo_queue.delete();
        ref_count = 0;
        ref_empty = 1;
        ref_full = 0;
        ref_overflow = 0;   
        ref_underflow = 0;
        update_almost_flag();
        `uvm_info(get_type_name(), 
                  $sformatf("FIFO cleared (count=%0d, sticky flags reset)", clr_count),
                  UVM_MEDIUM)
      end
      
      // DROP_ON_FULL tracking
      if (tr.drop_on_full != drop_on_full) begin
        drop_on_full_toggles++;
        `uvm_info(get_type_name(), 
                  $sformatf("DROP_ON_FULL=%0b (count=%0d)", tr.drop_on_full, drop_on_full_toggles),
                  UVM_MEDIUM)
      end
      drop_on_full = tr.drop_on_full;
      
      `uvm_info(get_type_name(),
                $sformatf("CTRL UPDATE: en=%0b clear=%0b drop_on_full=%0b", 
                          fifo_enabled, tr.clear, drop_on_full),
                UVM_MEDIUM)
    end
  endfunction

  // Threshold register
  function void handle_thresh_reg(fifo_item tr);
    if (tr.is_write) begin
      threshold_configs++;
      ref_almost_full_th  = tr.almost_full_th;
      ref_almost_empty_th = tr.almost_empty_th;

      `uvm_info(get_type_name(),
                $sformatf("THRESH configured (count=%0d): AF_TH=%0d AE_TH=%0d", 
                          threshold_configs, ref_almost_full_th, ref_almost_empty_th),
                UVM_MEDIUM)
      
      // Update almost flag based on new thresholds
      update_almost_flag();
    end
  endfunction

  // Status register
  function void handle_status_reg(fifo_item tr);
    bit act_empty;
    bit act_full;
    bit act_almost;
    bit act_overflow;
    bit act_underflow;
    int act_count;
    
    if (!tr.is_write) begin
      status_checks++;
      
      act_empty     = tr.empty;
      act_full      = tr.full;
      act_almost    = tr.almost;
      act_overflow  = tr.overflow;
      act_underflow = tr.underflow;
      act_count     = tr.count;

      `uvm_info(get_type_name(),
                $sformatf("STATUS check #%0d", status_checks),
                UVM_MEDIUM)

      // Compare with reference model
      if ((act_empty !== ref_empty) || 
          (act_full !== ref_full) ||
          (act_almost !== ref_almost) ||
          (act_overflow !== ref_overflow) ||
          (act_underflow !== ref_underflow) ||
          (act_count !== ref_count)) begin
        status_errors++;
        `uvm_error(get_type_name(),
          $sformatf("STATUS MISMATCH (#%0d)!\nExpected: empty=%0b full=%0b almost=%0b overflow=%0b underflow=%0b count=%0d\nActual:   empty=%0b full=%0b almost=%0b overflow=%0b underflow=%0b count=%0d",
                    status_errors,
                    ref_empty, ref_full, ref_almost, ref_overflow, ref_underflow, ref_count,
                    act_empty, act_full, act_almost, act_overflow, act_underflow, act_count))
      end else begin
        `uvm_info(get_type_name(),
                  $sformatf("STATUS PASS: empty=%0b full=%0b almost=%0b ovf=%0b unf=%0b count=%0d",
                            act_empty, act_full, act_almost, act_overflow, act_underflow, act_count),
                  UVM_LOW)
      end
      
      // Track sticky flag 
      if (ref_overflow && act_overflow) begin
        `uvm_info(get_type_name(), "Overflow flag correctly sticky", UVM_MEDIUM)
      end
      if (ref_underflow && act_underflow) begin
        `uvm_info(get_type_name(), "Underflow flag correctly sticky", UVM_MEDIUM)
      end
    end
  endfunction

  // Data register (push/pop)
  function void handle_data_reg(fifo_item tr);
    bit [7:0] expected_data; 
    
    if (tr.is_write) begin
      // PUSH operation
      push_count++;
      `uvm_info(get_type_name(), $sformatf("PUSH #%0d", push_count), UVM_MEDIUM)
      
      // Check if EN=0
      if (!fifo_enabled) begin
        en_disabled_ops++;
        `uvm_info(get_type_name(), 
                  $sformatf("Push while EN=0 (#%0d)", en_disabled_ops),
                  UVM_MEDIUM)
        return; 
      end

      // Check if full
      if (ref_full) begin
        overflow_triggered++;
        ref_overflow = 1;  
        
        if (drop_on_full) begin
          `uvm_info(get_type_name(), 
                    $sformatf("Push to full with DROP_ON_FULL=1 - data 0x%0h dropped (ovf #%0d)", 
                              tr.data[7:0], overflow_triggered),
                    UVM_MEDIUM)
        end else begin
          `uvm_info(get_type_name(), 
                    $sformatf("Push to full with DROP_ON_FULL=0 - OVERFLOW (ovf #%0d)", 
                              overflow_triggered),
                    UVM_MEDIUM)
        end
      end else begin
        // Normal push
        ref_fifo_queue.push_back(tr.data[7:0]);
        ref_count++;
        ref_empty = 0;
        ref_full = (ref_count >= max_depth);
        update_almost_flag();
        
        `uvm_info(get_type_name(),
                  $sformatf("REF PUSH: data=0x%0h count=%0d empty=%0b full=%0b almost=%0b", 
                            tr.data[7:0], ref_count, ref_empty, ref_full, ref_almost),
                  UVM_MEDIUM)
      end
      
    end else begin
      // POP operation
      pop_count++;
      `uvm_info(get_type_name(), $sformatf("POP #%0d", pop_count), UVM_MEDIUM)
      
      // Check if EN=0
      if (!fifo_enabled) begin
        en_disabled_ops++;
        `uvm_info(get_type_name(), 
                  $sformatf("Pop while EN=0 (#%0d)", en_disabled_ops),
                  UVM_MEDIUM)
        return;  
      end

      // Check if empty
      if (ref_empty) begin
        underflow_triggered++;
        ref_underflow = 1; 
        `uvm_info(get_type_name(), 
                  $sformatf("Pop from empty - UNDERFLOW (unf #%0d)", underflow_triggered),
                  UVM_MEDIUM)
      end else begin
        expected_data = ref_fifo_queue.pop_front();
        ref_count--;
        ref_empty = (ref_count == 0);
        ref_full = 0;
        update_almost_flag();

        if (tr.data[7:0] !== expected_data) begin
          data_errors++;
          `uvm_error(get_type_name(),
            $sformatf("DATA MISMATCH (#%0d)! Expected=0x%0h Got=0x%0h count=%0d", 
                      data_errors, expected_data, tr.data[7:0], ref_count))
        end else begin
          `uvm_info(get_type_name(),
                    $sformatf("POP PASS: data=0x%0h count=%0d empty=%0b full=%0b almost=%0b", 
                              tr.data[7:0], ref_count, ref_empty, ref_full, ref_almost), 
                    UVM_LOW)
        end
      end
    end
  endfunction

  function void update_almost_flag();
    ref_almost = (ref_count >= ref_almost_full_th) || (ref_count <= ref_almost_empty_th);
  endfunction
  
  function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    
    `uvm_info(get_type_name(), "========================================", UVM_NONE)
    `uvm_info(get_type_name(), "   FUNCTIONAL VERIFICATION SUMMARY", UVM_NONE)
    `uvm_info(get_type_name(), "========================================", UVM_NONE)
    
    `uvm_info(get_type_name(), "FIFO Operations Depend on EN", UVM_NONE)
    `uvm_info(get_type_name(), $sformatf("  - EN toggles:           %0d", en_toggle_count), UVM_NONE)
    `uvm_info(get_type_name(), $sformatf("  - Ops while EN=0:       %0d", en_disabled_ops), UVM_NONE)
    
    `uvm_info(get_type_name(), "CLR Clears FIFO & Sticky Flags", UVM_NONE)
    `uvm_info(get_type_name(), $sformatf("  - CLR operations:       %0d", clr_count), UVM_NONE)
    
    `uvm_info(get_type_name(), "Push/Pop Operations", UVM_NONE)
    `uvm_info(get_type_name(), $sformatf("  - Push operations:      %0d", push_count), UVM_NONE)
    `uvm_info(get_type_name(), $sformatf("  - Pop operations:       %0d", pop_count), UVM_NONE)
    
    `uvm_info(get_type_name(), "Sticky Overflow/Underflow", UVM_NONE)
    `uvm_info(get_type_name(), $sformatf("  - Overflow triggered:   %0d times", overflow_triggered), UVM_NONE)
    `uvm_info(get_type_name(), $sformatf("  - Underflow triggered:  %0d times", underflow_triggered), UVM_NONE)
    
    `uvm_info(get_type_name(), "DROP_ON_FULL Behavior", UVM_NONE)
    `uvm_info(get_type_name(), $sformatf("  - DROP_ON_FULL toggles: %0d", drop_on_full_toggles), UVM_NONE)
    
    `uvm_info(get_type_name(), "Threshold Configuration", UVM_NONE)
    `uvm_info(get_type_name(), $sformatf("  - Threshold configs:    %0d", threshold_configs), UVM_NONE)
    `uvm_info(get_type_name(), $sformatf("  - STATUS checks:        %0d", status_checks), UVM_NONE)
    
    `uvm_info(get_type_name(), "ERROR SUMMARY", UVM_NONE)
    `uvm_info(get_type_name(), $sformatf("  - STATUS mismatches:    %0d", status_errors), UVM_NONE)
    `uvm_info(get_type_name(), $sformatf("  - DATA mismatches:      %0d", data_errors), UVM_NONE)
    
    `uvm_info(get_type_name(), "========================================", UVM_NONE)
  endfunction

endclass : fifo_scoreboard

`endif