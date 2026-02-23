interface apb_sync_fifo_if (input logic clk, input logic reset_n);
  timeunit 1ns; timeprecision 1ps;

// Inputs to DUT
    logic PSEL;
    logic PENABLE;
    logic PWRITE;
    logic [7:0] PADDR;
    logic [31:0] PWDATA;

// Outputs from DUT
    logic [31:0] PRDATA;
    logic PREADY;
    logic PSLVERR;

// Driver: drives on posedge, samples after #1step
    clocking drv_cb @(posedge clk);
        default input #1step output #0;
        output PSEL, PENABLE, PWRITE, PADDR, PWDATA;
        input PRDATA, PREADY, PSLVERR;
    endclocking

// Monitor: purely sampled view
      clocking mon_cb @(posedge clk);
        default input #1step output #0;
        input PSEL, PENABLE, PWRITE, PADDR, PWDATA;
        input PRDATA, PREADY, PSLVERR;
    endclocking

// --------- Modports ----------
  
// For DUT instance 
    modport DUT_mp (
        input PSEL, PENABLE, PWRITE, PADDR, PWDATA,
        output PRDATA, PREADY, PSLVERR
    );

// For UVM driver
    modport drv_mp (
        input PRDATA, PREADY, PSLVERR,
        output PSEL, PENABLE, PWRITE, PADDR, PWDATA
    );

// For UVM monitor
    modport mon_mp (
        input PSEL, PENABLE, PWRITE, PADDR, PWDATA,
        input PRDATA, PREADY, PSLVERR
    );

endinterface