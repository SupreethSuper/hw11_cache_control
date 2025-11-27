module pipe_id_ex #(
    parameter BITS = 32,
    parameter REG_WORDS=32,
    parameter ADDR_LEFT=$clog2(REG_WORDS)-1,
    parameter OP_BITS=4,
    parameter SHIFT_BITS=5
) 
(
    output logic                    atomic_s3,
    output logic                    sel_mem_s3,
    output logic                    check_link_s3,
    output logic                    mem_rw_s3,
    output logic                    rw_s3,
    output logic [ADDR_LEFT:0]      waddr_s3,
    output logic                    load_link_s3,
    output logic [BITS-1:0]         r2_data_s3,
    output logic [BITS-1:0]         r1_data_s3,
    output logic [ADDR_LEFT:0]      r2_addr_s3,
    output logic [ADDR_LEFT:0]      r1_addr_s3,
    output logic                    alu_imm_s3,
    output logic [BITS-1:0]         sign_ext_imm_s3,
    output logic [SHIFT_BITS-1:0]   shamt_s3,
    output logic [OP_BITS-1:0]      alu_op_s3,
    output logic [3:0]              byte_en_s3,
    output logic                    halt_s3,
    // output logic                    jal_s3,
    // output logic [BITS-1:0]         pc_addr_s3,

    input logic                     clk,
    input logic                     rst_,
    input logic                     atomic,
    input logic                     sel_mem,
    input logic                     check_link,
    input logic                     mem_rw_,
    input logic                     rw_,
    input logic [ADDR_LEFT:0]       waddr,
    input logic                     load_link_,
    input logic [BITS-1:0]          r2_data,
    input logic [BITS-1:0]          r1_data,
    input [ADDR_LEFT:0]             r2_addr,
    input [ADDR_LEFT:0]             r1_addr,
    input logic                     alu_imm,
    input logic [BITS-1:0]          sign_ext_imm,
    input logic [SHIFT_BITS-1:0]    shamt,
    input logic [OP_BITS-1:0]       alu_op,
    input logic [3:0]               byte_en,
    input logic                     halt_s2,
    input                           stall_pipe
    // input logic                     jal_s2,
    // input logic [BITS-1:0]          pc_addr_s2
);

   `include "common.vh"

    always @(posedge clk or negedge rst_) begin
        if (!rst_) begin
            atomic_s3       <= 1'b0;
            sel_mem_s3      <= 1'b0;
            check_link_s3   <= 1'b0;
            mem_rw_s3       <= 1'b1;
            rw_s3           <= 1'b1;
            waddr_s3        <= { (ADDR_LEFT+1) {1'b0} };
            load_link_s3    <= 1'b1;
            r2_data_s3      <= { BITS {1'b0} };
            r1_data_s3      <= { BITS {1'b0} };
            r2_addr_s3      <= { (ADDR_LEFT+1) {1'b0}};
            r1_addr_s3      <= { (ADDR_LEFT+1) {1'b0}};
            alu_imm_s3      <= 1'b0;
            sign_ext_imm_s3 <= { BITS {1'b0} };
            shamt_s3        <= { SHIFT_BITS {1'b0} };
            alu_op_s3       <= { OP_BITS {1'b0} };
            byte_en_s3      <= 4'h0;
            halt_s3         <= 1'b0;
            // jal_s3 <= 1'b0;
            // pc_addr_s3 <= {BITS{1'b0}};
        end 
        
        else begin
            atomic_s3       <= atomic && !stall_pipe;
            sel_mem_s3      <= sel_mem && !stall_pipe;
            check_link_s3   <= check_link && !stall_pipe;
            mem_rw_s3       <= mem_rw_ || stall_pipe;
            rw_s3           <= rw_ || stall_pipe;
            waddr_s3        <= waddr;
            load_link_s3    <= load_link_ || stall_pipe;
            r2_data_s3      <= r2_data;
            r1_data_s3      <= r1_data;
            r2_addr_s3      <= r2_addr;
            r1_addr_s3      <= r1_addr;
            alu_imm_s3      <= alu_imm;
            sign_ext_imm_s3 <= sign_ext_imm;
            shamt_s3        <= shamt;
            alu_op_s3       <= alu_op;
            byte_en_s3      <= byte_en;
            halt_s3         <= halt_s2;
            // jal_s3 <= jal_s2;
            // pc_addr_s3 <= pc_addr_s2;
        end
    end
    
endmodule