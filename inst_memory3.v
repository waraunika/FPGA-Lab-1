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

    mem[0]  = 8'hC9;  // MOV B, DB
    mem[1]  = 8'h05;  // B = 5
    mem[2]  = 8'hC0;  // MOV A, DB
    mem[3]  = 8'h00;  // A = 0
    mem[4]  = 8'h09;  // LOOP: ADD A,B
    mem[5]  = 8'h39;  // DEC B
    mem[6]  = 8'hF2;  // JNZ DB
    mem[7]  = 8'h04;  //   -> LOOP (A ends at 0FH, B=0)
    mem[8]  = 8'hF8;  // CALL DB
    mem[9]  = 8'h16;  //   -> DOUBLE (16H) (A -> 1EH)
    mem[10] = 8'h3F;  // RRC (A -> 0FH, carry=0)
    mem[11] = 8'hF5;  // JC DB
    mem[12] = 8'h0F;  //   -> CARRY_SET (0FH)
    mem[13] = 8'hF0;  // JMP DB
    mem[14] = 8'h13;  //   -> NO_CARRY  (13H)
    mem[15] = 8'hD2;  // CARRY_SET: MOV C, DB
    mem[16] = 8'hCC;  //   C = CCH
    mem[17] = 8'hF0;  // JMP DB
    mem[18] = 8'h15;  //   -> END (15H)
    mem[19] = 8'hD2;  // NO_CARRY: MOV C, DB
    mem[20] = 8'h00;  //   C = 00H
    mem[21] = 8'hEF;  // END: FRZ
    mem[22] = 8'h08;  // DOUBLE: ADD A,A
    mem[23] = 8'h14;  // RNC
    mem[24] = 8'hEE;  // RST
    mem[25] = 8'hEF;  // FRZ
  end

  always @(posedge CLK) begin
    if (WRITE_STACK_ENABLE) begin
      mem[stack_pointer] = stack_value;
    end
  end

  assign inst = mem[PC];
endmodule
