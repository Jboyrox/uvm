// // Code your testbench here
// // or browse Examples
`include "uvm_macros.svh"
import uvm_pkg::*;
`timescale 1ns/1ps


// // transaction class 
class transaction extends uvm_sequence_item;
  rand bit din;
  rand bit resetn;
  bit dout;
  
  function new(string path="transaction");
    super.new(path);
  endfunction
  `uvm_object_utils_begin(transaction)
  `uvm_field_int(din, UVM_DEFAULT)
  `uvm_field_int(resetn, UVM_DEFAULT)
  `uvm_field_int(dout, UVM_DEFAULT)
  `uvm_object_utils_end
endclass

// // //sequence class which generates the stimulus the sequence of transactions
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
      tr.resetn=1;
      `uvm_info("RST",$sformatf("sequence din:%0d , resetn:%0d , dout:%0d is created",tr.din,tr.resetn,tr.dout),UVM_NONE);
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
      tr.resetn=0;
      `uvm_info("NORM",$sformatf("sequence din:%0d , resetn:%0d , dout:%0d is created",tr.din,tr.resetn,tr.dout),UVM_NONE);
        finish_item(tr);
         end
  endtask
  endclass

// // //driver sends the stimulus to the DUT via interface

class driver extends uvm_driver#(transaction);
  `uvm_component_utils(driver)
  transaction tr;
  virtual fsm_if fif;
  
  function new(string path="driver",uvm_component parent);
    super.new(path,parent);
    endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    if(!uvm_config_db#(virtual fsm_if)::get(this,"","fif",fif))
      `uvm_error("drv","Unable to access Interface");
  endfunction
  
  virtual task run_phase(uvm_phase phase);
    tr = transaction::type_id::create("tr");
    forever begin
      seq_item_port.get_next_item(tr);
      fif.din<=tr.din;
      fif.resetn<=tr.resetn;
      `uvm_info("DRV",$sformatf(" din:%0d , resetn:%0d , dout:%0d is sent to the DUT",tr.din,tr.resetn,tr.dout),UVM_NONE);
      seq_item_port.item_done();

      repeat(1) @(posedge fif.clk);
    end
  endtask
endclass

// // // Monitor gets data from DUT and sends it to the scoreboard

class monitor extends uvm_monitor;
  `uvm_component_utils(monitor)
  
  transaction tr;
  virtual fsm_if fif;
  uvm_analysis_port#(transaction) send;
  
  function new(string path="monitor",uvm_component parent);
    super.new(path,parent);
    endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
     send=new("send",this);
    tr=transaction::type_id::create("tr");
    if(!uvm_config_db#(virtual fsm_if)::get(this,"","fif",fif))
      `uvm_error("drv","Unable to access Interface");
  endfunction
  
  virtual task run_phase(uvm_phase phase);
    forever begin

      repeat(1) @(posedge fif.clk);
      tr.din=fif.din;
      tr.resetn=fif.resetn;
      tr.dout=fif.dout;
      `uvm_info("MON",$sformatf(" din:%0d , resetn:%0d , dout:%0d is sent to the scoreboard",tr.din,tr.resetn,tr.dout),UVM_NONE);
      send.write(tr);
    end
  endtask
endclass

// // // scoreboard gets the output data from monitor and checks if it is correct


class scoreboard extends uvm_scoreboard;
  `uvm_component_utils(scoreboard)
  transaction tr;
  bit [32:0] board;
  uvm_analysis_imp#(transaction,scoreboard) recv;
  
  function new(string path="scoreboard",uvm_component parent);
    super.new(path,parent);
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    recv = new("recv", this);
  endfunction
  
  function void write(input transaction t);
    tr = t;
     // Append new din value
    `uvm_info("SCO",$sformatf(" din:%0d , resetn:%0d , dout:%0d is received from the monitor, board:%0d",tr.din,tr.resetn,tr.dout,board),UVM_NONE);
    
    if (tr.resetn == 1) begin
      board = 0; // Reset the board
      if (tr.dout == 0)
        `uvm_info("SCO", "Test Case Passed", UVM_NONE)
      else
        `uvm_info("SCO", "Test Failed", UVM_NONE)
    end else if (tr.resetn == 0) begin
      if (board % 5 == 0) begin
        if (tr.dout)
          `uvm_info("SCO", "Test Case Passed", UVM_NONE)
        else
          `uvm_info("SCO", "Test Case Failed", UVM_NONE)
      end else begin
        if (!tr.dout)
          `uvm_info("SCO", "Test Case Passed", UVM_NONE)
        else
          `uvm_info("SCO", "Test Case Failed", UVM_NONE)
      end
          board = {board[31:0], tr.din};
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
    
// // // Test here we run our testbench
    
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
      
      fsm_if fif();
      
      model dut(.clk(fif.clk),.resetn(fif.resetn),.din(fif.din),.dout(fif.dout));
      
  
      initial begin
        uvm_config_db #(virtual fsm_if)::set(null,"*","fif",fif);
        run_test("test");
      end
      initial begin
      fif.clk=0;
      end
      always #10 fif.clk=~fif.clk;
      initial begin
    $dumpfile("dump.vcd");
    $dumpvars;
  end
  
endmodule
    
