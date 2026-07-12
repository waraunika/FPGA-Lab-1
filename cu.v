// refer to cpu_architecture.md for more info.
// it will simply not be possible to include everything here
module cu (
    input CLK,

    input      [7:0] inst,
    output reg [7:0] PC,
    output reg       WRITE_STACK_ENABLE,
    output reg [7:0] stack_value,
    stack_pointer,

    output reg       carry_flag,
    carry_use,
    input  reg       carry_in,
    zero_in,
    output reg [2:0] ALUOP,

    output reg [7:0] IMMEDIATE,
    output reg [2:0] READREG1,
    READREG2,
    WRITEREG,
    output reg       WRITEENABLE,

    output reg       MUX1_SEL,
    MUX2_SEL,
    output reg [1:0] MUX3_SEL
);


  // All instructions are present at cpu_architecture.md
  // I've also made a google sheet to keep track of what instruction
  // is mapped to which hex code.

  reg [1:0] state;
  reg immediate_flag, zero_flag;
  reg jmp_enable, call_enable, ret_enable;

  parameter FETCH = 2'b00;
  parameter DECODE = 2'b01;
  parameter EXECUTE = 2'b10;
  parameter FETCH_IMMEDIATE = 2'b11;

  initial begin
    reset();
  end

  // helper function for resetting to start
  task reset();
    begin
      state              = FETCH;
      PC                 = 8'h00;
      immediate_flag     = 1'b0;
      WRITEENABLE        = 1'b0;
      carry_flag         = 1'b0;
      carry_use          = 1'b0;
      zero_flag          = 1'b0;
      MUX1_SEL           = 1'b0;
      MUX2_SEL           = 1'b0;
      MUX3_SEL           = 2'b00;
      jmp_enable         = 1'b0;
      call_enable        = 1'b0;
      ret_enable         = 1'b0;
      stack_pointer      = 8'hFF;
      WRITE_STACK_ENABLE = 1'b0;
      READREG1           = 3'b000;
      READREG2           = 3'b000;
    end
  endtask

  // helper function for branching instructions
  task branch_logic(input flag);
    begin
      if ((flag && inst[0]) || (!flag && !inst[0])) begin
        state          <= FETCH_IMMEDIATE;
        PC             <= PC + 1;
        immediate_flag <= 1'b1;
        if (inst[3]) begin
          call_enable <= 1'b1;
        end else begin
          jmp_enable <= 1'b1;
        end
      end else begin
        state <= FETCH;
        PC    <= PC + 2;
      end
    end
  endtask

  // helper function for return instructions
  task return_logic(input flag);
    begin
      state <= EXECUTE;

      if ((flag && inst[0]) || (!flag && !inst[0])) begin
        stack_pointer <= stack_pointer + 1;
        ret_enable    <= 1'b1;
      end else begin
        PC <= PC + 1;
      end
    end
  endtask

  // 3 states: 1 for fetching instruction
  // 2nd for decoding and sending proper control signals.
  // since mux's and alu are combinational, they won't need additional
  // cycle.
  // and we can get the output of alu, store it in register bank,
  // and simultaneously fetch next instruction as well.

  always @(posedge CLK) begin
    case (state)
      FETCH: begin
        state              <= DECODE;
        WRITE_STACK_ENABLE <= 1'b0;
        WRITEENABLE        <= 1'b0;

        // no operation in these op codes
        if (
	      (inst == 8'h07 || inst == 8'h47 || inst == 8'h87)
	      || (inst == 8'h11 || inst == 8'h16 || inst == 8'h17)
	      || (inst[7:3] == 5'b00100)
	      || (inst[7:3] == 5'b00110)
	      || (inst[7:3] == 5'b01001)
	      || (inst[7:4] == 4'b0101)
	      || (inst[7:5] == 3'b011)
	      || (inst[7:3] == 5'b10001)
	      || (inst[7:4] == 4'b1001)
	      || (inst == 8'hA1 || inst == 8'hA6 || inst == 8'hA7 || inst[7:3] == 5'b10101)
	      || (inst[7:4] == 4'b1011)
	      || (inst == 8'hDE || inst == 8'hDF || inst == 8'hE6 || inst == 8'hE7)
	      || (inst == 8'hF1 || inst == 8'hF6 || inst == 8'hF7)
	      || (inst == 8'hF9 || inst == 8'hFE || inst == 8'hFF)
	      ) begin
          state <= FETCH;
          PC    <= PC + 1;
        end
      end

      DECODE: begin
        // aiming for serial op codes, based on category.

        // but first, two special op codes: reset (RST) and freeze (FRZ)
        if (inst == 8'hEE) begin
          $display("reset");
          reset();
        end else if (inst == 8'hEF) begin
          $display("cpu frozen for reading reg value");
        end  // logical operations: AND OR NOR condition: 00/01/10 000 xxx
        else if (inst[7:6] != 2'b11 && inst[5:3] == 3'b000) begin
          $display("AND, OR, XOR");
          READREG1 <= 3'b000;
          WRITEREG <= 3'b000;
          WRITEENABLE <= 1'b1;
          // alu op code will be 000 for AND, 001 for OR, 010 for XOR
          ALUOP    <= {1'b0, inst[7:6]};
          MUX1_SEL <= 1'b0;
          MUX3_SEL <= 2'b00;

          // xx 000 110 is op code for immediate operation
          if (inst[2:1] == 2'b11) begin
            MUX2_SEL       <= 1'b1;
            immediate_flag <= 1'b1;
            PC             <= PC + 1;
            state          <= FETCH_IMMEDIATE;
          end  // if not immediate operation:
          else begin
            MUX2_SEL <= 1'b0;
            READREG2 <= inst[2:0];
            state    <= EXECUTE;
          end
        end  // logical operation NOR is quite complex
             // (C6/7 H, CE/F H) and (D6/7 H)
        // two conditions: (1100 x11x) and (1101 011x) respectively
        else if ((inst[7:4] == 4'b1100 && inst[2:1] == 2'b11) || (inst[7:1] == 7'b1101011)) begin
          $display("NOR");
          READREG1 <= 3'b000;
          // reg 2 logic:
          // bit 4, 3, 0 decide the register
          // example: NOR A, C = CE H = 1100 1110
          // bit 4 3 0: 010 -> C register
          READREG2 <= {inst[4:3], inst[0]};
          WRITEREG <= 3'b000;
          WRITEENABLE <= 1'b1;

          MUX1_SEL <= 1'b0;
          MUX2_SEL <= 1'b0;
          MUX3_SEL <= 2'b00;

          ALUOP <= 3'b011;  // NOR opcode for alu: 011
          state <= EXECUTE;
        end  // rotate operations
             // 2E -> ROL, 2F -> ROR (no carry usage in both): 0010 111x
        // 3E -> RLC, 3F -> RRC (carry usage in both): 0011 111x
        // we can treat ROL, RLC as same ALU instruction with carry usage differing
        // we can treat ROR, RRC as same ALU instruction with carry usage differing
        else if (inst[7:5] == 3'b001 && inst[3:1] == 3'b111) begin
          $display("Rotate");
          READREG1    <= 3'b000;
          WRITEREG    <= 3'b000;
          WRITEENABLE <= 1'b1;

          ALUOP       <= {2'b11, (inst[0] == 1'b1)};  // 110 to rotate left, 111 to rotate right
          carry_use   <= inst[4] == 1'b1;
          MUX1_SEL    <= 1'b0;
          MUX2_SEL    <= 1'b0;
          MUX3_SEL    <= 2'b00;

          state       <= EXECUTE;
        end  // arithmetic operations op codes: 00 xx1 xxx
        else if (inst[7:6] == 2'b00 && inst[3] == 1'b1) begin
          $display("arithmetic");
          WRITEENABLE <= inst[2:0] != 3'b110;
          carry_use <= inst[2:0] == 3'b111;

          // readreg1 will be A, unless for increment/decrement
          // if inc/dec then we'd have to have respective regsiter
          READREG1 <= inst[5] == 1'b1 ? inst[2:0] : 3'b000;

          // reg 2 logic: if add, sub normal logic
          // if incrementing, decrementing,
          // we use special registr at reg[6] that has default value of 01.
          // if ADC or SBB, then we need only B
          READREG2 <= (inst[5] == 1'b1) ? 3'b110 : (inst[2:0] == 3'b111) ? 3'b001 : inst[2:0];

          // if INC/DEC operation, use given register, else use A register.
          WRITEREG <= inst[5] == 1'b1 ? inst[2:0] : 3'b000;

          // if subtracting or decreasing, then we'd want its 2's complement.
          MUX1_SEL <= inst[4] == 1'b1;
          MUX2_SEL <= inst[2:0] == 3'b110;
          MUX3_SEL <= inst[2:0] == 3'b110 ? 2'b10 : 00;

          // if ADD A, DB or SUB B, DB, fetch immediate
          state <= inst[2:0] == 3'b110 ? FETCH_IMMEDIATE : EXECUTE;
          PC <= inst[2:0] == 3'b110 ? PC + 1 : PC;
          immediate_flag <= inst[2:0] == 3'b110;
          ALUOP <= inst == 8'h1F ? 3'b101 : 3'b100;
        end  // return operations, at op code: 1010 xxx
        else if (inst[7:3] == 5'b00010) begin
          $display("return");
          // unconditional return
          if (inst[2:0] === 3'b000) begin
            state         <= FETCH;
            PC            <= stack_value;
            stack_pointer <= stack_pointer + 1;
          end  // conditional returns
          else if (inst[2:1] == 2'b01) begin
            return_logic(carry_flag);
          end else if (inst[2:1] == 2'b10) begin
            return_logic(zero_flag);
          end
        end

	      // JMP/CALL instruction at F0-F5H and F8-FDH, simple take the next byte in inst_memory and go there.
                    // in the form of 1111 0xxx for jmp, 1xxx for call
        else if (inst[7:4] == 4'b1111) begin
          $display("branch");
          // simple JMP (F0H) or CALL (F8H)
          if (inst[2:0] == 3'b000) begin
            state          <= FETCH_IMMEDIATE;
            immediate_flag <= 1'b1;
            PC             <= PC + 1;

            if (inst[3] == 0) begin
              jmp_enable <= 1'b1;
            end else begin
              call_enable <= 1'b1;
            end
          end else if (inst[2:1] == 2'b01) begin
            branch_logic(zero_flag);
          end else if (inst[2:1] == 2'b10) begin
            branch_logic(carry_flag);
          end
        end  // data transfer operation: 11 xxx xxx
        else if (inst[7:6] == 2'b11) begin
          $display("data transfer");
          WRITEENABLE <= inst[5:3] != inst[2:0];
          READREG1 <= inst[2:0];
          WRITEREG <= inst[5:3];

          MUX3_SEL <= 2'b01;

          state <= EXECUTE;

          if (inst[5:3] == inst[2:0]) begin
            immediate_flag <= 1'b1;
            MUX3_SEL       <= 2'b10;
            PC             <= PC + 1;
            state          <= FETCH_IMMEDIATE;
          end
        end
      end

      FETCH_IMMEDIATE: begin
        IMMEDIATE      <= inst;
        immediate_flag <= 1'b0;
        state          <= EXECUTE;
        WRITEENABLE    <= !jmp_enable;
      end

      EXECUTE: begin
        WRITEENABLE <= 1'b0;
        PC <= (jmp_enable || call_enable) ? IMMEDIATE : PC + 1;
        WRITE_STACK_ENABLE <= jmp_enable;

        if (call_enable) begin
          stack_value   <= PC + 8'h01;
          stack_pointer <= stack_pointer - 8'h01;
        end

        if (ret_enable) begin
          PC <= stack_value;
        end

        jmp_enable <= 1'b0;
        call_enable <= 1'b0;
        ret_enable <= 1'b0;
        zero_flag <= (inst[7:6] == 2'b00 && inst[3] == 1'b1) && !(inst == 8'h2E || inst == 8'h2F || inst == 8'h3E || inst == 8'h3F)
          ? zero_in
          : zero_flag;
        carry_flag <= (inst[7:3] == 5'b00011)  // if SUB, ! CY
        ? !carry_in
					: ((!jmp_enable && !call_enable) && (inst[7:3] == 5'b00001 || inst[7:1] == 7'b0010111 || inst[7:1] == 7'b0011111)) // if ROTATE/ADD then carry_in
        ? carry_in : carry_flag;

        state <= FETCH;
      end

      default: begin
        state <= FETCH;
      end
    endcase
  end

endmodule
