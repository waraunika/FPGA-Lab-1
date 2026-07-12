module register_file (
  input CLK,
  input [2:0] READREG1, READREG2, WRITEREG,
  input WRITEENABLE,
  input [7:0] WRITEDATA,
  output reg [7:0] REGOUT1, REGOUT2
);

  reg [7:0] regs [0:7];
  integer i;

  initial begin
    for (i = 0; i < 8; i = i + 1) begin
      regs[i] = 8'h00;
    end
    regs[6] = 8'h01;
  end

  always @(posedge CLK) begin
    if (WRITEENABLE) begin
      regs[WRITEREG] <= WRITEDATA;
    end
  end

  always @(*) begin
    REGOUT1 = regs[READREG1];
    REGOUT2 = regs[READREG2];
  end

endmodule
