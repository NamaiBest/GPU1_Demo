// =============================================================================
// core_relu.v  —  ReLU Activation Core
// GPU Make | Xilinx Artix-7 target | Verilog POC
//
// Performs:  out = max(0, in)   on a stream of signed 32-bit values
// Latency   : 1 cycle
// Throughput: 1 result per clock (fully pipelined)
// =============================================================================

`timescale 1ns/1ps

module core_relu #(
    parameter DATA_WIDTH = 32
)(
    input  wire                        clk,
    input  wire                        rst_n,
    input  wire                        data_valid_in,           // upstream valid
    input  wire signed [DATA_WIDTH-1:0] data_in,               // signed input
    output reg                         data_valid_out,          // downstream valid
    output reg         [DATA_WIDTH-1:0] data_out               // rectified output (unsigned)
);

    // -------------------------------------------------------------------------
    // ReLU: clamp negative values to zero, pass positives through
    // One-cycle registered path for clean timing closure on FPGA
    // -------------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out       <= 0;
            data_valid_out <= 1'b0;
        end else begin
            data_valid_out <= data_valid_in;
            if (data_valid_in)
                data_out <= (data_in[DATA_WIDTH-1]) ? {DATA_WIDTH{1'b0}} : data_in;
            else
                data_out <= 0;
        end
    end

endmodule
