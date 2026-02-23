`ifndef FIFO_ITEM_SV
`define FIFO_ITEM_SV
`include "uvm_macros.svh"
import uvm_pkg::*;

class fifo_item extends uvm_sequence_item;
  // Address and data
  rand bit [7:0]  addr;      
  rand bit [31:0] data;    
  rand bit        is_write; 
  
  // Control register bits 
  rand bit enable;
  rand bit clear;
  rand bit drop_on_full;
  
  // Threshold register
  rand bit [7:0] almost_full_th;
  rand bit [7:0] almost_empty_th;
  
  // Status flags
  bit empty;
  bit full;
  bit almost;
  bit overflow;
  bit underflow;
  bit [3:0] count;
  
  constraint valid_addr_c {
    addr inside {8'h00, 8'h04, 8'h08, 8'h0C};
  }
  
  constraint valid_thresh_c {
    almost_full_th <= 16;
    almost_empty_th <= 16;
  }
  
  `uvm_object_utils_begin(fifo_item)
  `uvm_field_int(addr, UVM_ALL_ON)
  `uvm_field_int(data, UVM_ALL_ON)
  `uvm_field_int(is_write, UVM_ALL_ON)
  `uvm_field_int(enable, UVM_ALL_ON)
  `uvm_field_int(clear, UVM_ALL_ON)
  `uvm_field_int(drop_on_full, UVM_ALL_ON)
  `uvm_field_int(almost_full_th, UVM_ALL_ON)
  `uvm_field_int(almost_empty_th, UVM_ALL_ON)
  `uvm_field_int(empty, UVM_DEFAULT)
  `uvm_field_int(full, UVM_DEFAULT)
  `uvm_field_int(almost, UVM_DEFAULT)
  `uvm_field_int(overflow, UVM_DEFAULT)
  `uvm_field_int(underflow, UVM_DEFAULT)
  `uvm_field_int(count, UVM_DEFAULT)
  `uvm_object_utils_end
  
  function new(string name = "fifo_item");
    super.new(name);
  endfunction
  
  function void do_print(uvm_printer printer);
    super.do_print(printer);
    printer.print_field_int("addr", addr, 8, UVM_HEX);
    printer.print_field_int("data", data, 32, UVM_HEX);
    printer.print_field_int("is_write", is_write, 1, UVM_BIN);
    printer.print_field_int("enable", enable, 1, UVM_BIN);
    printer.print_field_int("clear", clear, 1, UVM_BIN);
    printer.print_field_int("drop_on_full", drop_on_full, 1, UVM_BIN);
    printer.print_field_int("almost_full_th", almost_full_th, 8, UVM_DEC);
    printer.print_field_int("almost_empty_th", almost_empty_th, 8, UVM_DEC);
    printer.print_field_int("empty", empty, 1, UVM_BIN);
    printer.print_field_int("full", full, 1, UVM_BIN);
    printer.print_field_int("almost", almost, 1, UVM_BIN);
    printer.print_field_int("overflow", overflow, 1, UVM_BIN);
    printer.print_field_int("underflow", underflow, 1, UVM_BIN);
    printer.print_field_int("count", count, 4, UVM_DEC);
  endfunction
  
endclass : fifo_item

`endif