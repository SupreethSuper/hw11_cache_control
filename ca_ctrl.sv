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


    logic [STATE_BITS - 1 : 0] current_state;
    logic [STATE_BITS - 1 : 0] next_state;
    logic staller;




    logic [CACHE_ADDR_LEFT : 0] addr_counter;

    

    always_ff @(posedge clk or negedge rst_) begin
        if (!rst_) begin
            current_state <= IDLE;
        end else begin
            current_state <= next_state;
        end
    end


    // WARNING: This is a hack. Leaving this here will summon demons
    // assign cache_hit = '0;
    // assign cache_full = '0;

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
            else begin
                addr_counter <= '0;
            end
        end
    end

    always_comb begin : STATE_MACHINE
        cache_w_addr = addr_counter;

        if(branch_or_jump) begin
            next_state = IDLE;
        end

       
        case (current_state)

    // ----------------------IDLE-----------------------
        IDLE    : begin           

            cache_read = 1'b0;
            cache_write_ = 1'b1;
            new_valid = '0;
            cache_stall = 1'b0;
            if ( ( !cache_hit ) && ( !cache_full ) ) begin
                next_state = LOAD;
            end
            else if( (!cache_hit) && (cache_full) ) begin
                next_state = CLEAR;
            end
            if (branch_or_jump) begin
                next_state = IDLE;
            end
        end
    //-----------------------------------------------------

        LOAD : begin
                       
            new_valid = 1'b1;
        
            cache_read = 1'b1;
            cache_write_ = 1'b1;
            cache_stall = 1'b1;

        //==============LOAD TO IDLE AND CLEAR================
            // cache_stall = !branch_or_jump;
            if(!cache_hit) begin
                if(cache_full) begin
                    next_state = CLEAR;
                end
            end
            else begin
                next_state = IDLE;
            end
        end
        //========================================================


        CLEAR : begin

            new_valid = 1'b1;
            cache_read = 1'b0;
            cache_write_ = 1'b0;
            cache_stall = 1'b1;
            


        //=============CLEAR TO LOAD AND IDLE=================    
            // cache_stall = !branch_or_jump;
            if(cache_hit) begin
                next_state = IDLE;

            end

            else begin
                if(!cache_full) begin
                    next_state = LOAD;
                end
            end
        end
        //==================================================



            default: begin
                next_state = IDLE;

            end
        endcase
       
    end


endmodule
