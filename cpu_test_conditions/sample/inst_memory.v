module inst_memory (
    input [7:0] PC,
    input CLK,
    input reg WRITE_STACK_ENABLE,
    input reg [7:0] stack_value,
    input reg [7:0] stack_pointer,
    output [7:0] inst
);

  reg [7:0] mem[0:255];
  integer i;

  initial begin
    for (i = 0; i < 256; i = i + 1) begin
      mem[i] = 8'hFF;
    end
    mem[0]  = 8'hC0;  // MOV A, DB
    mem[1]  = 8'h2F;  // 2FH as DB
    mem[2]  = 8'h3F;  // RLC
    mem[3]  = 8'h1E;  // SUB A, DB
    mem[4]  = 8'h55;  // DB = 55H
    mem[5]  = 8'hC8;  // MOV B, A
    mem[6]  = 8'hC0;  // MOV A, DB
    mem[7]  = 8'h78;  // DB = 78
    mem[8]  = 8'hEE;  // RST
    mem[9]  = 8'h09;  // ADD A, B
    mem[10] = 8'hF5;  // JC DB
    mem[11] = 8'h10;  // DB = 10
    mem[12] = 8'h41;  // OR A, B
    mem[16] = 8'h01;  // AND A, B
    mem[17] = 8'hEF;  // FRZ
  end

  always @(posedge CLK) begin
    if (WRITE_STACK_ENABLE) begin
      mem[stack_pointer] = stack_value;
    end
  end

  assign inst = mem[PC];
endmodule
