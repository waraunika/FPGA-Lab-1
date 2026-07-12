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
    mem[1]  = 8'hB6;  // B6H (10110110, 5 1's)
    mem[2]  = 8'hC9;  // MOV B, DB
    mem[3]  = 8'h00;  // 00H (bit counter)
    mem[4]  = 8'hDB;  // MOV D, DB
    mem[5]  = 8'h08;  // 08H (bits to test)
    mem[6]  = 8'h3E;  // LOOP: RLC (carry = old A[0])
    mem[7]  = 8'hF4;  // JNC DB
    mem[8]  = 8'h0A;  //   -> SKIP (0AH)
    mem[9]  = 8'h29;  // INC B
    mem[10] = 8'h3B;  // SKIP: DEC D
    mem[11] = 8'hF2;  // JNZ DB
    mem[12] = 8'h06;  //   -> LOOP (06H)
    mem[13] = 8'hD1;  // MOV C, B
    mem[14] = 8'hEF;  // FRZ
  end

  always @(posedge CLK) begin
    if (WRITE_STACK_ENABLE) begin
      mem[stack_pointer] = stack_value;
    end
  end

  assign inst = mem[PC];
endmodule
