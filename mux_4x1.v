module mux_4x1 (
    input  [7:0] a,
    b,
    c,
    d,
    input  [1:0] s,
    output [7:0] z
);

  assign z = (s == 2'b00) ? a : (s == 2'b01) ? b : (s == 2'b10) ? c : (s == 2'b11) ? d : 1'bz;

endmodule
