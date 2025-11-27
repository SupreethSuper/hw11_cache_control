// program counter
module pc
  #(
   parameter OFFSET_ADDR_BITS = 16,   // number of bits in offset address
   parameter BITS=32                  // default number of BITS per word
   )
   (

   output logic [BITS-1:0] pc_addr,      // current instruction address

   input                clk,             
   input  [BITS-7:0]    addr,            
   input                rst_,            
   input                jmp,             
   input                load_instr,      
   input  [BITS-1:0]    sign_ext_imm,    
   input                equal,           
   input                breq,            
   input                not_equal,       
   input                brne,            
   input                jreg,            
   input  [BITS-1:0]    r1_data,         
   input  [BITS-1:0]    alu_out_s4,      
   input  [BITS-1:0]    reg_wdata,        
   input                j_fwd_s4,        
   input                j_fwd_s5,        
   input                stall_pipe      
   );

   logic [BITS-1:0] next_addr;
   logic [BITS-1:0] p1_addr;

   logic [BITS-1:0] reg_addr;
   logic [BITS-1:0] jmp_addr;
   logic [BITS-1:0] jreg_addr;
   logic [BITS-1:0] breq_addr;
   logic [BITS-1:0] brne_addr;

   logic branch_or_jump;


   localparam logic [BITS-1:0] ONE = { { (BITS-1) {1'b0} }, 1'b1};
   localparam logic [BITS-1:0] ZERO = {BITS{1'b0}};


   always_ff @(posedge clk or negedge rst_) begin
      if (!rst_) begin
         pc_addr <= ZERO;
      end
      else if (load_instr && !stall_pipe) begin
         pc_addr <= next_addr;
      end

   end


   assign branch_or_jump = jmp | jreg | (brne && not_equal) | (breq && equal);
   assign p1_addr = pc_addr + ONE;


   assign reg_addr = !branch_or_jump ? p1_addr
                                     : ZERO;

   assign jmp_addr = jmp ? { pc_addr[BITS-1:BITS-4], 2'b0, addr }
                         : ZERO;

   assign jreg_addr = jreg ? ( j_fwd_s4 ? alu_out_s4 
                                        : j_fwd_s5 ? reg_wdata 
                                                   : r1_data ) 
                           : ZERO;

   assign breq_addr = breq ? (equal ? (pc_addr + sign_ext_imm) : p1_addr) 
                                    : ZERO;

   assign brne_addr = brne ? (not_equal ? (pc_addr + sign_ext_imm) : p1_addr) 
                                        : ZERO;

   assign next_addr = reg_addr | jmp_addr | jreg_addr | brne_addr | breq_addr;   
         
endmodule

