// =============================================================================
// core_mac.v  —  Multiply-Accumulate Core
// GPU Make | Xilinx Artix-7 target | Verilog POC
//
// Performs:  acc += A[i] * B[i]   for N elements (dot product)
// Datapath  : combinational multiply, registered accumulate
// Input     : 8-bit signed × 8-bit signed
// Output    : 32-bit signed accumulator
//
// Protocol:
//   1. Assert `start` for exactly 1 clock with the first (a_in, b_in) element.
//   2. Drive (a_in, b_in) for VEC_LEN consecutive clocks (including start clock).
//   3. After VEC_LEN clocks `valid` pulses high and `result` holds the answer.
// =============================================================================

`timescale 1ns/1ps

module core_mac #(
    parameter DATA_WIDTH = 8,
    parameter ACC_WIDTH  = 32,
    parameter VEC_LEN    = 16        // dot-product vector length
)(
    input  wire                          clk,
    input  wire                          rst_n,
    input  wire                          start,        // 1-cycle pulse: begin dot-product
    input  wire signed [DATA_WIDTH-1:0]  a_in,         // element of vector A
    input  wire signed [DATA_WIDTH-1:0]  b_in,         // element of vector B
    output reg  signed [ACC_WIDTH-1:0]   result,       // latched final result
    output reg                           valid          // 1-cycle pulse: result is ready
);

    // -------------------------------------------------------------------------
    // Combinational product (DSP48 will infer this on Artix-7)
    // -------------------------------------------------------------------------
    wire signed [2*DATA_WIDTH-1:0] product = a_in * b_in;

    // -------------------------------------------------------------------------
    // Accumulator + FSM
    // -------------------------------------------------------------------------
    reg signed [ACC_WIDTH-1:0]   acc;
    reg [$clog2(VEC_LEN):0]      count;
    reg                          running;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            acc     <= 0;
            count   <= 0;
            running <= 1'b0;
            valid   <= 1'b0;
            result  <= 0;
        end else begin
            valid <= 1'b0;  // default deasserted

            if (start && !running) begin
                // First element: clear accumulator, count=1, capture product
                acc     <= {{(ACC_WIDTH - 2*DATA_WIDTH){product[2*DATA_WIDTH-1]}}, product};
                count   <= 1;
                running <= 1'b1;
            end else if (running) begin
                acc   <= acc + {{(ACC_WIDTH - 2*DATA_WIDTH){product[2*DATA_WIDTH-1]}}, product};
                count <= count + 1;

                if (count == VEC_LEN - 1) begin
                    // All elements consumed — latch result next cycle
                    result  <= acc + {{(ACC_WIDTH - 2*DATA_WIDTH){product[2*DATA_WIDTH-1]}}, product};
                    valid   <= 1'b1;
                    running <= 1'b0;
                    count   <= 0;
                end
            end
        end
    end

endmodule
