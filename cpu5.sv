// the top level cpu 
module cpu4
   (
   output logic      halt,      // halt signal to end simulation
   output logic      exception, // the exception interupt signal

   input             clk,  // system clock
   input             rst_  // system reset
   );

   `include "cpu_params.vh"

   logic [BITS-1:0]            pc_addr;      // current address
   logic [BITS-1:0]            i_mem_rdata;  // instruction memory read data
   logic [BITS-1:0]            d_mem_rdata;  // data memory read data
   logic [BITS-1:0]            r1_data;      // register file read data 1
   logic [BITS-1:0]            r2_data;      // register file read data 2
   logic [BITS-1:0]            alu_out;      // alu output
   logic [BITS-1:0]            alu_in_1;     // alu input 1
   logic [BITS-1:0]            alu_in_2;     // alu input 2
   logic [REG_ADDR_LEFT:0]     r1_addr;      // register file read addr 1
   logic [REG_ADDR_LEFT:0]     r2_addr;      // register file read addr 2
   logic [REG_ADDR_LEFT:0]     waddr;        // register file write addr
   logic [SHIFT_BITS-1:0]      shamt;        // shift amount
   logic [OP_BITS-1:0]         alu_op;       // alu operation
   logic [IMM_LEFT-1:0]        imm;          // immediate data
   logic [JMP_LEFT:0]          addr;         // jump address to program counter
   logic                       rw_;          // register file read write signal
   logic                       mem_rw_;      // data memory read write signal
   logic                       sel_mem;      // select the output from the memory
   logic                       alu_imm;      // use immediate data for the alu
   logic [BITS-1:0]            reg_wdata;    // data to write to the register file
   logic [BITS-1:0]            sign_ext_imm; // immediate data that has been sign extended
   logic                       signed_ext;   // whether or not to extend the sign bit
   logic [ 3:0]                byte_en;      // byte enables
   logic                       load_link_;   // load the link register
   logic                       check_link;   // check if link register is same as address
   logic                       atomic;       // force value to 0 or 1 for atomic operation
   logic                       jmp;          // doing a jump
   logic                       equal;        // values were equal for branches
   logic                       breq;         // doing a branch on equal
   logic                       not_equal;    // values were not equal for branches
   logic                       brne;         // doing o branch o not equal
   logic                       jal;          // doing a jump and link
   logic                       jreg;         // jumping to an address in a register

   logic [BITS-1:0]            link_addr;
   logic                       link_valid;
   logic                       link_rw_;
   logic                       use_mem_rw_;

//    logic [BITS-1:0]            data2_equality;

   // ========================================================
   // pipe_id_ex outputs
   logic                    atomic_s3;
   logic                    sel_mem_s3;
   logic                    check_link_s3;
   logic                    mem_rw_s3;
   logic                    rw_s3;
   logic [REG_ADDR_LEFT:0]  waddr_s3;
   logic                    load_link_s3;
   logic [BITS-1:0]         r2_data_s3;
   logic [BITS-1:0]         r1_data_s3;
   logic [REG_ADDR_LEFT:0]     r2_addr_s3;
   logic [REG_ADDR_LEFT:0]     r1_addr_s3;
   logic                    alu_imm_s3;
   logic [BITS-1:0]         sign_ext_imm_s3;
   logic [SHIFT_BITS-1:0]   shamt_s3;
   logic [OP_BITS-1:0]      alu_op_s3;
   logic [3:0]              byte_en_s3;
   logic                    halt_s3;
   logic                    halt_s2;
//    logic                    jal_s3;
//    logic [BITS-1:0]         pc_addr_s3;
   logic [BITS-1:0]         r1_data_wb_fwd;
   logic [BITS-1:0]         r2_data_wb_fwd;


   // ========================================================
   // pipe_ex_mem outputs
   logic [BITS-1:0]         alu_out_s4;
   logic                    atomic_s4;
   logic                    sel_mem_s4;
   logic                    check_link_s4;
   logic                    mem_rw_s4;
   logic                    rw_s4;
   logic [REG_ADDR_LEFT:0]  waddr_s4;
   logic                    load_link_s4;
   logic [BITS-1:0]         r2_data_s4;
   logic [3:0]              byte_en_s4;
   logic                    halt_s4;
//    logic                    jal_s4;
//    logic [BITS-1:0]         pc_addr_s4;
   logic [BITS-1:0]            r2_data_s3_fwd;


  // ========================================================
   // pipe_mem_wb outputs
   logic [BITS-1:0]         alu_out_s5;
   logic                    atomic_s5;
   logic [BITS-1:0]         d_mem_rdata_s5;
   logic                    link_rw_s5;
   logic                    sel_mem_s5;
   logic                    rw_s5;
   logic [REG_ADDR_LEFT:0]  waddr_s5;
   logic [3:0]              byte_en_s5;
//    logic                    jal_s5;
//    logic [BITS-1:0]         pc_addr_s5;
   // logic                    halt_s5;


   // =======================================================
   // forward
   logic                       r2_fwd_s4;
   logic                       r1_fwd_s4;
   logic                       r2_fwd_s5;
   logic                       r1_fwd_s5;
   logic                       r2_fwd_s6;
   logic                       r1_fwd_s6;
   logic                       b_r1_fwd_s4;
   logic                       b_r2_fwd_s4;
   logic                       b_r1_fwd_s5;
   logic                       b_r2_fwd_s5;
   logic                       j_fwd_s4;
   logic                       j_fwd_s5;
   logic                       stall_pipe;


   // the program counter
   // which instruction to read from the instruction memory
   pc #(.BITS(BITS) ) pc (
          .pc_addr(pc_addr), 
		  .clk(clk), 
		  .addr(addr), 
		  .rst_(rst_),
          .jmp(jmp), 
		  .load_instr(1'b1), 
		  .sign_ext_imm(sign_ext_imm),
          .equal(equal), 
		  .not_equal(not_equal), 
		  .breq(breq), 
		  .brne(brne),
          .jreg(jreg), 
		  .r1_data(r1_data),
          .reg_wdata(reg_wdata),
          .alu_out_s4(alu_out_s4),    
		  .j_fwd_s4(j_fwd_s4),
          .j_fwd_s5(j_fwd_s5),
		  .stall_pipe(stall_pipe)
   );



   // the instruction memory
   // holds the program
   // NOTE: not currently enabling writes to the instruction memory
   memory #( .BASE_ADDR(I_MEM_BASE_ADDR), .BITS(BITS), .WORDS(I_MEM_WORDS) ) i_memory(
       .rdata(i_mem_rdata), .clk(clk), .wdata(32'b0), .rw_(1'b1),
       .addr(pc_addr), .byte_en(4'b0) );

   // the instruction register - includes instruction decode
   // gets instruction to execute and decodes it, telling the rest of the design what to do
   instr_reg #( .BITS(BITS), .REG_WORDS(REG_WORDS), .OP_BITS(OP_BITS),
                .SHIFT_BITS(SHIFT_BITS), .JMP_LEFT(JMP_LEFT) ) instr_reg (
       .r1_addr(r1_addr), 
	   .r2_addr(r2_addr), 
	   .waddr(waddr),
       .jal(jal), 
	   .jreg(jreg), 
	   .exception(exception),
       .shamt(shamt), 
	   .alu_op(alu_op), 
	   .imm(imm), 
	   .addr(addr),
       .rw_(rw_), 
	   .sel_mem(sel_mem), 
	   .alu_imm(alu_imm),
       .signed_ext(signed_ext), 
	   .byte_en(byte_en), 
	   .halt(halt_s2),
       .clk(clk), 
	   .load_instr(1'b1), 
	   .mem_rw_(mem_rw_), 
       //.swap(swap),
       .load_link_(load_link_), 
	   .check_link(check_link),
       .atomic(atomic), 
	   .jmp(jmp), 
	   .breq(breq), 
	   .equal(equal), 
       .brne(brne), 
	   .not_equal(not_equal),
       .mem_data(i_mem_rdata), 
	   .rst_(rst_),
      .stall_pipe(stall_pipe)
   );

   // select the data to write to the register file:
   // from data memory or atomic value (write a 0 or 1) or swapped else from the alu
   assign reg_wdata = sel_mem_s5 ? d_mem_rdata_s5
                              : atomic_s5 ? { {(BITS-1){1'b0}}, ~link_rw_s5 }
                                              : alu_out_s5;

   // the register file
   // holds the 32 registers that you can read or write
   regfile #( .WORDS(REG_WORDS), .BITS(BITS) ) regfile(
       .r1_data(r1_data), .r2_data(r2_data), .clk(clk), .rst_(rst_),
       .rw_(rw_s5), .wdata(reg_wdata), .waddr(waddr_s5),
       .r1_addr(r1_addr), .r2_addr(r2_addr), .jal(jal), .pc_addr(pc_addr), .byte_en(byte_en_s5) ); 

//    assign data2_equality = alu_imm ? sign_ext_imm : r2_data;
   
   equality #( .NUM_BITS(BITS) ) equality (
       .data1(r1_data), .data2(r2_data),
       .equal(equal), .not_equal(not_equal),
       .alu_out_s4(alu_out_s4),
       .reg_wdata(reg_wdata), 
	   .b_r1_fwd_s4(b_r1_fwd_s4),
       .b_r2_fwd_s4(b_r2_fwd_s4),
       .b_r1_fwd_s5(b_r1_fwd_s5),
       .b_r2_fwd_s5(b_r2_fwd_s5)
	);

   assign sign_ext_imm = signed_ext ? { {(BITS - IMM_LEFT) {imm[IMM_LEFT-1]}}, imm}
                                    : { {(BITS - IMM_LEFT) {1'b0}}, imm}; // do sign extension


   assign alu_in_1     = r1_fwd_s4  ? alu_out_s4 
   									: r1_fwd_s5  ? reg_wdata
									: r1_data_s3; // always r1_data

   assign alu_in_2     = alu_imm_s3 ? sign_ext_imm_s3 
									: r2_fwd_s4 ? alu_out_s4
												: r2_fwd_s5 ? reg_wdata
   															: r2_data_s3; // need sign extended version?

   // the alu
   // does the math
   alu #( .NUM_BITS(BITS), .OP_BITS(OP_BITS), .SHIFT_BITS(SHIFT_BITS) ) alu (
       .alu_out(alu_out), 
       // .equal(equal), .not_equal(not_equal), 
       .data1(alu_in_1), .data2(alu_in_2), 
       .alu_op(alu_op_s3), .shamt(shamt_s3) );
	
   assign r2_data_s3_fwd = (!mem_rw_s3  && r2_fwd_s4) ? alu_out_s4 :
                                 (!mem_rw_s3  && r2_fwd_s5) ? reg_wdata :
                                 r2_data_s3;

   assign r1_data_wb_fwd = r1_fwd_s6 ? reg_wdata : r1_data;
   assign r2_data_wb_fwd = r2_fwd_s6 ? reg_wdata : r2_data;

   // the data memory
   // the data is stored or read
   memory #( .BASE_ADDR(D_MEM_BASE_ADDR), .BITS(BITS), .WORDS(D_MEM_WORDS) ) d_memory (
        .rdata(d_mem_rdata), .clk(clk), .wdata(r2_data_s4),
        .rw_(use_mem_rw_), .addr(alu_out_s4), .byte_en(byte_en_s4) );

   assign link_rw_ = ( check_link_s4 & ( (alu_out_s4 != link_addr) | !link_valid ));
   assign use_mem_rw_ = ( mem_rw_s4 || link_rw_ );


   pipe_id_ex #(
      .BITS(BITS),
      .REG_WORDS(REG_WORDS),
      .ADDR_LEFT(REG_ADDR_LEFT),
      .OP_BITS(OP_BITS),
      .SHIFT_BITS(SHIFT_BITS)
   ) pipe_id_ex (
      // output ports
         .atomic_s3(atomic_s3),
         .sel_mem_s3(sel_mem_s3),
         .check_link_s3(check_link_s3),
         .mem_rw_s3(mem_rw_s3),
         .rw_s3(rw_s3),
         .waddr_s3(waddr_s3),
         .load_link_s3(load_link_s3),
         .r2_data_s3(r2_data_s3),
         .r1_data_s3(r1_data_s3),
		 .r2_addr_s3(r2_addr_s3),
       	 .r1_addr_s3(r1_addr_s3),
         .alu_imm_s3(alu_imm_s3),
         .sign_ext_imm_s3(sign_ext_imm_s3),
         .shamt_s3(shamt_s3),
         .alu_op_s3(alu_op_s3),
         .byte_en_s3(byte_en_s3),
         .halt_s3(halt_s3),
        //  .jal_s3(jal_s3),
        //  .pc_addr_s3(pc_addr_s3),

      // input ports
         .clk(clk),
         .rst_(rst_),
         .atomic(atomic),
         .sel_mem(sel_mem),
         .check_link(check_link),
         .mem_rw_(mem_rw_),
         .rw_(rw_),
         .waddr(waddr),
         .load_link_(load_link_),
		 .r2_addr(r2_addr),
         .r1_addr(r1_addr),
         .alu_imm(alu_imm),
         .sign_ext_imm(sign_ext_imm),
         .shamt(shamt),
         .alu_op(alu_op),
         .byte_en(byte_en),
         .halt_s2(halt_s2),
        //  .jal_s2(jal),
        //  .pc_addr_s2(pc_addr),
		 .r2_data         (r2_data_wb_fwd),
		 .r1_data         (r1_data_wb_fwd),
		 .stall_pipe      (stall_pipe)
   );

   pipe_ex_mem #(
      .BITS(BITS),
      .REG_WORDS(REG_WORDS),
      .ADDR_LEFT(REG_ADDR_LEFT)
   ) pipe_ex_mem (
      // output ports
         .alu_out_s4(alu_out_s4),
         .atomic_s4(atomic_s4),
         .sel_mem_s4(sel_mem_s4),
         .check_link_s4(check_link_s4),
         .mem_rw_s4(mem_rw_s4),
         .rw_s4(rw_s4),
         .waddr_s4(waddr_s4),
         .load_link_s4(load_link_s4),
         .r2_data_s4(r2_data_s4),
         .byte_en_s4(byte_en_s4),
         .halt_s4(halt_s4),
        //  .jal_s4(jal_s4),
        //  .pc_addr_s4(pc_addr_s4),

      // input ports
         .clk(clk),
         .rst_(rst_),
         .alu_out(alu_out),
         .atomic_s3(atomic_s3),
         .sel_mem_s3(sel_mem_s3),
         .check_link_s3(check_link_s3),
         .mem_rw_s3(mem_rw_s3),
         .rw_s3(rw_s3),
         .waddr_s3(waddr_s3),
         .load_link_s3(load_link_s3),
         .r2_data_s3(r2_data_s3_fwd),
         .byte_en_s3(byte_en_s3),
         .halt_s3(halt_s3)
        //  .jal_s3(jal_s3),
        //  .pc_addr_s3(pc_addr_s3)
   );

   pipe_mem_wb #(
      .BITS(BITS),
      .REG_WORDS(REG_WORDS),
      .ADDR_LEFT(REG_ADDR_LEFT)
   ) pipe_mem_wb (
      // output ports
         .alu_out_s5(alu_out_s5),
         .atomic_s5(atomic_s5),
         .d_mem_rdata_s5(d_mem_rdata_s5),
         .link_rw_s5(link_rw_s5),
         .sel_mem_s5(sel_mem_s5),
         .rw_s5(rw_s5),
         .waddr_s5(waddr_s5),
         .byte_en_s5(byte_en_s5),
         .halt_s5(halt),
        //  .jal_s5(jal_s5),
        //  .pc_addr_s5(pc_addr_s5),

      // input ports
         .clk(clk),
         .rst_(rst_),
         .alu_out_s4(alu_out_s4),
         .atomic_s4(atomic_s4),
         .d_mem_rdata(d_mem_rdata),
         .link_rw_(link_rw_),
         .sel_mem_s4(sel_mem_s4),
         .rw_s4(rw_s4),
         .waddr_s4(waddr_s4),
         .byte_en_s4(byte_en_s4),
         .halt_s4(halt_s4)
        //  .jal_s4(jal_s4),
        //  .pc_addr_s4(pc_addr_s4)

   );

   forward #(
		.REG_WORDS(REG_WORDS), 
		.BITS(BITS)
	) forward 
	(
	// outputs
		.r1_fwd_s4(r1_fwd_s4), 
		.r2_fwd_s4(r2_fwd_s4),
  		.r1_fwd_s5(r1_fwd_s5), 
		.r2_fwd_s5(r2_fwd_s5),
  		.r1_fwd_s6(r1_fwd_s6), 
		.r2_fwd_s6(r2_fwd_s6),
  		.b_r1_fwd_s4(b_r1_fwd_s4), 
		.b_r2_fwd_s4(b_r2_fwd_s4),
  		.b_r1_fwd_s5(b_r1_fwd_s5), 
		.b_r2_fwd_s5(b_r2_fwd_s5),
  		.j_fwd_s4(j_fwd_s4), 
		.j_fwd_s5(j_fwd_s5),
		.stall_pipe(stall_pipe),

  	// inputs
		.r1_addr_s3(r1_addr_s3), 
		.r2_addr_s3(r2_addr_s3),
		.rw_s4(rw_s4), 
		.waddr_s4(waddr_s4),
		.rw_s5(rw_s5), 
		.waddr_s5(waddr_s5),
		.sel_mem_s3(sel_mem_s3), // keep as your sel_mem_s3 if golden semantics
		.waddr_s3(waddr_s3),
		.r1_addr(r1_addr), 
		.r2_addr(r2_addr),
		.jreg(jreg),
		.rw_s3(rw_s3),
		.sel_mem_s4(sel_mem_s4),
		.breq(breq), 
		.brne(brne)
	);


   always @(posedge clk or negedge rst_) begin 
      if (!rst_) begin
         link_valid <= 1'b0;
         link_addr <= {BITS {1'b0}};
      end 
      else begin
         if (!load_link_s4) begin       	// LL
            link_valid <= 1'b1;
            link_addr <= alu_out_s4;
         end 
         else if (check_link_s4) begin   	// SC
            link_valid <= 1'b0;
            link_addr  <= {BITS{1'b0}}; 
         end 
         else if ( !check_link_s4 && mem_rw_s4 == 1'b0 && link_valid && (alu_out_s4 == link_addr) ) begin
            link_valid <= 1'b0;
            link_addr  <= {BITS{1'b0}}; 
         end
      end
   end

endmodule   
