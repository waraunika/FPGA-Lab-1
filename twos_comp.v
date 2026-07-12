module twos_comp (
  input [7:0] x,
  output [7:0] y
);

  assign y = ~x + 1'b1;

endmodule
