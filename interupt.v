`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Ayush Aman
// 
// Create Date: 15.06.2025 09:15:51
// Design Name: 
// Module Name: inc
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


module inc(
        input [3:0] inp,
        input start,
        input clk,
        input rst,
        input [7:0] priority,
        input mode,
        output reg [3:0]  out
    );
    
parameter PRIORITY = 1'b0;
parameter POLLING  = 1'b1;

reg [1:0] value [3:0];

reg [1:0] poll_state;
parameter poll_0 = 2'b00,
          poll_1 = 2'b01,
          poll_2 = 2'b10,
          poll_3 = 2'b11;
          
          
reg [1:0] next_value [3:0];
reg [3:0] next_out;
reg [1:0] next_poll_state;


integer i;
always@(posedge clk)begin 

    if(rst)begin
        out<=0;
         poll_state <= poll_0;
         for (i =0; i<4; i=i+1)
            value[i]<= 0;
       end else begin 
            out<=next_out;
            poll_state<= next_poll_state;
            for ( i=0 ; i<4; i=i+1) 
                value[i]<= next_value[i];
         end 
     end  
                
always @(*) begin 
        next_out = out;
        next_poll_state = poll_state;
    
    
    for (i = 0; i < 4; i = i + 1) begin
       next_value[i] = value[i];
    end    
    
    
    
        if (mode==PRIORITY) begin 
            if(start) begin   
                    next_value[0] = priority[1:0];
                    next_value[1] = priority[3:2];
                    next_value[2] = priority[5:4];
                    next_value[3] = priority[7:6];
             end
             
             if (inp[value[0]]==1)
                 next_out= 4'b0001 << value[0];
               else if (inp[value[1]]==1)
                 next_out= 4'b0001 << value[1];
               else if (inp[value[2]]==1)
                 next_out= 4'b0001 << value[2];
               else if (inp[value[3]]==1)
                 next_out= 4'b0001 << value[3];
                else 
                    next_out= 4'b0000;
              end 
              
              
         else begin     
                next_out = 4'b0000;
                
                case (poll_state)   
                    poll_0: begin 
                        if(inp[0])begin
                            next_out = 4'b0001;
                            next_poll_state = poll_0;end
                         else begin 
                         next_out = 4'b0;
                         next_poll_state = poll_1;
                         end
                         end 
                    poll_1: begin   
                         if(inp[1]) begin
                            next_out = 4'b0010;
                            next_poll_state = poll_1;end
                         else begin 
                         next_out = 4'b0; 
                         next_poll_state = poll_2; end
                         end 
                    poll_2: begin   
                         if(inp[2])begin
                            next_out = 4'b0100;
                            next_poll_state = poll_2;end
                         else begin next_out = 4'b0;
                         next_poll_state = poll_3; end 
                         end                          
                    poll_3: begin   
                         if(inp[3])begin
                            next_out = 4'b1000;
                            next_poll_state = poll_3;end
                         else begin 
                         next_out = 4'b0; 
                         next_poll_state = poll_0; end 
                         end                          
                   default : begin  
                           next_out = 4'b0;
                           next_poll_state =  poll_0; end endcase
end 
end 


endmodule

