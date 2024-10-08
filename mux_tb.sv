// Code your testbench here
// or browse Examples
`include "uvm_macros.svh"
import uvm_pkg::*;
`timescale 1ns/1ps


// transaction class 
class transaction extends uvm_sequence_item;
  rand bit [3:0] ip1;
  rand bit [3:0] ip2;
  rand bit [3:0] ip3;
  rand bit [3:0] ip4;
  rand bit [1:0] sel;
  bit [3:0] out;
  
  function new(string path="transaction");
    super.new(path);
  endfunction
  `uvm_object_utils_begin(transaction)
  `uvm_field_int(ip1, UVM_DEFAULT)
  `uvm_field_int(ip2, UVM_DEFAULT)
  `uvm_field_int(ip3, UVM_DEFAULT)
  `uvm_field_int(ip4, UVM_DEFAULT)
  `uvm_field_int(sel, UVM_DEFAULT)
  `uvm_field_int(out, UVM_DEFAULT)
  `uvm_object_utils_end
endclass

//sequence class which generates the stimulus the sequence of transactions
class seq extends uvm_sequence#(transaction);
  `uvm_object_utils(seq);
  transaction tr;
  function new(string path="seq");
    super.new(path);
  endfunction
  virtual task body();
    repeat(15)
    begin
      tr=transaction::type_id::create("tr");
      start_item(tr);
      assert(tr.randomize());
      `uvm_info("SEQ",$sformatf("sequence ip1:%0d ip2:%0d ip3:%0d ip4:%0d sel:%0d out:%0d is created",tr.ip1,tr.ip2,tr.ip3,tr.ip4,tr.sel,tr.out),UVM_NONE);
        finish_item(tr);
         end
  endtask
  endclass

//driver sends the stimulus to the DUT via interface

