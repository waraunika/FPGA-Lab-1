`timescale 1ns / 1ps
module cpu ();
  reg CLK;
  wire [7:0] PC;
  wire [7:0] inst;
  wire [2:0] READREG1, READREG2, WRITEREG;
  wire [7:0] REGOUT1, REGOUT2, COMP_OUT;
  wire WRITEENABLE;
  wire MUX1_SEL, MUX2_SEL;
  wire [1:0] MUX3_SEL;
  wire [7:0] MUX2_OUT, OPERAND2;
  wire [7:0] IMMEDIATE, ALURESULT;
  wire [2:0] ALUOP;
  wire carry_flag, carry_use;
  wire carry, zero_out;
  wire WRITE_STACK_ENABLE;
  wire [7:0] stack_value, stack_pointer;
  wire [7:0] WRITEDATA;
  wire [7:0] R0, R1, R2, R3, R4, R5, R6, R7;

  cu cu (
      .inst(inst),
      .CLK(CLK),
      .READREG1(READREG1),
      .READREG2(READREG2),
      .WRITEREG(WRITEREG),
      .WRITEENABLE(WRITEENABLE),
      .MUX1_SEL(MUX1_SEL),
      .MUX2_SEL(MUX2_SEL),
      .MUX3_SEL(MUX3_SEL),
      .carry_in(carry),
      .carry_flag(carry_flag),
      .carry_use(carry_use),
      .zero_in(zero_out),
      .WRITE_STACK_ENABLE(WRITE_STACK_ENABLE),
      .IMMEDIATE(IMMEDIATE),
      .PC(PC),
      .stack_value(stack_value),
      .stack_pointer(stack_pointer),
      .ALUOP(ALUOP)
  );

  inst_memory mem (
      .PC(PC),
      .CLK(CLK),
      .WRITE_STACK_ENABLE(WRITE_STACK_ENABLE),
      .stack_value(stack_value),
      .stack_pointer(stack_pointer),
      .inst(inst)
  );

  register_file register_file (
      .CLK        (CLK),
      .READREG1   (READREG1),
      .READREG2   (READREG2),
      .WRITEREG   (WRITEREG),
      .WRITEENABLE(WRITEENABLE),
      .WRITEDATA  (WRITEDATA),
      .REGOUT1    (REGOUT1),
      .REGOUT2    (REGOUT2)
  );

  assign R0 = register_file.regs[0];
  assign R1 = register_file.regs[1];
  assign R2 = register_file.regs[2];
  assign R3 = register_file.regs[3];
  assign R4 = register_file.regs[4];
  assign R5 = register_file.regs[5];
  assign R6 = register_file.regs[6];
  assign R7 = register_file.regs[7];

  mux_2x1 m2 (
      .x(REGOUT2),
      .y(IMMEDIATE),
      .s(MUX2_SEL),
      .z(MUX2_OUT)
  );

  twos_comp twos_comp (
      .x(MUX2_OUT),
      .y(COMP_OUT)
  );

  mux_2x1 m1 (
      .x(MUX2_OUT),
      .y(COMP_OUT),
      .s(MUX1_SEL),
      .z(OPERAND2)
  );

  mux_4x1 m3 (
      .a(ALURESULT),
      .b(REGOUT1),
      .c(IMMEDIATE),
      .s(MUX3_SEL),
      .z(WRITEDATA)
  );

  alu alu (
      .OPERAND1(REGOUT1),
      .OPERAND2(OPERAND2),
      .ALUOP(ALUOP),
      .carry_flag(carry_flag),
      .carry_out(carry),
      .carry_use(carry_use),
      .zero_out(zero_out),
      .ALURESULT(ALURESULT)
  );

  always #5 CLK = ~CLK;

  initial begin
    $dumpfile("cpu.vcd");
    $dumpvars(0, cpu);

    CLK = 0;
    #1800;
    $finish;
  end
endmodule
