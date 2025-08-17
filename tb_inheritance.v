`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 
// Design Name: 
// Module Name: tb_priority_controller
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



module tb_priority_controller;

    // ===================================================================
    //  Testbench Parameters - Match these with the DUT instantiation
    // ===================================================================
    parameter NUM_TASKS = 4;
    parameter TASK_ID_WIDTH = $clog2(NUM_TASKS);
    parameter CLK_PERIOD = 10;

    // --- Testbench Signals ---
    reg                                 clk;
    reg                                 rst;
    reg                                 start;
    reg [NUM_TASKS-1:0]                 inp;
    reg [NUM_TASKS*TASK_ID_WIDTH-1:0]   priority_def;
    reg [NUM_TASKS-1:0]                 resource_needed;

    wire [NUM_TASKS-1:0]                out;
    wire                                resource_locked;
    wire [TASK_ID_WIDTH-1:0]            resource_owner;

    // --- Instantiate the Device Under Test (DUT) ---
    priority_controller #(
        .NUM_TASKS(NUM_TASKS),
        .TASK_ID_WIDTH(TASK_ID_WIDTH)
    ) dut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .inp(inp),
        .priority_def(priority_def),
        .resource_needed(resource_needed),
        .out(out),
        .resource_locked(resource_locked),
        .resource_owner(resource_owner)
    );

    // ===================================================================
    //  Clock Generator & Verification Task
    // ===================================================================
    always # (CLK_PERIOD/2) clk = ~clk;

    task check_output;
        input [NUM_TASKS-1:0] expected_out;
        input [150:0] test_name;
        begin
            if (out === expected_out)
                $display("[PASSED] %s | Expected: %b, Got: %b", test_name, expected_out, out);
            else
                $display("[FAILED] %s | Expected: %b, Got: %b", test_name, expected_out, out);
        end
    endtask

    // ===================================================================
    //  Main Test Sequence
    // ===================================================================
    initial begin
        // --- Initialization ---
        $display("================ Starting Testbench ================");
        clk = 1'b1;
        rst = 1'b1;
        start = 1'b0;
        inp = 0;
        priority_def = 0;
        resource_needed = 0;
        # (CLK_PERIOD * 2);
        rst = 1'b0;
        # (CLK_PERIOD);

        // --- Test Case 1: Configure Priorities and Resources ---
        $display("\n--- Test 1: Configuring Priorities and Resources ---");
        // Priority: T3(High) > T2 > T1 > T0(Low)
        // This means priority level 3 is for task 3, level 2 for task 2, etc.
        priority_def = {2'b11, 2'b10, 2'b01, 2'b00}; 
        // Resources: Task 0 (Low) and Task 3 (High) need the shared resource.
        resource_needed = (1 << 3) | (1 << 0); // 4'b1001
        
        start = 1'b1;
        #CLK_PERIOD;
        start = 1'b0;
        #CLK_PERIOD;
        $display("Configuration loaded. Resource needed by tasks: %b", resource_needed);

        // --- Test Case 2: Normal Priority (No resource contention) ---
        $display("\n--- Test 2: Normal Priority ---");
        inp = (1 << 1); // Task 1 (Medium-Low) requests
        #CLK_PERIOD;
        check_output( (1 << 1), "Grant to Task 1");
        
        inp = (1 << 1) | (1 << 2); // Task 2 (Medium-High) requests
        #CLK_PERIOD;
        check_output( (1 << 2), "Grant preempts to higher priority Task 2");
        
        inp = 0;
        #CLK_PERIOD;
        check_output(0, "Grant cleared");

        // --- Test Case 3: Priority Inversion and Inheritance ---
        $display("\n--- Test 3: Priority Inversion Scenario ---");
        // Step 1: Low-priority task (T0) requests and locks the resource.
        inp = (1 << 0); // T0 requests
        #CLK_PERIOD;
        check_output( (1 << 0), "Step 3.1: Grant to T0");
        $display("Resource state: locked=%b, owner=%d", resource_locked, resource_owner);

        // Step 2: High-priority task (T3) requests the same resource and gets blocked.
        inp = (1 << 0) | (1 << 3); // T0 and T3 request
        #CLK_PERIOD;
        check_output( (1 << 0), "Step 3.2: T3 blocked, grant STAYS with T0 (owner)");
        $display("T3 is blocked by T0. Grant remains with T0.");
        
        // Step 3: Medium-priority task (T2, no resource needed) requests.
        // This is the moment of PRIORITY INVERSION.
        inp = (1 << 0) | (1 << 3) | (1 << 2); // T0, T3, T2 request
        #CLK_PERIOD;
        // ** THE CRITICAL CHECK **
        check_output( (1 << 0), "Step 3.3: PRIORITY INHERITANCE! Grant STAYS with T0, not T2.");
        $display("T2 is prevented from running. T0 inherits T3's priority.");
        
        // Step 4: Low-priority task (T0) finishes and releases the resource.
        inp = (1 << 3) | (1 << 2); // T0's request goes low
        #CLK_PERIOD;
        #CLK_PERIOD; 
        // Now that the resource is free, the grant should go to the highest-priority waiting task (T3).
        check_output( (1 << 3), "Step 3.4: T0 releases lock, grant goes to T3");
        $display("Resource state: locked=%b, owner=%d", resource_locked, resource_owner);

        // Step 5: High-priority task (T3) finishes.
        inp = (1 << 2); // T3's request goes low
        #CLK_PERIOD;
        check_output( (1 << 2), "Step 3.5: T3 releases, grant goes to T2");

        // --- NEW Test Case 4: Verify Priority Returns to Normal ---
        $display("\n--- Test 4: Verify Priority Inheritance is Temporary ---");
        // Step 1: Clear all requests from the previous test.
        inp = 0;
        #CLK_PERIOD;
        check_output(0, "Step 4.1: All requests cleared");

        // Step 2: Request from T0 (lowest) and T1 (medium-low).
        // If T0's priority was permanently boosted, it would win.
        // Since it should be temporary, T1 should win.
        inp = (1 << 0) | (1 << 1);
        #CLK_PERIOD;
        check_output( (1 << 1), "Step 4.2: Grant goes to T1, proving T0's priority is normal");
        $display("T0's priority has correctly returned to low.");

        // --- End of Simulation ---
        inp = 0;
        # (CLK_PERIOD * 5);
        $display("\n================ Testbench Finished ================");
        $finish;
    end

    // Optional: Monitor to see signal changes during simulation
    initial begin
        $monitor("Time=%0t | rst=%b | inp=%b | out=%b | locked=%b | owner=%d",
                 $time, rst, inp, out, resource_locked, resource_owner);
    end

endmodule


