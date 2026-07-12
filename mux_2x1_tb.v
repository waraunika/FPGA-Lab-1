`timescale 1ns/1ps;
module mux_2x1_tb;

  reg x, y, s;
  wire z;

  mux_2x1 uut (
    .x(x),
    .y(y),
    .s(s),
    .z(z)
  );

  initial begin
    $dumpfile("mux_2x1.vcd");
    $dumpvars(0, uut);

    #10;
    x = 0; y = 0; s = 0; #10;
    x = 0; y = 0; s = 1; #10;
    x = 0; y = 1; s = 0; #10;
    x = 0; y = 1; s = 1; #10;
    x = 1; y = 0; s = 0; #10;
    x = 1; y = 0; s = 1; #10;
    x = 1; y = 1; s = 0; #10;
    x = 1; y = 1; s = 1; #10;
    $finish;
  end

endmodule
