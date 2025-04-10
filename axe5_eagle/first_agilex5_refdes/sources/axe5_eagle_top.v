// 
// SPDX-FileCopyrightText: Copyright (C) 2024 Arrow Electronics, Inc. 
// SPDX-License-Identifier: MIT-0 
//
// This simple project uses a counter running at 25MHz clock to toggle and LED
// FPGA_PB2 and FPGA_PB3 are used to drive 2 other LEDs.
// FPGA_PB2 pressed -> RGB_LED1.Green is on
// FPGA_PB3 pressed -> RGB_LED1.Blue is on
// The counter timeout marched the colors of RGB_LED0 R -> G -> B -> R ...

`timescale 1ns/10ps

module axe5_eagle_top (

   output        	LED0R, LED0G, LED0B,

   output        	LED1R, LED1G, LED1B,

   input [1:0]   	FPGA_PB,		// Labeled FPGA_PB3:FPGA_PB2 on the PCB

   input         	REFCLK_3B0,		// 25MHz differential clock input
   input         	FPGA_RST_n		// active-low reset from RST button
   
);


   wire      ninit_done;
	wire      combo_reset;
	reg       rs1, reset_synched;
	
   reg [2:0] rgb_led0;          // 3-bit shift register for driving RGB_LED0

   assign LED0R = rgb_led0[2];
   assign LED0G = rgb_led0[1];
   assign LED0B = rgb_led0[0];

   wire [2:0] rgb_led1;

   assign LED1R = rgb_led1[2];
   assign LED1G = rgb_led1[1];
   assign LED1B = rgb_led1[0];

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

// Instantiate the Agilex Reset Release module
rrip reset_release (
		.ninit_done (ninit_done)  //  output,  width = 1, ninit_done.reset
	);


// Combine ninit_done with FPGA_RST_n
assign combo_reset = !FPGA_RST_n | ninit_done;

// Synchronize the Reset action to the clock.
always @ (posedge REFCLK_3B0) begin
	rs1           <= combo_reset;
	reset_synched <= rs1;
end



// Add counter, push-button, and LED logic

	reg [24:0] counter;
	
// The Counter counts up from 0x0000000 to 0x1000000.
// Every time it reaches the terminal count, it resets itself to 0x0000000, and
// selects the next LED0 color to be illuminated
always @ (posedge REFCLK_3B0 or posedge reset_synched) begin
	if (reset_synched)
		counter <= 25'h0;
	else if (counter[24])
		counter <= 25'h0;
	else
		counter <= counter + 25'h1;
end

// march the colors in rgb_led0 every time the counter times out
always @ (posedge REFCLK_3B0 or posedge reset_synched) 
begin
	if (reset_synched)
		rgb_led0 <= 3'h7;		// all LEDs off
	else if (counter[24]) begin
		if ((rgb_led0 == 3'h7) || (rgb_led0 == 3'b110))
			rgb_led0 <= 3'b011;		// drive R color
		else if (rgb_led0 == 3'b011)
			rgb_led0 <= 3'b101;		// drive G color
		else if (rgb_led0 == 3'b101)
			rgb_led0 <= 3'b110;		// drive B color
	end
end

// push-buttons (no debouncing)
assign rgb_led1[2] = 1'b1;			// RGB_LED1.Red not used
assign rgb_led1[1] = FPGA_PB[0];	// RGB_LED1.Green
assign rgb_led1[0] = FPGA_PB[1];	// RGB_LED1.Blue

endmodule
