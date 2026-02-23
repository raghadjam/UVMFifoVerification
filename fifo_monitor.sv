class fifo_monitor extends uvm_component;
  `uvm_component_utils(fifo_monitor)
  
  virtual apb_sync_fifo_if vif;
  uvm_analysis_port#(fifo_item) ap;
    
  function new(string n="fifo_monitor", uvm_component p=null);
    super.new(n,p);
  endfunction
  
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if(!uvm_config_db#(virtual apb_sync_fifo_if)::get(this, "", "vif", vif))
      `uvm_fatal(get_type_name(), "Monitor: Virtual interface NOT found")
    ap = new("ap", this);
  endfunction
  
  task run_phase(uvm_phase phase);
    fifo_item tr;
    forever begin
      @(vif.mon_cb);
      if(vif.mon_cb.PSEL && vif.mon_cb.PENABLE && vif.mon_cb.PREADY) begin
        tr = fifo_item::type_id::create("tr");
        tr.addr = vif.mon_cb.PADDR;
        tr.is_write = vif.mon_cb.PWRITE;
        
        if(tr.is_write) begin
          tr.data = vif.mon_cb.PWDATA;
          case(tr.addr)
            8'h00: begin
              tr.enable       = vif.mon_cb.PWDATA[0];
              tr.clear        = vif.mon_cb.PWDATA[1];
              tr.drop_on_full = vif.mon_cb.PWDATA[2];
            end
            8'h04: begin
              tr.almost_full_th  = vif.mon_cb.PWDATA[7:0];
              tr.almost_empty_th = vif.mon_cb.PWDATA[15:8];
            end
            8'h0C: begin
              tr.data = vif.mon_cb.PWDATA[7:0];
            end
          endcase
        end else begin
          tr.data = vif.mon_cb.PRDATA;
          case(tr.addr)
            8'h00: begin
              tr.enable       = vif.mon_cb.PRDATA[0];
              tr.clear        = vif.mon_cb.PRDATA[1];
              tr.drop_on_full = vif.mon_cb.PRDATA[2];
            end
            8'h04: begin
              tr.almost_full_th  = vif.mon_cb.PRDATA[7:0];
              tr.almost_empty_th = vif.mon_cb.PRDATA[15:8];
            end
            8'h08: begin
              tr.empty     = vif.mon_cb.PRDATA[0];
              tr.full      = vif.mon_cb.PRDATA[1];
              tr.almost    = vif.mon_cb.PRDATA[2] | vif.mon_cb.PRDATA[3];
              tr.overflow  = vif.mon_cb.PRDATA[4];
              tr.underflow = vif.mon_cb.PRDATA[5];
              tr.count     = vif.mon_cb.PRDATA[13:6]; 
            end
            8'h0C: begin
              tr.data = vif.mon_cb.PRDATA[7:0];
            end
          endcase
        end
        
        `uvm_info(get_type_name(),
                  $sformatf("MONITOR: addr=0x%0h write=%0b data=0x%0h",
                            tr.addr, tr.is_write, tr.data), UVM_NONE)
        ap.write(tr);
      end
    end
  endtask
endclass