class driver extends uvm_driver#(transaction);
  `uvm_component_utils(driver)
  transaction tr;
  virtual mux_if mif;
  
  function new(string path="driver",uvm_component parent);
    super.new(path,parent);
    endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
     if(!uvm_config_db#(virtual mux_if)::get(this,"","mif",mif))
      `uvm_error("drv","Unable to access Interface");
  endfunction
  
  virtual task run_phase(uvm_phase phase);
    tr = transaction::type_id::create("tr");
    forever begin
      seq_item_port.get_next_item(tr);
      mif.ip1<=tr.ip1;
      mif.ip2<=tr.ip2;
      mif.ip3<=tr.ip3;
      mif.ip4<=tr.ip4;
      mif.sel<=tr.sel;
      `uvm_info("DRV",$sformatf("ip1:%0d ip2:%0d ip3:%0d ip4:%0d sel:%0d out:%0d is is sent to the DUT",tr.ip1,tr.ip2,tr.ip3,tr.ip4,tr.sel,tr.out),UVM_NONE);
      seq_item_port.item_done();
      #20;
    end
  endtask
endclass

// Monitor gets data from DUT and sends it to the scoreboard

class monitor extends uvm_monitor;
  `uvm_component_utils(monitor)
  
  transaction tr;
  virtual mux_if mif;
  uvm_analysis_port#(transaction) send;
  
  function new(string path="monitor",uvm_component parent);
    super.new(path,parent);
    endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
     send=new("send",this);
    tr=transaction::type_id::create("tr");
     if(!uvm_config_db#(virtual mux_if)::get(this,"","mif",mif))
      `uvm_error("drv","Unable to access Interface");
  endfunction
  
  virtual task run_phase(uvm_phase phase);
    forever begin
      #20;
      tr.ip1=mif.ip1;
      tr.ip2=mif.ip2;
      tr.ip3=mif.ip3;
      tr.ip4=mif.ip4;
      tr.sel=mif.sel;
      tr.out=mif.out;
      `uvm_info("MON",$sformatf("ip1:%0d ip2:%0d ip3:%0d ip4:%0d sel:%0d out:%0d  is sent to the scoreboard",tr.ip1,tr.ip2,tr.ip3,tr.ip4,tr.sel,tr.out),UVM_NONE);
      send.write(tr);
    end
  endtask
endclass

// scoreboard gets the output data from monitor and checks if it is correct


class scoreboard extends uvm_scoreboard;
  `uvm_component_utils(scoreboard)
  transaction tr;
  uvm_analysis_imp#(transaction,scoreboard) recv;
  
  function new(string path="scoreboard",uvm_component parent);
    super.new(path,parent);
    endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    recv=new("recv",this);
  endfunction
  
  function void write(input transaction t);
    tr=t;
    `uvm_info("SCO",$sformatf("ip1:%0d ip2:%0d ip3:%0d ip4:%0d sel:%0d out:%0d  is recieved from Monitor",tr.ip1,tr.ip2,tr.ip3,tr.ip4,tr.sel,tr.out),UVM_NONE);
   if (tr.sel == 0) begin
    if (tr.out == tr.ip1)
      `uvm_info("SCO", "Test Case Passed", UVM_NONE)
    else
      `uvm_info("SCO", "Test Failed", UVM_NONE)
  end else if (tr.sel == 1) begin
    if (tr.out == tr.ip2)
      `uvm_info("SCO", "Test Case Passed", UVM_NONE)
    else
      `uvm_info("SCO", "Test Failed", UVM_NONE)
  end else if (tr.sel == 2) begin
    if (tr.out == tr.ip3)
      `uvm_info("SCO", "Test Case Passed", UVM_NONE)
    else
      `uvm_info("SCO", "Test Failed", UVM_NONE)
  end else if (tr.sel == 3) begin
    if (tr.out == tr.ip4)
      `uvm_info("SCO", "Test Case Passed", UVM_NONE)
    else
      `uvm_info("SCO", "Test Failed", UVM_NONE)
  end
    
  endfunction
  
endclass

//agent contains sequence sequencer driver and monitor connects sequencer with driver
      class agent extends uvm_agent;
        `uvm_component_utils(agent)
        driver d;
        monitor m;
        uvm_sequencer#(transaction) seqr;
        function new(string path="agent",uvm_component parent);
    super.new(path,parent);
    endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    d=driver::type_id::create("d",this);
    m=monitor::type_id::create("m",this);
    seqr=uvm_sequencer #(transaction)::type_id::create("s",this);
  endfunction
        
        virtual function void connect_phase(uvm_phase phase);
          super.connect_phase(phase);
          d.seq_item_port.connect(seqr.seq_item_export);
          
        endfunction
        
      endclass
      
 // Environment contains the agent and scoreboard . We also connect the monitor to the scoreboard
    
    class env extends uvm_env;
      `uvm_component_utils(env)
      agent a;
      scoreboard s;
      function new(string path="env",uvm_component parent);
    super.new(path,parent);
    endfunction
  
 virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    a=agent::type_id::create("a",this);
    s=scoreboard::type_id::create("s",this);
  endfunction
        
       virtual function void connect_phase(uvm_phase phase);
          super.connect_phase(phase);
          a.m.send.connect(s.recv);
          
        endfunction
    endclass
    
// Test here we run our testbench
    
    class test extends uvm_test;
      `uvm_component_utils(test);
      function new(string path="test",uvm_component parent);
    super.new(path,parent);
    endfunction
      
    seq s1;
    env e;
    
      virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        s1=seq::type_id::create("s1",this);
        e=env::type_id::create("e",this);
      endfunction
      
      virtual task run_phase(uvm_phase phase);
        phase.raise_objection(this);
        s1.start(e.a.seqr);
        #50;
        phase.drop_objection(this);
      endtask
    endclass
    
    
//test bench module
    module tb();
      
      mux_if mif();
      
      mux dut(.ip1(mif.ip1),.ip2(mif.ip2),.ip3(mif.ip3),.ip4(mif.ip4),.sel(mif.sel),.out(mif.out));
      initial begin
        uvm_config_db #(virtual mux_if)::set(null,"*","mif",mif);
        run_test("test");
      end
      
      initial begin
    $dumpfile("dump.vcd");
    $dumpvars;
  end
  
endmodule
    
