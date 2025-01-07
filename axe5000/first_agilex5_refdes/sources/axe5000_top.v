// 
// SPDX-FileCopyrightText: Copyright (C) 2025 Arrow Electronics, Inc. 
// SPDX-License-Identifier: MIT-0 
//
// This simple project uses a count running at 2MHz clock to toggle an RGB LED
// USER_BTN is pressed to hold the design in reset.
// DIP_SW[0] position reverses the direction of the count from up to down, thus 
// reversing the sequence of the colors of the RGB LED.


`timescale 1ns/10ps

module axe5000_top (

   output        	RLED, GLED, BLED,

   input [1:0]	   	DIP_SW,			// Labeled S3 on the PCB

   input         	CLK_25M_C,		// 25MHz differential clock input
   input         	USER_BTN		// active-low reset from RST button
   
);


   wire      ninit_done;
   wire      combo_reset;
   
   wire		 clk_2m;



/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

// Instantiate the Agilex Reset Release module
rrip reset_release (
		.ninit_done (ninit_done)  //  output,  width = 1, ninit_done.reset
	);
	
// Combine ninit_done with USER_BTN
assign combo_reset = !USER_BTN | ninit_done;		

// instantiate the PLL	
PLL phase_lock_loop (
		.refclk   (CLK_25M_C),
		.rst      (combo_reset),
		.outclk_0 (clk_2m)
);

	reg [23:0]	count;
	wire		up_down;
	
	assign up_down = DIP_SW[0];

// instantiate the counter
always @ (posedge clk_2m or posedge combo_reset) begin
	if (combo_reset)
		count <= 24'h0;
	else if (up_down)
		count <= count + 24'h1;
	else 
		count <= count - 24'h1;	
end	


// The count counts up or down depending on the position of the DIP_SW[0].
// Every time it reaches the terminal count, it resets itself.
// Red is the slowest changibng color and green is the fastest. The design 
// cycles through 8 different colors, a combination of red, green and blue.

   assign RLED = count[23];
   assign GLED = count[22];
   assign BLED = count[21];

endmodule
