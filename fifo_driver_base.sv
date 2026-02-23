`ifndef FIFO_DRIVER_BASE_SV
`define FIFO_DRIVER_BASE_SV
`include "uvm_macros.svh"
import uvm_pkg::*;

class fifo_driver_base extends uvm_driver#(fifo_item);
  `uvm_component_utils(fifo_driver_base)
  virtual apb_sync_fifo_if vif;
  
  function new(string n, uvm_component p=null); 
    super.new(n,p); 
  endfunction
  
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual apb_sync_fifo_if)::get(this, "", "vif", vif)) begin
      `uvm_fatal(get_type_name(), "Virtual interface not found in config DB")
    end
  endfunction
  
  task run_phase(uvm_phase phase);
    fifo_item tr;
    forever begin
      seq_item_port.get_next_item(tr);
      drive_one(tr);
      seq_item_port.item_done();
    end
  endtask
  
  virtual task drive_one(fifo_item tr);
    // Idle
    vif.drv_cb.PSEL    <= 0;
    vif.drv_cb.PENABLE <= 0;
    vif.drv_cb.PWRITE  <= 0;
    vif.drv_cb.PADDR   <= 8'h00;
    vif.drv_cb.PWDATA  <= 32'h0;
    
    @(vif.drv_cb);
    
    // Setup phase
    vif.drv_cb.PADDR   <= tr.addr;
    vif.drv_cb.PWDATA  <= tr.data;  
    vif.drv_cb.PWRITE  <= tr.is_write ? 1'b1 : 1'b0;
    vif.drv_cb.PSEL    <= 1;
    vif.drv_cb.PENABLE <= 0;
    
    @(vif.drv_cb);
    
    // Enable phase
    vif.drv_cb.PENABLE <= 1;
    
    // Wait for PREADY
    do begin
        @(vif.drv_cb);  
    end while (vif.drv_cb.PREADY !== 1'b1);
    
    // Capture read data
    if (!tr.is_write) begin
        tr.data = vif.drv_cb.PRDATA;
        `uvm_info(get_type_name(),
                  $sformatf("Read 0x%0h from addr 0x%0h", tr.data, tr.addr),
                  UVM_MEDIUM)
    end
    
    // Return to idle
    vif.drv_cb.PSEL    <= 0;
    vif.drv_cb.PENABLE <= 0;
    vif.drv_cb.PWRITE  <= 0;
  endtask
  
endclass

`endif