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
    mem[1]  = 8'h3C;  // A = 3CH
    mem[2]  = 8'hC9;  // MOV B, DB
    mem[3]  = 8'h5A;  // B = 5AH
    mem[4]  = 8'h01;  // AND A,B   -> A = 18H
    mem[5]  = 8'h41;  // OR  A,B   -> A = 5AH
    mem[6]  = 8'h81;  // XOR A,B   -> A = 00H
    mem[7]  = 8'hC7;  // NOR A,B   -> A = A5H
    mem[8]  = 8'h3E;  // RLC       -> A = 4AH, carry=1
    mem[9]  = 8'h09;  // ADD A,B   -> A = A4H
    mem[10] = 8'h0F;  // ADC A,B   -> A = FEH
    mem[11] = 8'h19;  // SUB A,B   -> A = A4H
    mem[12] = 8'h1F;  // SBB A,B   -> A = 4AH
    mem[13] = 8'hD0;  // MOV C, A  -> C = 4AH
    mem[14] = 8'h2A;  // INC C     -> C = 4BH
    mem[15] = 8'h3A;  // DEC C     -> C = 4AH
    mem[16] = 8'hDA;  // MOV D, C  -> D = 4AH
    mem[17] = 8'hE3;  // MOV E, D  -> E = 4AH
    mem[18] = 8'hEC;  // MOV F, E  -> F = 4AH
    mem[19] = 8'hEF;  // FRZ

  end

  always @(posedge CLK) begin
    if (WRITE_STACK_ENABLE) begin
      mem[stack_pointer] = stack_value;
    end
  end

  assign inst = mem[PC];
endmodule
