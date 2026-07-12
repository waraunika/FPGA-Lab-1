module mux_2x1 (
  input [7:0]  x, y,
	input s,
  output [7:0] z
  );

  assign z =
    (s == 1'b0)
      ? x
      : (s == 1'b1)
        ? y
        : 1'bz;

endmodule
