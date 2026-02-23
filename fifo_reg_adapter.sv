// fifo_reg2apb_adapter.sv
class fifo_reg2apb_adapter extends uvm_reg_adapter;
   `uvm_object_utils(fifo_reg2apb_adapter)

   function new(string name = "fifo_reg2apb_adapter");
      super.new(name);
   endfunction

   // Convert register transaction to APB bus transaction
   virtual function uvm_sequence_item reg2bus(const ref uvm_reg_bus_op rw);
      fifo_item pkt = fifo_item::type_id::create("pkt");

      pkt.is_write = (rw.kind == UVM_WRITE); // 1 = write, 0 = read
      pkt.addr     = rw.addr;
      pkt.data     = rw.data;

      `uvm_info("adapter", $sformatf("reg2bus addr=0x%0h data=0x%0h kind=%s",
                                     pkt.addr, pkt.data, rw.kind.name), UVM_DEBUG)
      return pkt;
   endfunction

   // Convert APB bus transaction to register transaction
   virtual function void bus2reg(uvm_sequence_item bus_item, ref uvm_reg_bus_op rw);
      fifo_item pkt;
      if (! $cast(pkt, bus_item)) begin
         `uvm_fatal("fifo_reg2apb_adapter", "Failed to cast bus_item to fifo_item")
      end

      rw.kind = pkt.is_write ? UVM_WRITE : UVM_READ;
      rw.addr = pkt.addr;
      rw.data = pkt.data;

      `uvm_info("adapter", $sformatf("bus2reg addr=0x%0h data=0x%0h kind=%s status=%s",
                                     rw.addr, rw.data, rw.kind.name(), rw.status.name()), UVM_DEBUG)
   endfunction
endclass

// Register Environment
class fifo_reg_env extends uvm_env;
  `uvm_component_utils(fifo_reg_env)
  
  function new(string name="fifo_reg_env", uvm_component parent=null);
    super.new(name, parent);
  endfunction
  
  ral_sys_fifo       reg_block;   
  fifo_reg2apb_adapter adapter;   
  uvm_reg_predictor #(fifo_item) predictor; 
  fifo_agent          agent;       

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    reg_block = ral_sys_fifo::type_id::create("reg_block", this);
    adapter   = fifo_reg2apb_adapter::type_id::create("adapter");
    predictor = uvm_reg_predictor #(fifo_item)::type_id::create("predictor", this);

    reg_block.build();
    reg_block.lock_model();

  endfunction

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);

    predictor.map     = reg_block.default_map;
    predictor.adapter = adapter;

  endfunction
endclass

