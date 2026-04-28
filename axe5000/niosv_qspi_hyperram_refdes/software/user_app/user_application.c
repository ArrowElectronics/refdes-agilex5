/*
  SPDX-FileCopyrightText: Copyright (C) 2026 Synaptic Labs Ltd. 
  SPDX-License-Identifier: MIT-0 
*/

#include <stdio.h>
#include <unistd.h>
#include "altera_avalon_pio_regs.h"
#include "altera_avalon_sysid_qsys.h"
#include "altera_avalon_sysid_qsys_regs.h"
#include "system.h"
#include "sys/alt_irq.h"

void PB_isr (void* context);

int main() {

   int i;
    alt_u32 hardware_id;
    
    printf("\r\n\r\n\+++++++++++++++++++++++++++++ User Application ++++++++++++++++++++++++++++\r\n\r\n");
    printf("Displaying 16 LED colors \r\n\n");

  //Go over all the colors
   for (i =0; i< 16; i++) {
     IOWR_ALTERA_AVALON_PIO_DATA(NIOSV_SYSTEM_0_PIO_LED_BASE, i);  
     usleep(200000);
    } 

	// Print the System ID selected in hardware
    hardware_id = IORD_ALTERA_AVALON_SYSID_QSYS_ID(NIOSV_SYSTEM_0_SYSID_BASE);
    printf("System ID: 0x%x \r\n\n", hardware_id);

	 // Enable PB IRQ in the Interrupt Controller
	 alt_ic_irq_enable (NIOSV_SYSTEM_0_PIO_PB_IRQ_INTERRUPT_CONTROLLER_ID, NIOSV_SYSTEM_0_PIO_PB_IRQ);
  
   // Register the PB interrupt handler
	 alt_ic_isr_register (NIOSV_SYSTEM_0_PIO_PB_IRQ_INTERRUPT_CONTROLLER_ID, NIOSV_SYSTEM_0_PIO_PB_IRQ, PB_isr, NULL, NULL);

   // Unmask the PB IRQ for USER_PB pin
	 IOWR_ALTERA_AVALON_PIO_IRQ_MASK(NIOSV_SYSTEM_0_PIO_PB_BASE, 0x01);


    printf("Press the push Button (PB) to change the color \r\n\r\n");

   
    fflush(stdout);
    while (1) {
    	//do Nothing
    }

    return 0;
}


/******************************************************************/


/* =============================================================
 * PB_isr - Push-Button interrupt service routine.
 *          Happens every time the buttons is pressed
 *          USER_PB (S2)
 *          Change the color
 */
void PB_isr (void* context)
{
   alt_u8  new_pb;
   alt_u32 current_led_val;

   // wait ~20msec debounce time
   usleep(20*1000);
   new_pb = (IORD_ALTERA_AVALON_PIO_DATA(NIOSV_SYSTEM_0_PIO_PB_BASE) & 0x01);

   // If PB
   if (new_pb != 0x01) {  // enter only if a button is still pressed

     current_led_val = IORD_ALTERA_AVALON_PIO_DATA(NIOSV_SYSTEM_0_PIO_LED_BASE);
     IOWR_ALTERA_AVALON_PIO_DATA(NIOSV_SYSTEM_0_PIO_LED_BASE, current_led_val + 1);  

#ifdef debug
    	  printf("USER_PB pressed\r\n");
#endif
   }
   // Clear both interrupt bits
   IOWR_ALTERA_AVALON_PIO_EDGE_CAP(NIOSV_SYSTEM_0_PIO_PB_BASE, 0x01);
}




