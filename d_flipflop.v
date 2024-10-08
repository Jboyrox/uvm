// Design + Interface
module d_flipflop
  (
    input clk , d , reset,
    output reg q
  );
  always @(posedge clk)
    begin
      if(reset)
        q<=0;
      else
        q<=d;
    end
endmodule


interface dff_if;
  logic clk;
  logic d;
  logic reset;
  logic q;
  endinterface  
