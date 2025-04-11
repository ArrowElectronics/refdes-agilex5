/***********************************************************************
* 
* SPDX-FileCopyrightText: Copyright (C) 2025 Arrow Electronics, Inc. 
* SPDX-License-Identifier: MIT-0 
*
* This design uses the NIOS-V /m CPU core with additional peripherals:
*   - 256KB SRAM
*   - PLL (100MHz output)
*   - I2C
*   - Custom PWM
*   - PIO for 2xDIP switches
*   - PIO for 1 Push-Button
*   - PIO for Accelerometer Interrupt pins
*   - Mailbox Client for reading FPGA temperature
*   - Interval Timer
*   - UART
*
* The program running on the NIOS-V is documented separately.
*
************************************************************************/

module axe5000_top (

// Push Button
input         USER_BTN,

// DIP switches
input [1:0]   DIP_SW,

// LEDs
output reg    LED1,
output        RLED, GLED, BLED,

// UART pin
input         UART_RXD,
output        UART_TXD,

// Accelerometer
input         INT1, INT2,			// Interrupt pins from Accelerometer
inout         I2C_SCL, I2C_SDA,	// I2C pins

// Global Signals
output        VSEL_1V3,		// VADJ selector between 1.2V and 1.3V
input         CLK_25M_C		// 25.0MHz Oscillator clock input

);


// Global signals
wire clk_100MHz;

// Sign of Life Counter 
reg [23:0] counter4led;
wire       counter_expired;
assign counter_expired = (counter4led[23:22] == 2'b11);


// I2C bidi buffers
wire     niosv_i2c_sda_in, niosv_i2c_sda_oe , niosv_i2c_scl_in, niosv_i2c_scl_oe;
assign   I2C_SCL    = niosv_i2c_scl_oe ? 1'b0 : 1'bz;
assign   niosv_i2c_scl_in = I2C_SCL;
assign   I2C_SDA    = niosv_i2c_sda_oe ? 1'b0 : 1'bz;
assign   niosv_i2c_sda_in     = I2C_SDA;

// Select 1.3V for HSIO on CRUCI-HS
assign VSEL_1V3 = 1'b1;


/******************************************************************************/

   niosv_system niosv_sys (
      .clk_25m_clk      (CLK_25M_C),       
      .accel_i2c_sda_in (niosv_i2c_sda_in),
      .accel_i2c_scl_in (niosv_i2c_scl_in),
      .accel_i2c_sda_oe (niosv_i2c_sda_oe),
      .accel_i2c_scl_oe (niosv_i2c_scl_oe),
      .pwm_out_conduit  ({RLED,GLED,BLED}), 
      .dip_sw_export    (DIP_SW),  
      .sysclk_clk       (clk_100MHz), 
      .reset_n_reset_n  (USER_BTN),
      .accel_irq_export ({INT2, INT1}), 
      .uart_rxd         (UART_RXD), 
      .uart_txd         (UART_TXD)
	);


/******************************************************************************/

// Counter blinking Red LED
always @ (posedge clk_100MHz) begin
	 if (counter_expired) begin
	   counter4led <= 24'h0;
		LED1 <= !LED1;
	 end
	 else begin
	   counter4led <= counter4led + 24'h01;
		LED1 <= LED1;
	 end
end


endmodule
