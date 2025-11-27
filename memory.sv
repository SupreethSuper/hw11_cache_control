// data memory

//`include "memory_params.vh"

module memory
  #(
   parameter WORDS=1024,                // default number of words
   parameter BITS=32,                   // default number of bits per word
   parameter [31:0] BASE_ADDR = 32'b0	// default base addres
   )
   (
   output logic [BITS-1:0]  rdata,  // read data

   input              clk,    // system clock
   input  [BITS-1:0]  wdata,  // data to write
   input              rw_,    // read=1, write=0
   input  [31:0]      addr,   // only uses enough bits to access # of words
   input  [3:0]       byte_en // byte enables
   );

   localparam ADDR_LEFT = $clog2(WORDS)-1;

   localparam FIRST_BYTE_LEFT = 7;
   localparam FIRST_BYTE_RIGHT = 0;
   localparam SECOND_BYTE_LEFT = 15;
   
   reg [BITS-1:0] mem[0:WORDS-1]; // default creates 1024 32-bit words

   // internal signals
   logic is_legal_addr;

   always_comb begin
      // Check if address is valid
      is_legal_addr = (addr >= BASE_ADDR) && (addr < (BASE_ADDR + WORDS));
   end

   always @ (posedge clk) begin 
      if (rw_ == 1'b0) begin
         if (is_legal_addr) begin
            case (byte_en)
               4'b0001: begin 
		  // Write a byte to the least significant position
                  mem[addr[ADDR_LEFT:0]][FIRST_BYTE_LEFT : FIRST_BYTE_RIGHT] <= wdata[FIRST_BYTE_LEFT : FIRST_BYTE_RIGHT];
               end
               4'b0011: begin 
		  // Write two bytes
                  mem[addr[ADDR_LEFT:0]][SECOND_BYTE_LEFT : FIRST_BYTE_RIGHT] <= wdata[SECOND_BYTE_LEFT : FIRST_BYTE_RIGHT];
               end
               4'b1111: begin 
		  // Write the entire word
                  mem[addr[ADDR_LEFT:0]] <= wdata;
               end
               default: begin
                  // Write ignored
               end
            endcase
   
         end
      end
   end

   always_comb begin
      if (is_legal_addr) begin 
         rdata = mem[addr[ADDR_LEFT:0]];
      end
      else begin
         rdata = 0;
      end
   end

endmodule
