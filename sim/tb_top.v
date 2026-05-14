// =============================================================================
// tb_top.v  —  Testbench for GPU Top-Level
// GPU Make | Simulation only (Icarus Verilog / ModelSim compatible)
//
// Tests:
//   T1 — Positive dot product  → ReLU passes through
//   T2 — Negative dot product  → ReLU clamps to zero
//   T3 — Zero vector           → Output is zero
// =============================================================================

`timescale 1ns/1ps

module tb_top;

    // -------------------------------------------------------------------------
    // Parameters (must match DUT)
    // -------------------------------------------------------------------------
    localparam DATA_WIDTH = 8;
    localparam ACC_WIDTH  = 32;
    localparam VEC_LEN    = 16;
    localparam CLK_PERIOD = 10;  // 10 ns → 100 MHz

    // -------------------------------------------------------------------------
    // DUT signals
    // -------------------------------------------------------------------------
    reg                          clk;
    reg                          rst_n;
    reg                          start;
    reg  signed [DATA_WIDTH-1:0] a_in;
    reg  signed [DATA_WIDTH-1:0] b_in;
    wire [ACC_WIDTH-1:0]         relu_out;
    wire                         output_valid;

    // -------------------------------------------------------------------------
    // DUT instantiation
    // -------------------------------------------------------------------------
    top #(
        .DATA_WIDTH (DATA_WIDTH),
        .ACC_WIDTH  (ACC_WIDTH),
        .VEC_LEN    (VEC_LEN)
    ) dut (
        .clk          (clk),
        .rst_n        (rst_n),
        .start        (start),
        .a_in         (a_in),
        .b_in         (b_in),
        .relu_out     (relu_out),
        .output_valid (output_valid)
    );

    // -------------------------------------------------------------------------
    // Clock generation: 100 MHz
    // -------------------------------------------------------------------------
    initial clk = 0;
    always #(CLK_PERIOD/2) clk = ~clk;

    // -------------------------------------------------------------------------
    // Task: feed VEC_LEN elements to the DUT
    //
    // Protocol (matches core_mac.v):
    //   Cycle 0 : start=1, a_in=val, b_in=val   (first element + start pulse)
    //   Cycle 1..VEC_LEN-1 : start=0, a_in=val, b_in=val
    //   After VEC_LEN cycles: inputs go idle
    // -------------------------------------------------------------------------
    task feed_vector;
        input signed [DATA_WIDTH-1:0] a_val;
        input signed [DATA_WIDTH-1:0] b_val;
        integer i;
        begin
            @(negedge clk);
            start = 1'b1;
            a_in  = a_val;
            b_in  = b_val;

            @(negedge clk);
            start = 1'b0;

            for (i = 1; i < VEC_LEN - 1; i = i + 1) begin
                a_in = a_val;
                b_in = b_val;
                @(negedge clk);
            end

            // Last element
            a_in = a_val;
            b_in = b_val;
            @(negedge clk);

            // Idle after vector is done
            a_in = 0;
            b_in = 0;
        end
    endtask

    // -------------------------------------------------------------------------
    // Task: wait for output_valid with timeout, then check result
    // -------------------------------------------------------------------------
    task check_output;
        input [ACC_WIDTH-1:0] expected;
        input integer         test_num;
        reg   [ACC_WIDTH-1:0] captured;
        begin
            captured = 0;

            // Poll for output_valid (max 60 cycles)
            begin : poll_loop
                integer k;
                for (k = 0; k < 60; k = k + 1) begin
                    @(posedge clk);
                    if (output_valid) begin
                        captured = relu_out;
                        disable poll_loop;
                    end
                end
            end

            #1; // tiny delta for signal settle

            if (captured === expected)
                $display("PASS T%0d: relu_out = %0d  (expected %0d)", test_num, captured, expected);
            else
                $display("FAIL T%0d: relu_out = %0d  (expected %0d)", test_num, captured, expected);
        end
    endtask

    // -------------------------------------------------------------------------
    // Stimulus
    // -------------------------------------------------------------------------
    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, tb_top);

        // Reset sequence
        rst_n = 1'b0;
        start = 1'b0;
        a_in  = 0;
        b_in  = 0;
        repeat(4) @(posedge clk);
        @(negedge clk);
        rst_n = 1'b1;
        repeat(2) @(posedge clk);

        // ------------------------------------------------------------------
        // T1: Positive dot product
        //   a=[2,2,...,2]  b=[3,3,...,3]  N=16
        //   MAC = 2*3*16 = 96  →  ReLU(96) = 96
        // ------------------------------------------------------------------
        $display("\n--- T1: Positive dot product ---");
        fork
            feed_vector(8'sd2, 8'sd3);
            check_output(32'd96, 1);
        join
        repeat(5) @(posedge clk);

        // ------------------------------------------------------------------
        // T2: Negative dot product
        //   a=[2,...] b=[-3,...] N=16
        //   MAC = -96  →  ReLU(-96) = 0
        // ------------------------------------------------------------------
        $display("\n--- T2: Negative dot product (ReLU clamp) ---");
        fork
            feed_vector(8'sd2, -8'sd3);
            check_output(32'd0, 2);
        join
        repeat(5) @(posedge clk);

        // ------------------------------------------------------------------
        // T3: Zero vector
        //   a=0 b=0  →  MAC=0  →  ReLU(0) = 0
        // ------------------------------------------------------------------
        $display("\n--- T3: Zero vector ---");
        fork
            feed_vector(8'sd0, 8'sd0);
            check_output(32'd0, 3);
        join
        repeat(5) @(posedge clk);

        $display("\n=== Simulation complete ===\n");
        $finish;
    end

endmodule
