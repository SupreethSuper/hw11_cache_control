module forward
#(
  // Register address width (MIPS = 5). If you have a project-wide param, you can replace this with an `include`.
	parameter BITS = 32,
	parameter REG_WORDS=32,
	parameter ADDR_LEFT=$clog2(REG_WORDS)-1
)
(
	output logic 			r1_fwd_s4, // needed for data hazards
	output logic 			r2_fwd_s4,
	output logic 			r1_fwd_s5,
	output logic 			r2_fwd_s5,
	output logic 			stall_pipe,
	output logic 			j_fwd_s4, // also needed for jr
	output logic 			j_fwd_s5,
	output logic 			b_r1_fwd_s4, // also needed for branches
	output logic 			b_r2_fwd_s4,
	output logic 			b_r1_fwd_s5,
	output logic 			b_r2_fwd_s5,
	output logic 			r1_fwd_s6, // needed to feed pipe_id_ex
	output logic 			r2_fwd_s6,

	input [ADDR_LEFT:0]		r1_addr_s3, // needed for data hazards
	input [ADDR_LEFT:0]		r2_addr_s3,
	input 					rw_s4,
	input [ADDR_LEFT:0]		waddr_s4,
	input 					rw_s5,
	input [ADDR_LEFT:0]		waddr_s5,
	input 					sel_mem_s3,
	input [ADDR_LEFT:0]		waddr_s3,
	input [ADDR_LEFT:0]		r1_addr, // also needed for jr
	input [ADDR_LEFT:0]		r2_addr,
	input 					jreg,
	input 					rw_s3,
	input 					sel_mem_s4,
	input 					breq, // also needed for branches
	input 					brne

);

	localparam [ADDR_LEFT:0] ADDR_ZERO = { (ADDR_LEFT+1){1'b0} };

	assign r1_fwd_s6 = (!rw_s5) && (waddr_s5 == r1_addr) && (waddr_s5 != ADDR_ZERO);
	assign r2_fwd_s6 = (!rw_s5) && (waddr_s5 == r2_addr) && (waddr_s5 != ADDR_ZERO);

	assign r1_fwd_s5 = (!rw_s5) && (waddr_s5 == r1_addr_s3) && (waddr_s5 != ADDR_ZERO);
	assign r2_fwd_s5 = (!rw_s5) && (waddr_s5 == r2_addr_s3) && (waddr_s5 != ADDR_ZERO);

	assign r1_fwd_s4 = (!rw_s4) && (waddr_s4 == r1_addr_s3) && (waddr_s4 != ADDR_ZERO);
	assign r2_fwd_s4 = (!rw_s4) && (waddr_s4 == r2_addr_s3) && (waddr_s4 != ADDR_ZERO);


	assign j_fwd_s4 = (jreg) && (!rw_s4) && (waddr_s4 == r1_addr) && (waddr_s4 != ADDR_ZERO);
	assign j_fwd_s5 = (jreg) && (!rw_s5) && (waddr_s5 == r1_addr) && (waddr_s5 != ADDR_ZERO);


	assign b_r1_fwd_s5 = (breq || brne) && (!rw_s5) && (waddr_s5 == r1_addr) && (waddr_s5 != ADDR_ZERO);
	assign b_r2_fwd_s5 = (breq || brne) && (!rw_s5) && (waddr_s5 == r2_addr) && (waddr_s5 != ADDR_ZERO);

	assign b_r1_fwd_s4 = (breq || brne) && (!rw_s4) && (waddr_s4 == r1_addr) && (waddr_s4 != ADDR_ZERO);
	assign b_r2_fwd_s4 = (breq || brne) && (!rw_s4) && (waddr_s4 == r2_addr) && (waddr_s4 != ADDR_ZERO);


	assign stall_pipe = ( (sel_mem_s3) && (waddr_s3 != ADDR_ZERO) && ( (waddr_s3 == r1_addr) || (waddr_s3 == r2_addr) ) ) ||
                    	( (jreg) && (sel_mem_s4) && (waddr_s4 == r1_addr) && (waddr_s4 != ADDR_ZERO) ) ||
                        ( (jreg) && (!rw_s3) && (waddr_s3 == r1_addr) && (waddr_s3 != ADDR_ZERO) ) ||
                        ( (breq || brne) && (sel_mem_s4) && ( (waddr_s4 == r1_addr) || (waddr_s4 == r2_addr) ) && (waddr_s4 != ADDR_ZERO) ) ||                        
                        ( (breq || brne) && (!rw_s3) && ( (waddr_s3 == r1_addr) || (waddr_s3 == r2_addr) ) && (waddr_s3 != ADDR_ZERO) );

endmodule

// (
//     // -------- Inputs from S3 (ID/EX consumer) --------
//     input  logic [ADDR_LEFT:0] r1_addr_s3,
//     input  logic [ADDR_LEFT:0] r2_addr_s3,
//     input  logic                  sel_mem_s3,   // S3 is a memory op (used for load-use detect per slides)
//     input  logic                  rw_s3,        // S3 will write a register (destination meta for JR-not-ready)
//     input  logic [ADDR_LEFT:0] waddr_s3,     // S3 destination register (for JR-not-ready / load-use)

//     // -------- Inputs from S4 (EX/MEM newer producer) --------
//     input  logic                  rw_s4,
//     input  logic [ADDR_LEFT:0] waddr_s4,
//     input  logic                  sel_mem_s4,   // S4 is memory op (used for load→JR two-stall case)

//     // -------- Inputs from S5 (MEM/WB older producer) --------
//     input  logic                  rw_s5,
//     input  logic [ADDR_LEFT:0] waddr_s5,

//     // -------- Inputs from S2 / decode context (branch & JR sources) --------
//     input  logic [ADDR_LEFT:0] r1_addr,      // raw rs for current decode (used by JR/branches)
//     input  logic [ADDR_LEFT:0] r2_addr,      // raw rt for current decode (used by branches)
//     input  logic                  jreg,         // jump-register (JR/JALR)
//     input  logic                  breq,         // branch-equal
//     input  logic                  brne,         // branch-not-equal

//     // -------- Outputs for ALU operand forwarding (S3 consumer) --------
//     output logic                  r1_fwd_s4,
//     output logic                  r1_fwd_s5,
//     output logic                  r2_fwd_s4,
//     output logic                  r2_fwd_s5,

//     // -------- Outputs for early feed into pipe_id_ex (3-stage case, S2 consumer) --------
//     output logic                  r1_fwd_s6,
//     output logic                  r2_fwd_s6,

//     // -------- Outputs for JR/JALR target forwarding to PC path (S2 consumer) --------
//     output logic                  j_fwd_s4,
//     output logic                  j_fwd_s5,

//     // -------- Outputs for branch comparator forwarding (consumed inside equality.sv) --------
//     output logic                  b_r1_fwd_s4,
//     output logic                  b_r1_fwd_s5,
//     output logic                  b_r2_fwd_s4,
//     output logic                  b_r2_fwd_s5,

//     // -------- Stall control --------
//     output logic                  stall_pipe
// );

// 	// -------------------------
// 	// Helpers
// 	// -------------------------
// 	localparam logic [ADDR_LEFT:0] ZERO_REG = '0;

// 	// Predicates for valid writebacks (non-zero destination)
// 	logic s3_wb_valid, s4_wb_valid, s5_wb_valid;
// 	assign s3_wb_valid = rw_s3 && (waddr_s3 != ZERO_REG);
// 	assign s4_wb_valid = rw_s4 && (waddr_s4 != ZERO_REG);
// 	assign s5_wb_valid = rw_s5 && (waddr_s5 != ZERO_REG);

// 	// -------------------------
// 	// ALU operand forwarding (S3 consumer): S4 has priority over S5
// 	// -------------------------
// 	always_comb begin
// 	// defaults
// 	r1_fwd_s4 = 1'b0;
// 	r1_fwd_s5 = 1'b0;
// 	r2_fwd_s4 = 1'b0;
// 	r2_fwd_s5 = 1'b0;

// 	// R1 path
// 	if (s4_wb_valid && (waddr_s4 == r1_addr_s3)) begin
// 		r1_fwd_s4 = 1'b1;
// 	end else if (s5_wb_valid && (waddr_s5 == r1_addr_s3)) begin
// 		r1_fwd_s5 = 1'b1;
// 	end

// 	// R2 path
// 	if (s4_wb_valid && (waddr_s4 == r2_addr_s3)) begin
// 		r2_fwd_s4 = 1'b1;
// 	end else if (s5_wb_valid && (waddr_s5 == r2_addr_s3)) begin
// 		r2_fwd_s5 = 1'b1;
// 	end
// 	// NOTE: For stores, datapath uses r2_fwd_* to forward into the store-data path, not ALU-B.
// 	// (Per slides: don't forward R2 to ALU if doing a store.)
// 	end

// 	// -------------------------
// 	// Early feed (3-stage case) into pipe_id_ex (S2 consumer)
// 	// Compare S5 destination to *decode* r1/r2; assert when forwarding into S3 inputs is needed.
// 	// -------------------------
// 	always_comb begin
// 	r1_fwd_s6 = 1'b0;
// 	r2_fwd_s6 = 1'b0;

// 	if (s5_wb_valid && (waddr_s5 == r1_addr)) r1_fwd_s6 = 1'b1;
// 	if (s5_wb_valid && (waddr_s5 == r2_addr)) r2_fwd_s6 = 1'b1;
// 	end

// 	// -------------------------
// 	// JR/JALR target forwarding to PC (S2 consumer): S4 priority over S5
// 	// -------------------------
// 	always_comb begin
// 	j_fwd_s4 = 1'b0;
// 	j_fwd_s5 = 1'b0;

// 	if (jreg) begin
// 		if (s4_wb_valid && (waddr_s4 == r1_addr)) begin
// 		j_fwd_s4 = 1'b1; // Stage 4 has higher priority
// 		end else if (s5_wb_valid && (waddr_s5 == r1_addr)) begin
// 		j_fwd_s5 = 1'b1;
// 		end
// 	end
// 	end

// 	// -------------------------
// 	// Branch comparator forwarding (inside equality.sv will prefer S4 over S5)
// 	// Only assert when a branch is in decode (breq || brne)
// 	// -------------------------
// 	always_comb begin
// 	b_r1_fwd_s4 = 1'b0;
// 	b_r1_fwd_s5 = 1'b0;
// 	b_r2_fwd_s4 = 1'b0;
// 	b_r2_fwd_s5 = 1'b0;

// 	if (breq || brne) begin
// 		// Operand A
// 		if (s4_wb_valid && (waddr_s4 == r1_addr)) begin
// 		b_r1_fwd_s4 = 1'b1;
// 		end else if (s5_wb_valid && (waddr_s5 == r1_addr)) begin
// 		b_r1_fwd_s5 = 1'b1;
// 		end
// 		// Operand B
// 		if (s4_wb_valid && (waddr_s4 == r2_addr)) begin
// 		b_r2_fwd_s4 = 1'b1;
// 		end else if (s5_wb_valid && (waddr_s5 == r2_addr)) begin
// 		b_r2_fwd_s5 = 1'b1;
// 		end
// 	end
// 	end

// 	// -------------------------
// 	// Stall conditions (single signal). Front-end holds; ID/EX bubble kills control.
// 	//   1) Load–use: S3 is mem-read and S2 uses its dest (one-cycle stall).
// 	//   2) JR not ready: dest still in S3 (one-cycle stall).
// 	//   3) Load → JR: JR needs a value coming from a load currently in S4 (two-cycle total, this stays asserted as needed).
// 	// -------------------------
// 	logic stall_load_use;
// 	logic stall_jr_s3_notready;
// 	logic stall_jr_from_load_s4;

// 	// 1) Load–use hazard (per slides: match S3 dest against S2 sources; don't stall if dest is $zero)
// 	assign stall_load_use = sel_mem_s3 && s3_wb_valid &&
// 							((waddr_s3 == r1_addr) || (waddr_s3 == r2_addr));

// 	// 2) JR needs a value still being produced in S3 (not yet available)
// 	assign stall_jr_s3_notready = jreg && s3_wb_valid && (waddr_s3 == r1_addr);

// 	// 3) Load → JR: JR needs value produced by a memory read in S4 (value not read yet)
// 	assign stall_jr_from_load_s4 = jreg && sel_mem_s4 && s4_wb_valid && (waddr_s4 == r1_addr);

// 	// Combine all stall reasons
// 	always_comb begin
// 	stall_pipe = stall_load_use | stall_jr_s3_notready | stall_jr_from_load_s4;
// 	end

