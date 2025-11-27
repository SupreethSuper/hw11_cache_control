// Cache using CAM
module cam2
  #(
   parameter WORDS=8,                   // default number of words
   parameter BITS=8,                    // default number of bits per word
   parameter ADDR_LEFT=$clog2(WORDS)-1, // log base 2 of the number of words
                                        // which is # of bits needed to address
                                        // the memory for read and write
   parameter TAG_SZ=8                   // size of the tag
   )
   (
//---------------------outputs only----------------------------------------------
   output logic [BITS-1:0]    cache_data,        // the data
   output logic               cache_hit,    // was in the CAM - initially called as found_it
   output logic               cache_full,        //if  1 cam is full, else 0
//----------------------end of outputs--------------------------------------------

//------------------------inputs only-------------------------------------------

//----------------------------control signals-------------------------------------
   input                      read,        // read signal
   input                      clk,         // system clock
   input                      write_,      // write_ signal
   input                      rst_,         // system reset
   input                      new_valid,   // new valid bit
//---------------------------------------------------------------------------------

//-----------------------------------data------------------------------------------
   input  [TAG_SZ-1:0]        check_tag,   // the tag to match
   input  [ADDR_LEFT:0]       w_addr,      // address to write
   input  [BITS-1:0]          wdata,       // data to write
   input  [TAG_SZ-1:0]        new_tag     // the new tag
//--------------------------------------------------------------------------------------
   );

   `include "cam_params.vh" 
 


//----------------adding the vars--------------------------------
//integer               windex;      //for the loop
logic [ADDR_LEFT : 0] write_index; //where we found it
logic                 write_found; //did we find it
//----------------------------------------------------------------



   logic [BITS-1:0]   cache_data_mem[0:WORDS-1]; // data memory
   logic [TAG_SZ-1:0] tag_mem[0:WORDS-1];  // tag memory
   logic [WORDS-1:0]  val_mem;             // valid memory

  // integer index;                       // for the loop
   logic [ADDR_LEFT:0] match_index;     // where we found it
   logic found;                         // did we find it



//--------------------------------------------------------------------------------
   //the reset block
      always_ff @(posedge clk or negedge rst_) begin
       if (!rst_) begin
           for (int index = 0; index < WORDS; index++) begin
               val_mem[index] <= 1'b0;
               tag_mem[index] <= {TAG_SZ{1'b0}};
               cache_data_mem[index] <= {BITS{1'b0}};
           end
       end
       else if ((!write_) && (new_valid) && (!cache_full) && (write_found) ) begin // write_ is active-low
           val_mem[write_index] <= new_valid;
           tag_mem[write_index] <= new_tag;
           cache_data_mem[write_index] <= wdata;
       end
       else if ( (!write_) && (!new_valid) ) begin


               val_mem[w_addr] <= 1'b0;
               tag_mem[w_addr] <= {TAG_SZ{1'b0}};
               cache_data_mem[w_addr] <= {BITS{1'b0}}; 


       end

   end
//------------------------------------------------------------------------------------------


//---------------------------------------------------------------------------------------

   always_comb begin
       found      = 1'b0;
       match_index= INDEX[0];
       for (int index = 0; index < WORDS; index++) begin
           if (val_mem[index] && (tag_mem[index] == check_tag)) begin
               match_index = INDEX[index][ADDR_LEFT : 0];// changed as per INDEX requirement for variable words 
               found = 1'b1;
           end
       end
   end

//---------------------------------------------------------------------------------------




//-----------------------new style of writing to CAM-----------------------------------


   always_comb begin

// integer               windex;      //for the loop
// logic [ADDR_LEFT : 0] write_index; //where we found it
// logic                 write_found; //did we find it

      cache_full        = 1'b1; //we are saying that, initially its full
      write_found = 1'b0; //we are assuming its not empty 
      write_index =  { (ADDR_LEFT + 1) {1'b0} }; //initializing

      for(int windex = 0; windex<WORDS; windex++) begin
         if(!write_found && (!val_mem[windex]) ) begin
            write_found = 1'b1; //so we found a space to write
            write_index = INDEX[windex][ADDR_LEFT : 0]; //similar to match_index
            cache_full = 1'b0; //found atleast one empty

         end
      end



      //this is where the for loop comes in i guess


   end


//--------------------------------------------------------------------------------------


   assign cache_data = found ? cache_data_mem[match_index] : { BITS { 1'b0 } };
   assign cache_hit = found; //initially called as found_it

endmodule
