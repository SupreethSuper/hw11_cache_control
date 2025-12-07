`timescale 1ns/1ps

module tb_ca_ctrl_error_log0;

    localparam CACHE_ENTRIES    = 8;
    localparam CACHE_ADDR_LEFT  = $clog2(CACHE_ENTRIES) - 1;

    // DUT ports
    logic                     cache_read;
    logic                     cache_write_;
    logic [CACHE_ADDR_LEFT:0] cache_w_addr;
    logic                     new_valid;
    logic                     cache_stall;

    logic                     cache_hit;
    logic                     cache_full;
    logic                     branch_or_jump;
    logic                     clk;
    logic                     rst_;

    // Instantiate DUT
    ca_ctrl #(
        .CACHE_ENTRIES(CACHE_ENTRIES),
        .CACHE_ADDR_LEFT(CACHE_ADDR_LEFT)
    ) dut (
        .cache_read   (cache_read),
        .cache_write_ (cache_write_),
        .cache_w_addr (cache_w_addr),
        .new_valid    (new_valid),
        .cache_stall  (cache_stall),

        .cache_hit    (cache_hit),
        .cache_full   (cache_full),
        .branch_or_jump(branch_or_jump),
        .clk          (clk),
        .rst_         (rst_)
    );

    // Clock
    initial clk = 0;
    always #5 clk = ~clk;

    // Simple access to internals for debug
    typedef enum logic [1:0] {
        IDLE  = 2'h0,
        LOAD  = 2'h1,
        CLEAR = 2'h2
    } state_t;

    state_t cs;
    logic [CACHE_ADDR_LEFT:0] addr_counter_q;

    // Probes into DUT (this is legal in SV for TB)
    always_comb begin
        cs             = state_t'(dut.current_state[1:0]);  
        addr_counter_q = dut.addr_counter;
    end


    // Pretty-print state name
    function string state_name(state_t s);
        case (s)
            IDLE:  state_name = "IDLE ";
            LOAD:  state_name = "LOAD ";
            CLEAR: state_name = "CLEAR";
            default: state_name = "UNKWN";
        endcase
    endfunction

    // Monitor
    always @(posedge clk) begin
        $display("[%0t] state=%s  hit=%0b full=%0b  stall=%0b  wr_=%0b  new_valid=%0b  w_addr=%0d  cnt=%0d",
                 $time, state_name(cs), cache_hit, cache_full,
                 cache_stall, cache_write_, new_valid, cache_w_addr, addr_counter_q);
    end

    // Stimulus
    initial begin
        $display("\n=== tb_ca_ctrl_error_log0: starting ===\n");

        // init
        cache_hit      = 1'b1;
        cache_full     = 1'b0;
        branch_or_jump = 1'b0;
        rst_           = 1'b0;

        repeat (3) @(posedge clk);
        rst_ = 1'b1;
        @(posedge clk);

        // 1) A few hits in IDLE: state should stay IDLE, no stall
        $display("\n--- Phase 1: steady hits ---\n");
        cache_hit  = 1'b1;
        cache_full = 1'b0;
        repeat (4) @(posedge clk);

        // 2) Miss, not full: IDLE -> LOAD -> IDLE, counter increments once
        $display("\n--- Phase 2: miss, not full (IDLE -> LOAD -> IDLE) ---\n");
        cache_hit  = 1'b0;
        cache_full = 1'b0;   // not full miss
        @(posedge clk);      // should go IDLE -> LOAD
        cache_hit  = 1'b0;   // doesn't matter during LOAD; next_state is IDLE
        cache_full = 1'b0;
        @(posedge clk);      // LOAD -> IDLE
        cache_hit  = 1'b1;   // back to hit
        @(posedge clk);

        // 3) Miss, full: IDLE -> CLEAR -> LOAD -> IDLE
        $display("\n--- Phase 3: miss, full (IDLE -> CLEAR -> LOAD -> IDLE) ---\n");
        cache_hit  = 1'b0;
        cache_full = 1'b1;   // full miss
        @(posedge clk);      // IDLE -> CLEAR
        @(posedge clk);      // CLEAR -> LOAD
        @(posedge clk);      // LOAD  -> IDLE (hit/miss irrelevant in LOAD)

        // 4) Branch/jump: stall should be masked when branch_or_jump = 1
        $display("\n--- Phase 4: branch_or_jump masks stall ---\n");
        cache_hit      = 1'b0;
        cache_full     = 1'b1;   // cause miss+full
        branch_or_jump = 1'b1;   // pretend we're branching
        @(posedge clk);          // IDLE -> CLEAR, but stall should be 0 at PC side
        @(posedge clk);          // CLEAR -> LOAD, still masked
        branch_or_jump = 1'b0;
        @(posedge clk);          // LOAD -> IDLE, normal

        $display("\n=== tb_ca_ctrl_error_log0: done ===\n");
        $finish;
    end

endmodule
