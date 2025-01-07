// 
// SPDX-FileCopyrightText: Copyright (C) 2025 Arrow Electronics, Inc. 
// SPDX-License-Identifier: MIT-0 
//
// This simple project implements a Nios V/m soft microcontroller in an Agilex 5 FPGA
// USER_BTN is pressed to hold the design in reset.


`timescale 1ns/10ps

module axe5000_top (

   input         	CLK_25M_C,		// 25MHz differential clock input
   input         	USER_BTN		// active-low reset from RST button
   
);


/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

// Instantiate the Nios V Platform Designer system
	NIOSV_lab u0 (
		.clk_clk       (CLK_25M_C),
		.reset_reset_n (USER_BTN)
	);
	
endmodule
