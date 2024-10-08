// Code your testbench here
// or browse Examples
`include "uvm_macros.svh"
import uvm_pkg::*;
`timescale 1ns/1ps


// // transaction class 
class transaction extends uvm_sequence_item;
  rand bit d;
  rand bit reset;
  bit q;
  
  function new(string path="transaction");
    super.new(path);
  endfunction
  `uvm_object_utils_begin(transaction)
  `uvm_field_int(d, UVM_DEFAULT)
  `uvm_field_int(reset, UVM_DEFAULT)
  `uvm_field_int(q, UVM_DEFAULT)
  `uvm_object_utils_end
endclass

// //sequence class which generates the stimulus the sequence of transactions
class reset_case extends uvm_sequence#(transaction);
  `uvm_object_utils(reset_case);
  transaction tr;
  function new(string path="reset_case");
    super.new(path);
  endfunction
  virtual task body();
    repeat(15)
    begin
      tr=transaction::type_id::create("tr");
      start_item(tr);
      assert(tr.randomize());
      tr.reset=1;
      `uvm_info("RST",$sformatf("sequence d:%0d , reset:%0d , q:%0d is created",tr.d,tr.reset,tr.q),UVM_NONE);
        finish_item(tr);
         end
  endtask
  endclass

class normal_case extends uvm_sequence#(transaction);
  `uvm_object_utils(normal_case);
  transaction tr;
  function new(string path="normal_case");
    super.new(path);
  endfunction
  virtual task body();
    repeat(15)
    begin
      tr=transaction::type_id::create("tr");
      start_item(tr);
      assert(tr.randomize());
      tr.reset=0;
      `uvm_info("NORM",$sformatf("sequence d:%0d , reset:%0d , q:%0d is created",tr.d,tr.reset,tr.q),UVM_NONE);
        finish_item(tr);
         end
  endtask
  endclass

// //driver sends the stimulus to the DUT via interface

class driver extends uvm_driver#(transaction);
  `uvm_component_utils(driver)
  transaction tr;
  virtual dff_if dif;
  
  function new(string path="driver",uvm_component parent);
    super.new(path,parent);
    endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    if(!uvm_config_db#(virtual dff_if)::get(this,"","dif",dif))
      `uvm_error("drv","Unable to access Interface");
  endfunction
  
  virtual task run_phase(uvm_phase phase);
    tr = transaction::type_id::create("tr");
    forever begin
      seq_item_port.get_next_item(tr);
      dif.d<=tr.d;
      dif.reset<=tr.reset;
      `uvm_info("DRV",$sformatf(" d:%0d , reset:%0d , q:%0d is sent to the DUT",tr.d,tr.reset,tr.q),UVM_NONE);
      seq_item_port.item_done();

      repeat(2) @(posedge dif.clk);
    end
  endtask
endclass

// // Monitor gets data from DUT and sends it to the scoreboard

class monitor extends uvm_monitor;
  `uvm_component_utils(monitor)
  
  transaction tr;
  virtual dff_if dif;
  uvm_analysis_port#(transaction) send;
  
  function new(string path="monitor",uvm_component parent);
    super.new(path,parent);
    endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
     send=new("send",this);
    tr=transaction::type_id::create("tr");
    if(!uvm_config_db#(virtual dff_if)::get(this,"","dif",dif))
      `uvm_error("drv","Unable to access Interface");
  endfunction
  
  virtual task run_phase(uvm_phase phase);
    forever begin

      repeat(2) @(posedge dif.clk);
      tr.d=dif.d;
      tr.reset=dif.reset;
      tr.q=dif.q;
      `uvm_info("MON",$sformatf(" d:%0d , reset:%0d , q:%0d is sent to the scoreboard",tr.d,tr.reset,tr.q),UVM_NONE);
      send.write(tr);
    end
  endtask
endclass

// // scoreboard gets the output data from monitor and checks if it is correct


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
    `uvm_info("MON",$sformatf(" d:%0d , reset:%0d , q:%0d is received from the  monitor",tr.d,tr.reset,tr.q),UVM_NONE);
    if (tr.reset == 1) begin
      if (tr.q == 0)
      `uvm_info("SCO", "Test Case Passed", UVM_NONE)
    else
      `uvm_info("SCO", "Test Failed", UVM_NONE)
      end else if (tr.reset == 0) begin
        if (tr.q == tr.d)
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
      
//  // Environment contains the agent and scoreboard . We also connect the monitor to the scoreboard
    
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
    
// // Test here we run our testbench
    
    class test extends uvm_test;
      `uvm_component_utils(test);
      function new(string path="test",uvm_component parent);
    super.new(path,parent);
    endfunction
      
    reset_case r;
    normal_case n;
    env e;
    
      virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        r=reset_case::type_id::create("r",this);
        n=normal_case::type_id::create("n",this);
        e=env::type_id::create("e",this);
      endfunction
      
      virtual task run_phase(uvm_phase phase);
        phase.raise_objection(this);
        r.start(e.a.seqr);
        #50;
        n.start(e.a.seqr);
        phase.drop_objection(this);
      endtask
    endclass
    
    
//test bench module
    module tb();
      
      dff_if dif();
      
      d_flipflop dut(.clk(dif.clk),.d(dif.d),.reset(dif.reset),.q(dif.q));
      
  
      initial begin
        uvm_config_db #(virtual dff_if)::set(null,"*","dif",dif);
        run_test("test");
      end
      initial begin
      dif.clk=0;
      end
      always #10 dif.clk=~dif.clk;
      initial begin
    $dumpfile("dump.vcd");
    $dumpvars;
  end
  
endmodule
    
