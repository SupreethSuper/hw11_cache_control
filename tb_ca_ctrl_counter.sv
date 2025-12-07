`timescale 1ns/1ps

module tb_ca_ctrl_counter;

    // PARAMETERS
    localparam CACHE_ENTRIES = 8;
    localparam CACHE_ADDR_LEFT = $clog2(CACHE_ENTRIES) - 1;

    // DUT Ports
    logic cache_read;
    logic cache_write_;
    logic [CACHE_ADDR_LEFT:0] cache_w_addr;
    logic new_valid;
    logic cache_stall;

    logic cache_hit = 0;
    logic cache_full = 0;
    logic branch_or_jump = 0;

    logic clk = 0;
    logic rst_ = 0;

    // Instantiate DUT
    ca_ctrl #(
        .CACHE_ENTRIES(CACHE_ENTRIES),
        .CACHE_ADDR_LEFT(CACHE_ADDR_LEFT)
    ) dut (
        .cache_read(cache_read),
        .cache_write_(cache_write_),
        .cache_w_addr(cache_w_addr),
        .new_valid(new_valid),
        .cache_stall(cache_stall),

        .cache_hit(cache_hit),
        .cache_full(cache_full),
        .branch_or_jump(branch_or_jump),
        .clk(clk),
        .rst_(rst_)
    );

    // Clock generation
    always #5 clk = ~clk;   // 10ns clock period

    // Expected counter mirror
    logic [CACHE_ADDR_LEFT:0] expected;

    // TEST PROCEDURE
    initial begin
        $display("\n--- Testing addr_counter increment & wrap ---\n");

        rst_ = 0;
        expected = 0;
        repeat (2) @(posedge clk);
        rst_ = 1;

        // Force the internal state to CLEAR
        // force dut.current_state = dut.CLEAR;

        repeat (10) begin
            @(posedge clk);

            // Compare expected vs actual
            if (dut.addr_counter !== expected) begin
                $display("ERROR at time %0t: expected %0d, got %0d",
                          $time, expected, dut.addr_counter);
            end else begin
                $display("OK at %0t: counter = %0d", $time, dut.addr_counter);
            end

            // Update expected value
            if (expected == CACHE_ENTRIES - 1)
                expected = 0;
            else
                expected = expected + 1;
        end

        // Release forced signal
        release dut.current_state;

        $display("\n--- Test Complete ---\n");
        $finish;
    end

endmodule
