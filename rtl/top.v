// =============================================================================
// top.v  —  Top-Level GPU Module
// GPU Make | Xilinx Artix-7 target | Verilog POC
//
// Architecture:
//   Host → [Core A: MAC] → [Core B: ReLU] → Output
//
// The two cores form a minimal ML inference pipeline:
//   1. MAC core computes the dot product of two 8-bit vectors (one neuron)
//   2. ReLU core applies the activation function to the accumulator output
//
// This can be replicated N times in parallel for a full layer.
// =============================================================================

`timescale 1ns/1ps

module top #(
    parameter DATA_WIDTH = 8,
    parameter ACC_WIDTH  = 32,
    parameter VEC_LEN    = 16
)(
    input  wire                  clk,
    input  wire                  rst_n,

    // --- Host interface (simplified, no AXI for POC) ---
    input  wire                  start,              // begin computation
    input  wire signed [DATA_WIDTH-1:0] a_in,       // weight vector element
    input  wire signed [DATA_WIDTH-1:0] b_in,       // input vector element

    // --- Output ---
    output wire [ACC_WIDTH-1:0]  relu_out,           // activated neuron output
    output wire                  output_valid         // result is ready
);

    // -------------------------------------------------------------------------
    // Internal wires — connecting Core A (MAC) → Core B (ReLU)
    // -------------------------------------------------------------------------
    wire signed [ACC_WIDTH-1:0] mac_result;
    wire                        mac_valid;

    // -------------------------------------------------------------------------
    // Core A: MAC — Dot Product
    // -------------------------------------------------------------------------
    core_mac #(
        .DATA_WIDTH (DATA_WIDTH),
        .ACC_WIDTH  (ACC_WIDTH),
        .VEC_LEN    (VEC_LEN)
    ) u_mac (
        .clk    (clk),
        .rst_n  (rst_n),
        .start  (start),
        .a_in   (a_in),
        .b_in   (b_in),
        .result (mac_result),
        .valid  (mac_valid)
    );

    // -------------------------------------------------------------------------
    // Core B: ReLU — Activation Function
    // -------------------------------------------------------------------------
    core_relu #(
        .DATA_WIDTH (ACC_WIDTH)
    ) u_relu (
        .clk           (clk),
        .rst_n         (rst_n),
        .data_valid_in (mac_valid),
        .data_in       (mac_result),
        .data_valid_out(output_valid),
        .data_out      (relu_out)
    );

endmodule
