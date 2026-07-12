module alu (
    input  [7:0] OPERAND1,
    OPERAND2,
    input  [2:0] ALUOP,
    input        carry_flag,
    carry_use,
    output       carry_out,
    zero_out,
    output [7:0] ALURESULT
);


  // intermediary wires for operations.
  wire [7:0] SUM, SBB, ROT_LEFT, ROT_RIGHT;
  wire [7:0] logicAND, logicOR, logicXOR, logicNOR;
  wire carry_sum, borrow_diff, l_carry, r_carry;

  // intermediary wires for rotating
  wire RL_carry_status, RL_last_bit, RR_carry_status, RR_first_bit;
  wire [6:0] RL_main, RR_main;

  // if ROL: carry flag is as it is. if RLC: MSB becomes carry flag
  assign RL_carry_status = (carry_flag && !carry_use) || (OPERAND1[7] && carry_use);
  // if ROR: carry flag is as it is. if RRC: LSB becomes carry flag
  assign RR_carry_status = (carry_flag && !carry_use) || (OPERAND1[0] && carry_use);

  // main block in ROL/RLC and ROR/RRC that is simply rotated with no conflict
  assign RL_main = OPERAND1[6:0];
  assign RR_main = OPERAND1[7:1];

  // if ROL: LSB is MSB. if RLC: LSB is carry
  assign RL_last_bit = (OPERAND1[7] && !carry_use) || (carry_flag && carry_use);
  // if ROR: MSB is LSB. if RRC: MSB is carry
  assign RR_first_bit = (OPERAND1[0] && !carry_use) || (carry_flag && carry_use);

  assign {carry_sum, SUM} = OPERAND1 + OPERAND2 + {7'b0000000, carry_flag && carry_use};
  assign {borrow_diff, SBB} = OPERAND1 + OPERAND2 - {7'b0000000, carry_flag};

  assign {l_carry, ROT_LEFT} = {RL_carry_status, RL_main, RL_last_bit};
  assign {r_carry, ROT_RIGHT} = {RR_carry_status, RR_first_bit, RR_main};

  assign logicAND = OPERAND1 & OPERAND2;
  assign logicOR = OPERAND1 | OPERAND2;
  assign logicXOR = OPERAND1 ^ OPERAND2;
  assign logicNOR = ~(logicOR);

  // ALUOP definitions and usage
  // 00: simple and gate
  // 01: simple or gate
  // 02: simple xor gate
  // 03: simple nor gate
  // 04: add instruction for ADD, ADC, SUB
  // 05: SBB instruction specifically
  // 06: ROL and RLC based on carry_use
  // 07: ROR and RRC based on carry_use
  assign ALURESULT            =
                                (ALUOP == 3'o0) ? logicAND:
                                (ALUOP == 3'o1) ? logicOR:
                                (ALUOP == 3'o2) ? logicXOR:
                                (ALUOP == 3'o3) ? logicNOR:
                                (ALUOP == 3'o4) ? SUM:
                                (ALUOP == 3'o5) ? SBB:
                                (ALUOP == 3'o6) ? ROT_LEFT:
                                (ALUOP == 3'o7) ? ROT_RIGHT : 8'h00;

  assign carry_out            =
                                (ALUOP == 3'o4) ? carry_sum
                                : (ALUOP == 3'o5) ? borrow_diff
                                : (ALUOP == 3'o6) ? l_carry
                                : (ALUOP == 3'o7) ? r_carry : carry_flag;

  assign zero_out = (ALURESULT == 8'h00);
endmodule
