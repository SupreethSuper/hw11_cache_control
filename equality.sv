module equality
   #(
   parameter NUM_BITS=32
   )

   (
   input [NUM_BITS-1:0] data1,
   input [NUM_BITS-1:0] data2,
   input [NUM_BITS-1:0] alu_out_s4,
   input [NUM_BITS-1:0] reg_wdata,
   input                b_r1_fwd_s4,
   input                b_r2_fwd_s4,
   input                b_r1_fwd_s5,
   input                b_r2_fwd_s5,

   output equal,
   output not_equal
   );

   logic [NUM_BITS-1:0] b_fwd_data1;
   logic [NUM_BITS-1:0] b_fwd_data2;

   // Branch forwarding logic (Stage 4 has higher priority than Stage 5)
   assign b_fwd_data1 = b_r1_fwd_s4 ? alu_out_s4 :       // Stage 4 forwarding
                         b_r1_fwd_s5 ? reg_wdata :        // Stage 5 forwarding  
                         data1;                           // Original register data

   assign b_fwd_data2 = b_r2_fwd_s4 ? alu_out_s4 :       // Stage 4 forwarding
                         b_r2_fwd_s5 ? reg_wdata :        // Stage 5 forwarding
                         data2;  

   assign equal = b_fwd_data1 === b_fwd_data2;
   assign not_equal = b_fwd_data1 !== b_fwd_data2;

endmodule
