`timescale 1ns / 1ps

module upcounter_4bit(
    input  wire       clk,
    input  wire       reset,   // Active-high asynchronous reset
    input  wire       enable,  // High to count, low to hold state
    
    // --- DFT Ports ---
    input  wire       scan_en,
    input  wire       scan_in,
    input  wire       test_mode,
    output wire       scan_out,
    // -----------------
    
    output reg  [3:0] count
);

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            count <= 4'b0000;
        end else if (enable) begin
            count <= count + 1'b1;
        end
        // If enable is 0, it implicitly holds its state
    end
    
    // Tie off scan_out for RTL simulation; Genus overrides this during DFT
    assign scan_out = 1'b0;

endmodule


