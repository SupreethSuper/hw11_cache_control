module pipe_mem_wb #(
    parameter BITS = 32,
    parameter REG_WORDS=32,
    parameter ADDR_LEFT=$clog2(REG_WORDS)-1
) 
(
    output logic [BITS-1:0]         alu_out_s5,
    output logic                    atomic_s5,
    output logic [BITS-1:0]         d_mem_rdata_s5,
    output logic                    link_rw_s5,
    output logic                    sel_mem_s5,
    output logic                    rw_s5,
    output logic [ADDR_LEFT:0]      waddr_s5,
    output logic [3:0]              byte_en_s5,
    output logic                    halt_s5,
    // output logic                    jal_s5,
    // output logic [BITS-1:0]         pc_addr_s5,

    input logic                     clk,
    input logic                     rst_,
    input logic [BITS-1:0]          alu_out_s4,
    input logic                     atomic_s4,
    input logic [BITS-1:0]          d_mem_rdata,
    input logic                     link_rw_,
    input logic                     sel_mem_s4,
    input logic                     rw_s4,
    input logic [ADDR_LEFT:0]       waddr_s4,
    input logic [3:0]               byte_en_s4,
    input logic                     halt_s4
    // input logic                     jal_s4,
    // input logic [BITS-1:0]          pc_addr_s4
);

   `include "common.vh"

    always @(posedge clk or negedge rst_) begin
        if (!rst_) begin
            alu_out_s5      <= { BITS {1'b0} };
            atomic_s5       <= 1'b0;
            d_mem_rdata_s5  <= { BITS {1'b0} };
            link_rw_s5      <= 1'b1;
            sel_mem_s5      <= 1'b0;
            rw_s5           <= 1'b1;
            waddr_s5        <= { (ADDR_LEFT+1) {1'b0}};
            byte_en_s5      <= 4'h0;
            halt_s5         <= 1'b0;
            // jal_s5 <= 1'b0;
            // pc_addr_s5 <= {BITS{1'b0}};
        end 
        
        else begin
            alu_out_s5      <= alu_out_s4;
            atomic_s5       <= atomic_s4;
            d_mem_rdata_s5  <= d_mem_rdata;
            link_rw_s5      <= link_rw_;
            sel_mem_s5      <= sel_mem_s4;
            rw_s5           <= rw_s4;
            waddr_s5        <= waddr_s4;
            byte_en_s5      <= byte_en_s4;
            halt_s5         <= halt_s4;
            // jal_s5 <= jal_s4;
            // pc_addr_s5 <= pc_addr_s4;
        end
    end
    
endmodule
