`timescale 1ns/1ps;
module register_file_tb;

  reg CLK;
  reg[2:0] READREG1, READREG2, WRITEREG;
  reg WRITEENABLE;
  reg [7:0] WRITEDATA;
  wire [7:0] REGOUT1, REGOUT2;

  register_file uut(
    CLK,
    READREG1,
    READREG2,
    WRITEREG,
    WRITEENABLE,
    WRITEDATA,
    REGOUT1,
    REGOUT2
  );

  always #5 CLK = ~CLK;

  initial begin
    $dumpfile("register_file.vcd");
    $dumpvars(0, uut);

    CLK = 0;

    WRITEREG = 3'b000;
    WRITEDATA = 8'hAA;
    WRITEENABLE = 1'b1;
    #10;

    WRITEENABLE = 1'b0;
    READREG1 = 3'b000;
    READREG2 = 3'b001;
    #10;

    WRITEREG = 3'b001;
    WRITEDATA = 8'h55;
    WRITEENABLE = 1'b1;
    #10;

    WRITEENABLE = 1'b0;
    READREG1 = 3'b000;
    READREG2 = 3'b001;
    #10;

    WRITEREG = 3'b010;
    WRITEDATA = 8'hFF;
    WRITEENABLE = 1'b1;
    READREG1 = 3'b010;
    #10;

    #10;
    $finish;

  end
endmodule
