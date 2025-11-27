// instruction register and instruction decode
module instr_reg
  #(
   parameter BITS=32,                   // default number of bits per word
   parameter REG_WORDS=32,              // default number of words in the regfile
   parameter ADDR_LEFT=$clog2(REG_WORDS)-1, // log base 2 of the number of words
                                        // which is # of bits needed to address
                                        // the memory for read and write
   parameter OP_BITS=4,                 // bits needed to define operations
   parameter SHIFT_BITS=5,              // bits needed to define shift amount
   parameter JMP_LEFT=25,               // left bit of the jump target
   parameter IMM_LEFT=BITS/2            // number of bits in immediate field
   )
   (

   output logic [ADDR_LEFT:0]    r1_addr,      // reg file read address 1
   output logic [ADDR_LEFT:0]    r2_addr,      // reg file read address 2
   output logic [ADDR_LEFT:0]    waddr,        // reg file write address
   output logic [SHIFT_BITS-1:0] shamt,        // shift amount for alu
   output logic [OP_BITS-1:0]    alu_op,       // alu operation
   output logic [IMM_LEFT-1:0]   imm,          // use immediate value
   output logic [JMP_LEFT:0]     addr,         // jump address
   output logic                  rw_,          // register file read/write
   output logic                  mem_rw_,      // data memory read/write
   output logic                  sel_mem,      // use data from memory
   output logic                  alu_imm,      // use immediate data for alu
   output logic                  signed_ext,   // do sign extension
   output logic [ 3:0]           byte_en,      // byte enables
   output logic                  halt,         // stop the program
   output logic                  load_link_,   // load link register
   output logic                  check_link,   // check if link register same as addr
   output logic                  atomic,       // atomic operation
   output logic                  jmp,          // jump
   output logic                  breq,         // branch on equal
   output logic                  brne,         // branch on not equal
   output logic                  jal,          // jump and link
   output logic                  jreg,         // jump to register value
   output logic                  exception,    // take exception


   input                   clk,          // system clock
   input                   load_instr,   // if 1 load register
   input  [BITS-1:0]       mem_data,     // instruction from instruction memory
   input                   rst_,         // system reset
   input                   equal,        // alu inputs were equal for branches
   input                   not_equal,    // alu inputs were not equal for branches
   input                   stall_pipe
   );

   `include "common.vh"               // common constants
   `include "instr_reg_params.vh"     // instruction register constants

   localparam CODE_BITS = 6;          // instruction op code bits
   localparam FUNC_BITS = 6;          // instruction function bits
   localparam OP_LEFT = 31;
   localparam RS_LEFT = 25;
   localparam RT_LEFT = 20;
   localparam RD_LEFT = 15;
   localparam SH_LEFT = 10;
   localparam FU_LEFT = 5;
   localparam NUM_REG_BITS = 5;
   localparam OP_RTYPE = 6'h0;
   localparam OP_JTYPE1 = 6'h2;
   localparam OP_JTYPE2 = 6'h3;
   localparam NOP = 32'h0000_0020;             // ADD $0 = $0 + $0

   logic [BITS-1:0]         instr;             // see above!
   logic [CODE_BITS-1:0]    opcode;
   logic [FUNC_BITS-1:0]    funct;
   logic [ADDR_LEFT:0]      rs;
   logic [ADDR_LEFT:0]      rt;
   logic [ADDR_LEFT:0]      rd;
   logic                    rt_is_src;
   logic                    r_type;
   logic                    j_type;
   logic                    i_type;
   logic                    stall;
   
   localparam OP_SW = 6'h2B;
   localparam OP_SB = 6'h28;
   localparam OP_SH = 6'h29;
   localparam OP_BEQ = 6'h4;
   localparam OP_BNE = 6'h5;

   localparam OP_LUI = 6'h0F;

   localparam ADDR_ZERO = { (ADDR_LEFT + 1){1'b0} };

   localparam OP_SC          = 6'h38;  
   localparam ONE_LSB        = 4'b0001;  
   localparam TWO_LSB        = 4'b0011; 
//    localparam JAL_REG        = 5'd31; 			// regsiter JAL

   //always @ ( * )         // here for debugging
   //   $display("instruction reg is %h",instr);

   // register to hold the instruction
   always @(posedge clk or negedge rst_) begin
      if (!rst_) begin
         instr <= NOP;
      end 
      else if (!stall_pipe) begin
            if (stall) begin
                  instr <= NOP;
            end
            else if (load_instr && !halt) begin
                  instr <= mem_data;
            end
      end
      // else if (load_instr) begin
      //    instr <= mem_data;
      // end
   end

   assign opcode = instr[OP_LEFT -: CODE_BITS];   // extract instruction fields
   assign rs     = instr[RS_LEFT -: NUM_REG_BITS];
   assign rt     = instr[RT_LEFT -: NUM_REG_BITS];
   assign rd     = instr[RD_LEFT -: NUM_REG_BITS];

   assign r_type = opcode === OP_RTYPE;      // get instruction type
   assign j_type = ( (opcode === OP_JTYPE1) || (opcode === OP_JTYPE2) );
   assign i_type = ( !r_type && !j_type );

   assign rt_is_src = r_type 
                      || (opcode == OP_SW) 
                      || (opcode == OP_SB) 
                      || (opcode == OP_SH) 
                      || (opcode == OP_BEQ) 
                      || (opcode == OP_BNE)
                      || (opcode == OP_SC);

   // extract more instruction fields
   assign r1_addr = j_type 	? ADDR_ZERO 	: rs;
   assign r2_addr = rt_is_src 	? rt 		: ADDR_ZERO;
//    assign waddr   = jal 	? JAL_REG
   assign waddr   = (opcode == OP_SC)	? rt
							: r_type 	? rd 
                           						: (rt_is_src) 	? ADDR_ZERO
                                         						: rt;

   assign shamt   = r_type 	? instr[SH_LEFT -: SHIFT_BITS] 		: opcode == OP_LUI ? 5'd16 : {SHIFT_BITS{1'b0}};
   assign funct   = r_type 	? instr[FU_LEFT -: FUNC_BITS] 		: {FUNC_BITS{1'b0}};
   assign imm     = i_type 	? instr[IMM_LEFT-1 -: IMM_LEFT] 	: {IMM_LEFT{1'b0}};
   assign addr    = j_type 	? instr[JMP_LEFT -: JMP_LEFT+1] 	: {(JMP_LEFT+1){1'b0}};

   // implement each instruction
   always @ (*)
   begin
      rw_        = 1'b1;       // set default values so each instruction just
      mem_rw_    = 1'b1;       // has to override the values which differ
      alu_op     = ALU_PASS1;
      alu_imm    = 1'b0;
      sel_mem    = 1'b0;
      signed_ext = 1'b0;
      halt       = 1'b0;
      byte_en    = 4'hF;
      load_link_ = 1'b1;
      check_link = 1'b0;
      atomic     = 1'b0;
      jmp        = 1'b0;
      stall      = 1'b0;	// set to 1 for bnme, beq
      breq       = 1'b0;
      brne       = 1'b0;
      jal        = 1'b0;
      jreg       = 1'b0;
      exception  = 1'b0;

     if (rst_) begin

      case ( { opcode, funct } )
         ADD: begin
                 rw_ = 1'b0;
                 alu_op = ALU_ADD;
              end

         ADDI: begin
                 rw_ = 1'b0;
                 alu_op = ALU_ADD;
                 alu_imm = 1'b1;
                 signed_ext = 1'b1;
               end

         ADDIU: begin
                 rw_ = 1'b0;
                 alu_op = ALU_ADD;
                 alu_imm = 1'b1;
                 signed_ext = 1'b1;
               end

         ADDU: begin
                 rw_ = 1'b0;
                 alu_op = ALU_ADD;
               end

         AND: begin
                 rw_ = 1'b0;
                 alu_op = ALU_AND;
               end

         ANDI: begin
                 rw_ = 1'b0;
                 alu_op = ALU_AND;
                 alu_imm = 1'b1;
               end

         BEQ: begin
                 breq = 1'b1;
                 stall = equal;
               end

         BNE: begin
                 brne = 1'b1;
                 stall = not_equal;
               end

         LW: begin
                 rw_ = 1'b0;
                 alu_op = ALU_ADD;
                 alu_imm = 1'b1;
                 signed_ext = 1'b1;
                 sel_mem = 1'b1;
               end

         NOR: begin
                 rw_ = 1'b0;
                 alu_op = ALU_NOR;
               end

         OR: begin
                 rw_ = 1'b0;
                 alu_op = ALU_OR;
               end

         ORI: begin
                 rw_ = 1'b0;
                 alu_op = ALU_OR;
                 alu_imm = 1'b1;
               end

         SLL: begin
                 rw_ = 1'b0;
                 alu_op = ALU_SLL;
               end

         SRL: begin
                 rw_ = 1'b0;
                 alu_op = ALU_SRL;
               end

         SW: begin
                 mem_rw_ = 1'b0;
                 alu_op = ALU_ADD;
                 alu_imm = 1'b1;
                 signed_ext = 1'b1;
               end

         SUB: begin
                 rw_ = 1'b0;
                 alu_op = ALU_SUB;
               end

         SUBU: begin
                 rw_ = 1'b0;
                 alu_op = ALU_SUB;
               end

         SRA: begin
                 rw_ = 1'b0;
                 alu_op = ALU_SRA;
               end

         J: begin
                 jmp = 1'b1;
                 stall = 1'b1;
               end

         JAL: begin
                 jmp = 1'b1;
                 jal = 1'b1;
                 rw_ = 1'b0;
               end

         JR: begin
                 jreg = 1'b1;
                 stall = 1'b1;
               end

         LBU: begin
                 rw_ = 1'b0;
                 alu_op = ALU_ADD;
                 alu_imm = 1'b1;
	         signed_ext = 1'b1;
	         sel_mem = 1'b1;
	         byte_en = ONE_LSB;
               end

         LHU: begin
                 rw_ = 1'b0;
                 alu_op = ALU_ADD;
                 alu_imm = 1'b1;
	         signed_ext = 1'b1;
	         sel_mem = 1'b1;
	         byte_en = TWO_LSB;
               end

         LL: begin
                 rw_ = 1'b0;
                 alu_op = ALU_ADD;
                 alu_imm = 1'b1;
	         signed_ext = 1'b1;
	         sel_mem = 1'b1;
                 load_link_ = 1'b0;
               end

         LUI: begin
                 rw_ = 1'b0;
                 alu_imm = 1'b1;
                 alu_op = ALU_SLL;
               end

         SB: begin
                 mem_rw_ = 1'b0;
                 alu_op = ALU_ADD;
                 alu_imm = 1'b1;
	         signed_ext = 1'b1;
	         byte_en = ONE_LSB;
               end

         SC: begin
                 mem_rw_ = 1'b0;
                 alu_op = ALU_ADD;
                 alu_imm = 1'b1;
	         signed_ext = 1'b1;
                 check_link = 1'b1;
                 atomic = 1'b1;
                 rw_ = 1'b0;
               end

         SH: begin
                 mem_rw_ = 1'b0;
                 alu_op = ALU_ADD;
                 alu_imm = 1'b1;
	         signed_ext = 1'b1;
	         byte_en = TWO_LSB;
               end

         SLT: begin
                 rw_ = 1'b0;
                 alu_op = ALU_LTS;
               end

         SLTI: begin
                 rw_ = 1'b0;
                 alu_op = ALU_LTS;
                 alu_imm = 1'b1;
	         signed_ext = 1'b1;
               end

         SLTIU: begin
                 rw_ = 1'b0;
                 alu_op = ALU_LTU;
                 alu_imm = 1'b1;
	         signed_ext = 1'b1;
               end

         SLTU: begin
                 rw_ = 1'b0;
                 alu_op = ALU_LTU;
               end

         HALT: begin
                  halt = 1'b1;
               end

         default: begin
                     exception = 1'b1;
                     //halt = 1'b1;
                  end
      endcase
     end
   end

endmodule

