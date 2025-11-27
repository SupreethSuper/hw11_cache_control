// the register file - 2 read, 1 write

//`include "regfile_params.vh"

module regfile
  #(
   parameter WORDS=32,                  // default number of words
   parameter BITS=32,                   // default number of bits per word
   parameter REG_ADDR_LEFT = $clog2(WORDS)-1
   )
   (

   output logic [BITS-1:0] r1_data,          // read value 1
   output logic [BITS-1:0] r2_data,          // read value 2

   input                	rst_,		   // to reset all entries
   input                	clk,           // system clock
   input                	rw_,           // read=1, write=0
   input  [BITS-1:0]    	wdata,         // data to write
   input  [REG_ADDR_LEFT:0]     waddr,         // write address
   input  [REG_ADDR_LEFT:0]     r1_addr,       // read address 1
   input  [REG_ADDR_LEFT:0]     r2_addr,       // read address 2
   input                        jal,
   input  [BITS-1:0]            pc_addr,
   input  [3:0]         	byte_en        // byte enables
   );

   localparam RESET_VALUE = 32'b0;

   localparam FIRST_BYTE_LEFT = 7;
   localparam FIRST_BYTE_RIGHT = 0;
   localparam SECOND_BYTE_LEFT = 15;
   localparam SECOND_BYTE_RIGHT = 8;
   localparam THIRD_BYTE_RIGHT = 16;

   localparam ONE_BYTE = 4'b0001;
   localparam TWO_BYTE = 4'b0011;

   localparam JAL_ONE = { { (BITS-1){1'b0} }, {1'b1} };          
   localparam [REG_ADDR_LEFT:0] RA_REG = 5'd31; 	// Register 31 $ra

   reg [BITS-1:0] mem[0:WORDS-1]; // default creates 32 32-bit words

   // internal signals
   logic is_legal_waddr;

   assign is_legal_waddr = (waddr != 32'b0);

   always @ (posedge clk or negedge rst_) begin
      if (!rst_) begin
         for ( int i=0; i< WORDS; i++) begin
            mem[i] <= RESET_VALUE;
         end
      end
      else begin 		// Check if this is a write operation
         if ( !(jal && waddr == RA_REG) && rw_ == 1'b0 && is_legal_waddr ) begin	//  Check if the write address is in the valid range
            case (byte_en)
               ONE_BYTE: begin
                  // Write one byte
		            mem[waddr][FIRST_BYTE_LEFT : FIRST_BYTE_RIGHT] <= wdata [FIRST_BYTE_LEFT : FIRST_BYTE_RIGHT];
                  // Set other bytes to 0
	               mem[waddr][BITS-1 : SECOND_BYTE_RIGHT] <= '0; 			
               end
               TWO_BYTE: begin
                  // Write two bytes
                  mem[waddr][SECOND_BYTE_LEFT : FIRST_BYTE_RIGHT] <= wdata [SECOND_BYTE_LEFT : FIRST_BYTE_RIGHT];
                  // Set other bytes to 0
                  mem[waddr][BITS-1 : THIRD_BYTE_RIGHT] <= '0;
               end
               // For other byte_en values, including 4'b1111, write the entire word
               default: mem[waddr] <= wdata;
            endcase
         end

         if (jal) begin
            mem[RA_REG] <= pc_addr + JAL_ONE;
         end
      end
   end


   assign r1_data = mem[r1_addr];
   assign r2_data = mem[r2_addr];

endmodule
