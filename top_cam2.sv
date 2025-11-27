// test bench for the CAM
module top_cam2();

   localparam BITS=8;
   localparam TAG_SZ=8;
   localparam WORDS=8;
   localparam ADDR_LEFT=$clog2(WORDS)-1;

   logic [BITS-1:0]    cache_data;
   logic               cache_hit;
   logic [TAG_SZ-1:0]  new_tag;
   logic [TAG_SZ-1:0]  check_tag;
   logic               rst_;
   logic               clk;
   logic [ADDR_LEFT:0] w_addr;
   logic [BITS-1:0]    wdata;
   logic               read;
   logic               write_;
   logic               new_valid;


   logic [TAG_SZ-1:0] tag_0;
   logic [TAG_SZ-1:0] tag_1;
   logic [TAG_SZ-1:0] tag_2;
   logic [TAG_SZ-1:0] tag_3;
   logic [TAG_SZ-1:0] tag_4;
   logic [TAG_SZ-1:0] tag_5;
   logic [TAG_SZ-1:0] tag_6;
   logic [TAG_SZ-1:0] tag_7;

   logic [BITS-1:0] cache_data_0;
   logic [BITS-1:0] cache_data_1;
   logic [BITS-1:0] cache_data_2;
   logic [BITS-1:0] cache_data_3;
   logic [BITS-1:0] cache_data_4;
   logic [BITS-1:0] cache_data_5;
   logic [BITS-1:0] cache_data_6;
   logic [BITS-1:0] cache_data_7;

   logic val_0;
   logic val_1;
   logic val_2;
   logic val_3;
   logic val_4;
   logic val_5;
   logic val_6;
   logic val_7;

   logic cache_full;              //for the new output cache_full added

   cam2 cam2( .cache_data(cache_data), .cache_hit(cache_hit),

            .check_tag(check_tag), .read(read),
            .cache_full(cache_full),

            .write_(write_), .w_addr(w_addr),
            .wdata(wdata), .new_tag(new_tag), .new_valid(new_valid),

            .clk(clk), .rst_(rst_) );

   initial
   begin
     w_addr    = 3'b0;
     wdata     = 8'h0;
     new_tag   = 8'h1;
     read      = 1'b0;
     write_    = 1'b1;
     check_tag = 8'h0;
     new_valid = 1'b1;
     #10;
     write_    = 1'b0;
     new_tag = 8'h5; wdata = 8'h11; w_addr = 3'h1;
     wait(clk == 1'b1);
     wait(clk == 1'b0);

     new_tag = 8'h6; wdata = 8'h13; w_addr = 3'h3;
     wait(clk == 1'b1);
     wait(clk == 1'b0);

     new_tag = 8'h0; wdata = 8'h15; w_addr = 3'h5;
     wait(clk == 1'b1);
     wait(clk == 1'b0);

     new_tag = 8'h4; wdata = 8'h16; w_addr = 3'h6;
     wait(clk == 1'b1);
     wait(clk == 1'b0);

     new_tag = 8'h9; wdata = 8'h17; w_addr = 3'h7;
     wait(clk == 1'b1);
     wait(clk == 1'b0);
     write_ = 1'b1;
     read   = 1'b1;
     new_valid = 1'b0;
     new_tag = 8'h0;
     check_tag = 8'h0; wdata = 8'h0; w_addr = 3'h0;

     wait(clk == 1'b1);
     wait(clk == 1'b0);
     check_tag = 8'h5;
     wait(clk == 1'b1);
     wait(clk == 1'b0);
     check_tag = 8'h6;
     wait(clk == 1'b1);
     wait(clk == 1'b0);
     check_tag = 8'h7;
     wait(clk == 1'b1);
     wait(clk == 1'b0);
     check_tag = 8'h0;
     wait(clk == 1'b1);
     wait(clk == 1'b0);
     check_tag = 8'h4;
     wait(clk == 1'b1);
     wait(clk == 1'b0);
     check_tag = 8'h9;
     wait(clk == 1'b1);
     wait(clk == 1'b0);
     check_tag = 8'h1;
     wait(clk == 1'b1);
     wait(clk == 1'b0);
    //  $finish; 
    //as the finish is being called below
   end

   initial
   begin
     clk <= 1'b0;
     rst_ <= 1'b0;
     #10 rst_ <= 1'b1;
     while ( 1'b1 )
     begin
        #10 clk <= 1'b1;
        #10 clk <= 1'b0;
     end
   end

   initial
     begin
      $dumpfile("cam.vcd");      // dump the waves
      $dumpvars(0,top_cam2);
   end


   always @(posedge clk) begin
    $display("cache_full = %b, cache_data = %h, cache_hit = %b", cache_full, cache_data, cache_hit);

  end

  


   assign tag_0 = cam2.tag_mem[0];
   assign tag_1 = cam2.tag_mem[1];
   assign tag_2 = cam2.tag_mem[2];
   assign tag_3 = cam2.tag_mem[3];
   assign tag_4 = cam2.tag_mem[4];
   assign tag_5 = cam2.tag_mem[5];
   assign tag_6 = cam2.tag_mem[6];
   assign tag_7 = cam2.tag_mem[7];

   assign cache_data_0 = cam2.cache_data_mem[0];
   assign cache_data_1 = cam2.cache_data_mem[1];
   assign cache_data_2 = cam2.cache_data_mem[2];
   assign cache_data_3 = cam2.cache_data_mem[3];
   assign cache_data_4 = cam2.cache_data_mem[4];
   assign cache_data_5 = cam2.cache_data_mem[5];
   assign cache_data_6 = cam2.cache_data_mem[6];
   assign cache_data_7 = cam2.cache_data_mem[7];

   assign val_0 = cam2.val_mem[0];
   assign val_1 = cam2.val_mem[1];
   assign val_2 = cam2.val_mem[2];
   assign val_3 = cam2.val_mem[3];
   assign val_4 = cam2.val_mem[4];
   assign val_5 = cam2.val_mem[5];
   assign val_6 = cam2.val_mem[6];
   assign val_7 = cam2.val_mem[7];

  // Fill all CAM entries and check "cache_full"
integer fill_idx;
initial begin
    // Reset and initial entries as usual...

    // Fill every CAM entry to trigger "cache_full"
    for (fill_idx = 0; fill_idx < WORDS; fill_idx++) begin
        w_addr    = fill_idx;
        wdata     = fill_idx + 8'h20;  // any data
        new_tag   = fill_idx + 8'h10;  // unique tag per entry
        new_valid = 1'b1;
        write_    = 1'b0;
        read      = 1'b0;
        wait(clk == 1'b1);
        wait(clk == 1'b0);
        write_    = 1'b1;
    end

    // Wait one more cycle and check "cache_full"
    wait(clk == 1'b1);
    if (!cache_full)
        $error("CAM should be cache_full after filling all entries!");

    // Try writing once more after cache_full
    w_addr    = 0;
    wdata     = 8'hFF;
    new_tag   = 8'hFF;
    new_valid = 1'b1;
    write_    = 1'b0;
    wait(clk == 1'b1);
    wait(clk == 1'b0);
    write_    = 1'b1;

    // Confirm "cache_full" is still set
    if (!cache_full)
        $error("CAM 'cache_full' output should remain set after attempt to overfill!");
    #100; //to make sure, everything has been done
    $finish;
end



endmodule
