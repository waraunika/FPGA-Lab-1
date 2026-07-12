module twos_comp_tb;

  reg [7:0] x;
  wire [7:0] y;

  twos_comp uut (
    .x(x),
    .y(y)
  );

  initial begin
    $dumpfile("twos_comp.vcd");
    $dumpvars(0, uut);
    
    #10;
    x = 8'h00; #10;
    x = 8'h11; #10;
    x = 8'h43; #10;
    x = 8'h6A; #10;
    x = 8'h82; #10;
    x = 8'hAA; #10;
    x = 8'hCE; #10;
    x = 8'hEA; #10;
    $finish;
  end

endmodule
