module ca_ctrl #(
    // How many entries in the cache
    parameter int CACHE_ENTRIES   = 8,

    // log2 of the number of entries
    parameter int CACHE_ADDR_LEFT = $clog2(CACHE_ENTRIES) - 1
)(
    // Ok to read from the cache
    output logic                     cache_read,

    // Write (active low) to clear or set an entry
    output logic                     cache_write_,

    // Address to clear / update
    output logic [CACHE_ADDR_LEFT:0] cache_w_addr,

    // Whether the targeted entry becomes valid
    output logic                     new_valid,

    // Assert when the cache causes a pipeline stall
    output logic                     cache_stall,

    input  logic                     cache_hit,
    input  logic                     cache_full,
    input  logic                     branch_or_jump,
    input  logic                     clk,
    input  logic                     rst_
);

    // Cache control logic to be implemented here


    //-----------------FSM  controls-----------------------------
    localparam STATE_BITS = 2;
    localparam [STATE_BITS - 1 : 0] IDLE  = 2'h0; //IDLE
    localparam [STATE_BITS - 1 : 0] LOAD  = 2'h1; //LOAD FROM MEM
    localparam [STATE_BITS - 1 : 0] CLEAR = 2'h2; //CLEAR A MEM LOC
    //---------------------------------------------------------

    logic current_state;

    logic [CACHE_ADDR_LEFT : 0] addr_counter;

    //------------------counter-----------------------------------------

    always_ff @( posedge clk or negedge rst_ ) begin : counter
        if(!rst_) begin
            addr_counter <= '0;
        end
        
        else begin
            if(current_state == CLEAR) begin
                if(addr_counter == CACHE_ENTRIES - 1) begin
                    addr_counter <= '0;
                end

                else begin
                    addr_counter <= addr_counter + 1'b1;
                end
            
            end
        end
    end


endmodule
