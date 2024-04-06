`timescale 1ns / 1ps

module uart_tx
  #(parameter CLKFREQ=27000000, BAUD=115200)
   (
    input wire 	      clk,

    input wire 	      send,
    input wire [7:0]    data,

    output reg 	      tx,
    output wire         busy
    );

   initial tx <= 1'b1;

   reg [24:0] clk_count = 7'b0;

   
   always @(posedge clk)
     clk_count <= (baud_clk)? 0 : clk_count + 1;

   wire baud_clk = ((clk_count +1) == (CLKFREQ/BAUD));

   reg [9:0]   buff = 10'b1111111111;
   reg [3:0]   len = 0;
   assign busy = (len < 10);

   always @(posedge clk)
     begin

	if (!busy && send) 
   begin
	   buff <= { 1'b1, data[7:0], 1'b0 };
	   len = 4'd0;
	   tx <= 1;
	end
	else if (busy && baud_clk) 
   begin
	   tx <= buff[len];
	   len = len + 1;
	end

     end
endmodule


module uart_rx
  #(parameter CLKFREQ=27000000, BAUD=115200)
   (
    input 	         clk,
    input 	         rx,
    output 	         ready,
    output reg [7:0] data
    );

   initial data <= 8'b0;

   reg [6:0] clk_count = 7'b0;
   
   always @(posedge clk)
     if (frame)  clk_count <= (baud_clk0) ? 0 : clk_count + 1;
     else        clk_count <= 0;

   wire      baud_clk0 = ((clk_count +1) == (CLKFREQ/BAUD));
   wire      baud_clk1 = ((clk_count +1) == (CLKFREQ/BAUD)/2);

   reg [3:0] i = 4'hf;
   assign    ready = ((i == 4'd8) && rx);
   wire      frame = (i <= 8 || i == 4'hf);
   wire      reset = (!rx && !frame);

   always @(posedge reset or posedge baud_clk1)
     begin
      if (reset) 
      begin
         i <= 4'hf;
         data <= 8'd0;
      end else 
      begin
         if(frame) 
         begin
            if (i < 8)
               data[i] <= rx;
            i <= i + 1;
         end
      end
     end

endmodule