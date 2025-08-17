`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 15.06.2025 10:39:41
// Design Name: 
// Module Name: tb_inc
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


`timescale 1ns / 1ps

module tb_inc;

  // --- Testbench Parameters ---
parameter CLK_PERIOD = 10; // Clock period of 10ns

// --- Testbench Signals ---
reg         clk;
reg         rst;
reg         start;
reg         mode;
reg [3:0]   inp_req;
reg [7:0]   priority_def;
wire [3:0]  out_ack;

// --- Instantiate the Device Under Test (DUT) ---
inc dut (
    .clk(clk),
    .rst(rst),
    .start(start),
    .mode(mode),
    .inp(inp_req),
    .priority(priority_def),
    .out(out_ack)
);

// ===================================================================
//  Clock Generator
// ===================================================================
always begin
    clk = 1'b1; #(CLK_PERIOD/2);
    clk = 1'b0; #(CLK_PERIOD/2);
end

// ===================================================================
//  Verification Task
// ===================================================================
// This task checks if the output matches the expected value.
task check_output;
    input [3:0] expected_ack;
    input [100:0] test_name; // A string to describe the test
    begin
        if (out_ack === expected_ack) begin
            $display("[PASSED] %s | Expected: %b, Got: %b", test_name, expected_ack, out_ack);
        end else begin
            $display("[FAILED] %s | Expected: %b, Got: %b", test_name, expected_ack, out_ack);
        end
    end
endtask

// ===================================================================
//  Test Sequence
// ===================================================================
initial begin
    // --- Initialization ---
    $display("=====================================================");
    $display("               Starting Testbench");
    $display("=====================================================");
    rst = 1'b1;
    start = 1'b0;
    mode = 1'b0; // Default to priority mode
    inp_req = 4'b0000;
    priority_def = 8'h00;
    # (CLK_PERIOD * 2);
    rst = 1'b0;
    # (CLK_PERIOD);

    // --- Test Case 1: Priority Mode ---
    $display("\n--- Testing Priority Mode ---");
    mode = dut.PRIORITY;
    
    // Set priority: 2 (highest) -> 0 -> 1 -> 3 (lowest)
    // Priority levels: P3=2, P2=0, P1=1, P0=3
    priority_def = {2'b11, 2'b01, 2'b00, 2'b10}; // Corresponds to {req3, req2, req1, req0}
    
    // Load the priority definition
    start = 1'b1;
    #CLK_PERIOD;
    start = 1'b0;
    #CLK_PERIOD;

    // Test 1.1: Highest priority interrupt (req 2)
    inp_req = 4'b0100; #CLK_PERIOD;
    check_output(4'b0100, "Priority: Highest (req 2)");

    // Test 1.2: Multiple interrupts, highest should win
    inp_req = 4'b1111; #CLK_PERIOD;
    check_output(4'b0100, "Priority: Multiple req, highest wins");

    // Test 1.3: Second highest priority interrupt (req 0)
    inp_req = 4'b1001; #CLK_PERIOD;
    check_output(4'b0001, "Priority: Second highest (req 0)");

    // Test 1.4: Lowest priority interrupt (req 3)
    inp_req = 4'b1000; #CLK_PERIOD;
    check_output(4'b1000, "Priority: Lowest (req 3)");

    // Test 1.5: No interrupts active
    inp_req = 4'b0000; #CLK_PERIOD;
    check_output(4'b0000, "Priority: No requests");
    
    # (CLK_PERIOD * 2);

    // --- Test Case 2: Polling Mode ---
    $display("\n--- Testing Polling Mode ---");
    mode = dut.POLLING;
    inp_req = 4'b0000;
    #CLK_PERIOD;

    // Test 2.1: Poll for req 2. Expect latency.
    inp_req = 4'b0100;
    $display("Polling: Asserted req 2. Waiting for poller...");
    #CLK_PERIOD; // Poller at state 0, checks req 0 (miss)
    check_output(4'b0000, "Polling: State 0, no ack");
    #CLK_PERIOD; // Poller at state 1, checks req 1 (miss)
    check_output(4'b0000, "Polling: State 1, no ack");
    #CLK_PERIOD; // Poller at state 2, checks req 2 (hit!)
    check_output(4'b0000, "Polling: State 2, finds req 2");
    #CLK_PERIOD; // Poller stays at state 2
    check_output(4'b0100, "Polling: Stays on req 2");
    
    // De-assert req 2 to let poller move on
    inp_req = 4'b0000; #CLK_PERIOD;
    check_output(4'b0000, "Polling: De-assert req 2");
    #CLK_PERIOD;
    #CLK_PERIOD;

    // Test 2.2: Multiple requests, service in order
    inp_req = 4'b1010; // req 1 and req 3 are active
    $display("Polling: Asserted req 1 and 3. Waiting...");
    #CLK_PERIOD; // Poller moves to state 3 (miss)
    #CLK_PERIOD; // Poller moves to state 0 (miss)
    #CLK_PERIOD; // Poller moves to state 1 (hit!)
    check_output(4'b0010, "Polling: Finds req 1 first");
    
    // De-assert req 1, poller should find req 3
    inp_req = 4'b1000; #CLK_PERIOD;
    check_output(4'b0000, "Polling: De-assert req 1");
    #CLK_PERIOD; // Poller moves to state 2 (miss)
    #CLK_PERIOD; // Poller moves to state 3 (hit!)
    check_output(4'b1000, "Polling: Finds req 3");
    
    // De-assert req 3
    inp_req = 4'b0000; #CLK_PERIOD;
    check_output(4'b0000, "Polling: De-assert req 3");

    // --- End of Simulation ---
    # (CLK_PERIOD * 5);
    $display("\n=====================================================");
    $display("                Testbench Finished");
    $display("=====================================================");
    $finish;
end

// Optional: Monitor to see signal changes during simulation
initial begin
    $monitor("Time=%0t | rst=%b mode=%b | inp_req=%b | out_ack=%b | poll_state=%d",
             $time, rst, mode, inp_req, out_ack, dut.poll_state);
end

endmodule



