#
# SPDX-FileCopyrightText: Copyright (C) 2026 Synaptic Labs Ltd. 
# SPDX-License-Identifier: MIT-0 
#

`define INCLUDE_PSRAM

module axe5000_top (

// Global Signals
output        VSEL_1V3,		// VADJ selector between 1.2V and 1.3V
input         CLK_25M_C,

// Push Button
input         USER_BTN,

// UART pin
input         DBG_RX,
output        DBG_TX,


//PSRAM signals
output         HR_HRESETn ,// reset
output         HR_CLK,     // CLKp
output         HR_CSn ,    // CS2 n
inout [7:0]    HR_DQ  ,    // DQ
inout          HR_RWDS ,   // RWDS


// LED
output        RLED, GLED, BLED

);


// Select 1.3V for HSIO
assign VSEL_1V3 = 1'b1;



/******************************************************************************/

    top_system mipi_top (
        .clk25mhz_clk              (CLK_25M_C), 
        .sll_hyperram_MB0_CLK0     (HR_CLK),
        .sll_hyperram_MB0_CLK0n    (),
        .sll_hyperram_MB0_CS1n     (HR_CSn),
        .sll_hyperram_MB0_RWDS     (HR_RWDS),
        .sll_hyperram_MB0_DQ       (HR_DQ),
        .sll_hyperram_MB0_RSTn     (HR_HRESETn),
        .dbg_uart_rxd              (DBG_RX),
        .dbg_uart_txd              (DBG_TX),
        .led_export                ({RLED,GLED,BLED}),
        .pb_export                 (USER_BTN)
	);

/******************************************************************************/




endmodule
