module model (
  input clk,
  input resetn,
  input din,
  output logic dout
);

logic [3:0] state;

always @(posedge clk)
begin
if(resetn)
state<=5;
else
begin
  case(state)
  5:state<=(din ? 1 : 0);
  default : state <= ((state*2) + din )%5;
endcase
 
end
end
assign dout = (state==0);
endmodule

interface fsm_if;
  logic clk;
  logic resetn;
  logic din;
  logic dout;
endinterface
