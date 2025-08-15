`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05.08.2025 11:05:43
// Design Name: 
// Module Name: priority_controller
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


module priority_controller #(
    parameter NUM_TASKS = 4,
    parameter TASK_ID_WIDTH = $clog2(NUM_TASKS)
) (
    // Standard Inputs
    input           clk,
    input           rst,
    input           start,

    input  [NUM_TASKS-1:0]                inp,
    input  [NUM_TASKS*TASK_ID_WIDTH-1:0]  priority_def,
    input  [NUM_TASKS-1:0]                resource_needed,


    output reg [NUM_TASKS-1:0]            out,
    output reg                            resource_locked,
    output reg [TASK_ID_WIDTH-1:0]        resource_owner
);

    reg [TASK_ID_WIDTH-1:0] value [NUM_TASKS-1:0];
    
    reg [NUM_TASKS-1:0]            next_out;
    reg [TASK_ID_WIDTH-1:0]        next_value [NUM_TASKS-1:0];
    reg                            next_resource_locked;
    reg [TASK_ID_WIDTH-1:0]        next_resource_owner;

    reg [TASK_ID_WIDTH-1:0] static_winner_id;
    reg [TASK_ID_WIDTH-1:0] static_winner_prio;
    reg [TASK_ID_WIDTH-1:0] owner_prio;
    
    integer i;
    reg found_winner;

    // ===================================================================
    //  Block 1: Sequential Logic (State Updates on Clock Edge)
    // ===================================================================
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            out <= 0; // Automatically sized to all zeros
            resource_locked <= 1'b0;
            resource_owner  <= 0;
            for (i = 0; i < NUM_TASKS; i = i + 1) begin
                value[i] <= 0;
            end
        end else begin
            out <= next_out;
            resource_locked <= next_resource_locked;
            resource_owner  <= next_resource_owner;
            for (i = 0; i < NUM_TASKS; i = i + 1) begin
                value[i] <= next_value[i];
            end
        end
    end

    // ===================================================================
    //  Block 2: Combinational Logic (Calculates Next State and Outputs)
    // ===================================================================
    always @(*) begin

        next_out = out;
        next_resource_locked = resource_locked;
        next_resource_owner = resource_owner;
        for (i = 0; i < NUM_TASKS; i = i + 1) begin
            next_value[i] = value[i];
        end

        if (start) begin
            for (i = 0; i < NUM_TASKS; i = i + 1) begin

                next_value[i] = priority_def[i*TASK_ID_WIDTH +: TASK_ID_WIDTH];
            end
        end

        begin
            
            found_winner = 1'b0;
            static_winner_id = 0; 
            static_winner_prio = 0;
            for (i = NUM_TASKS - 1; i >= 0; i = i - 1) begin
                if (!found_winner && inp[value[i]]) begin
                    static_winner_id = value[i];
                    static_winner_prio = i;
                    found_winner = 1'b1;
                end
            end
        end

        owner_prio = priority_def[resource_owner*TASK_ID_WIDTH +: TASK_ID_WIDTH];

        if (resource_locked && resource_needed[static_winner_id] && (static_winner_prio > owner_prio)) begin

            next_out = (1'b1 << resource_owner);
        end else begin

            if (resource_needed[static_winner_id] && resource_locked) begin
                next_out = 0;
            end else if (inp == 0) begin
                next_out = 0;
            end
            else begin
                next_out = (1'b1 << static_winner_id);
            end
        end

        if (!resource_locked && resource_needed[static_winner_id] && (next_out == (1'b1 << static_winner_id))) begin
            next_resource_locked = 1'b1;
            next_resource_owner = static_winner_id;
        end
        else if (resource_locked && inp[resource_owner] == 1'b0) begin
            next_resource_locked = 1'b0;
        end
    end
endmodule



