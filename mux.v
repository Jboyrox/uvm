// Design + Interface
module mux
  (
    input [3:0] ip1 , ip2 ,ip3, ip4,
    input [1:0] sel,
    output [3:0] out
  );
  reg [3:0] temp;
  always @(*)
    begin
      case(sel)
        0:temp<=ip1;
        1:temp<=ip2;
        2:temp<=ip3;
        3:temp<=ip4;
      endcase
    end
 assign out=temp;
endmodule


interface mux_if;
  logic [3:0] ip1;
  logic [3:0] ip2;
  logic [3:0] ip3;
  logic [3:0] ip4;
  logic [1:0] sel;
  logic [3:0] out;
endinterface  
