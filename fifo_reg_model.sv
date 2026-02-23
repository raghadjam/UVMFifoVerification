`define UVM_REG_ADDR_WIDTH 32

// CTRL register: EN, CLR, DROP_ON_FULL
class ral_fifo_ctrl extends uvm_reg;
  uvm_reg_field en;
  uvm_reg_field clr;
  uvm_reg_field drop_on_full;

  `uvm_object_utils(ral_fifo_ctrl)

  function new(string name = "fifo_ctrl");
    super.new(name, 32, build_coverage(UVM_NO_COVERAGE));
  endfunction

  virtual function void build();
    this.en           = uvm_reg_field::type_id::create("en",, get_full_name());
    this.clr          = uvm_reg_field::type_id::create("clr",, get_full_name());
    this.drop_on_full = uvm_reg_field::type_id::create("drop_on_full",, get_full_name());

    this.en.configure(this, 1, 0, "RW", 0, 1'b0, 1, 0, 1);
    this.clr.configure(this, 1, 1, "RW", 0, 1'b0, 1, 0, 1);
    this.drop_on_full.configure(this, 1, 2, "RW", 0, 1'b0, 1, 0, 1);
  endfunction
endclass

// THRESH register: ALMOST_FULL_TH, ALMOST_EMPTY_TH
class ral_fifo_thresh extends uvm_reg;
  uvm_reg_field almost_full_th;
  uvm_reg_field almost_empty_th;

  `uvm_object_utils(ral_fifo_thresh)

  function new(string name = "fifo_thresh");
    super.new(name, 32, build_coverage(UVM_NO_COVERAGE));
  endfunction

  virtual function void build();
    this.almost_full_th  = uvm_reg_field::type_id::create("almost_full_th",, get_full_name());
    this.almost_empty_th = uvm_reg_field::type_id::create("almost_empty_th",, get_full_name());

    this.almost_full_th.configure(this, 8, 0, "RW", 0, 8'h0, 1, 0, 1);
    this.almost_empty_th.configure(this, 8, 8, "RW", 0, 8'h0, 1, 0, 1);
  endfunction
endclass

class ral_fifo_status extends uvm_reg;
  uvm_reg_field empty;
  uvm_reg_field full;
  uvm_reg_field almost;    
  uvm_reg_field overflow;
  uvm_reg_field underflow;
  uvm_reg_field count;

  `uvm_object_utils(ral_fifo_status)

  function new(string name = "fifo_status");
    super.new(name, 32, build_coverage(UVM_NO_COVERAGE));
  endfunction

  virtual function void build();
    this.empty     = uvm_reg_field::type_id::create("empty",, get_full_name());
    this.full      = uvm_reg_field::type_id::create("full",, get_full_name());
    this.almost    = uvm_reg_field::type_id::create("almost",, get_full_name());   
    this.overflow  = uvm_reg_field::type_id::create("overflow",, get_full_name());
    this.underflow = uvm_reg_field::type_id::create("underflow",, get_full_name());
    this.count     = uvm_reg_field::type_id::create("count",, get_full_name());

    this.empty.configure(this, 1, 0, "RO", 0, 1'b1, 0, 0, 1);
    this.full.configure(this, 1, 1, "RO", 0, 1'b0, 0, 0, 1);
    this.almost.configure(this, 1, 2, "RO", 0, 1'b0, 0, 0, 1);          
    this.overflow.configure(this, 1, 4, "RO", 0, 1'b0, 0, 0, 1);        
    this.underflow.configure(this, 1, 5, "RO", 0, 1'b0, 0, 0, 1);       
    this.count.configure(this, 8, 6, "RO", 0, 4'h0, 0, 0, 1);            
  endfunction
endclass

// DATA register: push/pop
class ral_fifo_data extends uvm_reg;
  uvm_reg_field data;

  `uvm_object_utils(ral_fifo_data)

  function new(string name = "fifo_data");
    super.new(name, 32, build_coverage(UVM_NO_COVERAGE));
  endfunction

  virtual function void build();
    this.data = uvm_reg_field::type_id::create("data",, get_full_name());
    this.data.configure(this, 8, 0, "RW", 0, 8'h0, 1, 0, 1);
  endfunction
endclass


// FIFO Register Block

class ral_block_fifo extends uvm_reg_block;
  rand ral_fifo_ctrl ctrl;
  rand ral_fifo_thresh thresh;
  rand ral_fifo_status status;
  rand ral_fifo_data data;

  `uvm_object_utils(ral_block_fifo)

  function new(string name = "fifo_block");
    super.new(name, build_coverage(UVM_NO_COVERAGE));
  endfunction

  virtual function void build();
    this.default_map = create_map("", 0, 4, UVM_LITTLE_ENDIAN, 0);

    // CTRL at offset 0x00
    this.ctrl = ral_fifo_ctrl::type_id::create("ctrl",, get_full_name());
    this.ctrl.configure(this, null, "");
    this.ctrl.build();
    this.default_map.add_reg(this.ctrl, 32'h00, "RW", 0);

    // THRESH at offset 0x04
    this.thresh = ral_fifo_thresh::type_id::create("thresh",, get_full_name());
    this.thresh.configure(this, null, "");
    this.thresh.build();
    this.default_map.add_reg(this.thresh, 32'h04, "RW", 0);

    // STATUS at offset 0x08
    this.status = ral_fifo_status::type_id::create("status",, get_full_name());
    this.status.configure(this, null, "");
    this.status.build();
    this.default_map.add_reg(this.status, 32'h08, "RO", 0);

    // DATA at offset 0x0C
    this.data = ral_fifo_data::type_id::create("data",, get_full_name());
    this.data.configure(this, null, "");
    this.data.build();
    this.default_map.add_reg(this.data, 32'h0C, "RW", 0);
  endfunction
endclass


class ral_sys_fifo extends uvm_reg_block;
  rand ral_block_fifo fifo;

  `uvm_object_utils(ral_sys_fifo)

  function new(string name = "fifo_sys");
    super.new(name);
  endfunction

  virtual function void build();
    this.default_map = create_map("", 0, 4, UVM_LITTLE_ENDIAN, 0);

    this.fifo = ral_block_fifo::type_id::create("fifo",, get_full_name());
    this.fifo.configure(this, "tb_top.fifo_if"); 
    this.fifo.build();

    this.default_map.add_submap(this.fifo.default_map, 32'h0);
  endfunction
endclass
