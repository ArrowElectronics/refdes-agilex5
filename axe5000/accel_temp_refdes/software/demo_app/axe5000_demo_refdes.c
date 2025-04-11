/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 * axe5000_box.c is a demo program running on the AXE5000 eval board.
 * It does 2 demos in 1 program.
 * demo #1: Uses the 3-axis accelerometer to PWM the RGB LED based on the tilt
 * demo #2: Reads Agilex-5 temp sensors, and power module Power delivery
 * DIP_SW[1] = 1 (OFF): demo #1.
 * DIP_SW[1] = 0 (ON) : demo #2.
 */

#include "system.h"
#include "stdio.h"
#include "sys/alt_stdio.h"
#include "io.h"
#include "alt_types.h"
#include "sys/alt_irq.h"
#include <sys/alt_sys_init.h>
#include "altera_avalon_i2c.h"
#include "altera_avalon_i2c_regs.h"
#include "altera_avalon_pio_regs.h"
#include "altera_avalon_sysid_qsys_regs.h"
#include <intel_mailbox_client.h>
#include "altera_avalon_timer.h"
#include "altera_avalon_timer_regs.h"
#include <intel_mailbox_client.h>

//I2C parameters
#define U6_addr     0x08	// FS1606 Power Module
#define U8_addr     0x09	// FS1606 Power Module
#define U10_addr    0x0D	// FS1606 Power Module
#define U11_addr    0x0B	// FS1606 Power Module
#define LIS3DH_addr 0x18

// Mailbox Client Registers
#define cmd_get_temp     0x19

#define frac_mul 24414

// Custom PWM parameters
#define PWM_CTRL	(0*4)
#define PWM_STAT	(1*4)
#define PWM_CNTR	(2*4)
#define PWM_PERD	(3*4)
#define PWM_B		(4*4)
#define PWM_G		(5*4)
#define PWM_R		(6*4)

// LIS3DH Registers
#define CTRL_REG0    0x1E
#define CTRL_REG1    0x20
#define CTRL_REG2    0x21
#define CTRL_REG3    0x22
#define CTRL_REG4    0x23
#define CTRL_REG5    0x24
#define CTRL_REG6    0x25
#define INT1_CFG     0x30
#define INT1_THS     0x32
#define INT1_DUR     0x33
#define INT2_CFG     0x34
#define ACT_THS      0x3E
#define ACT_DUR      0x3F
#define OUT_X_L      0x28
#define OUT_Y_L      0x2A
#define OUT_Z_L      0x2C
#define RD_INC       0xC0	// Read and auto increment
#define WR_INC       0x40	// Write and auto increment

//Definition
#define ARG_SIZE 2
#define INPUT_DATA 64
#define RESP_BUF_SIZE 64

// subroutine declarations
//void PB_isr (void* context);
void dispTemp();
void dispFS1606 ();
void FS1606_telemetry(alt_u8 dev_addr);
void readFS1606(alt_u8 dev_addr);
alt_u8  fracT(alt_u32 fraction);
void init_accel ();
void get_accel ();
alt_u32 gammaCorrected8to24(alt_u8 brightness);
void rti_isr (void* context);
void enableRTIinterrupts(void);
void disableRTIinterrupts(void);
void startRTI(void);
void INT2_isr (void* context);
void blink_LED ();


alt_u16 Vout, Vin, nIout;
float Iout;
alt_u8 FS1606_temp;

alt_u8 wData[10];
alt_u8 rData[20];
alt_8 y_value;
alt_8 x_value;
alt_8 z_value;
volatile alt_u8 accel_pio, flash_led;

alt_u8 dip_sw_stat, demo_accel, demo_power;
alt_u32 module_word, chip_id_u, chip_id_l;
alt_u16 cmd_len, response_length;

ALT_AVALON_I2C_DEV_t *i2c_dev;
ALT_AVALON_I2C_STATUS_CODE i2c_status;

//Mailbox Basic Declaration
intel_mailbox_client* fd;
int ret_code;

//Send Command - mailbox_client_send_cmd() Declaration
alt_u8 id;
alt_u32 cmd;
alt_u16 cmd_len;
alt_u32 arg[ARG_SIZE];
int arg_length;
int cmd_length;
alt_u32 input_data[INPUT_DATA];		//Words to write
alt_u32 resp_buf[RESP_BUF_SIZE];	//Words to read
alt_u32 resp_buf_len;


int main()
{

	// Initialize all of the HAL drivers used in this design
	alt_sys_init();

	fd = mailbox_client_open(SDM_MAILBOX_CLIENT_NAME);

	// set up the RTI 2 second interrupt. It is enabled on demand
	alt_ic_isr_register (RTI_2S_IRQ_INTERRUPT_CONTROLLER_ID, RTI_2S_IRQ, rti_isr, NULL, NULL);
	// Enable PB IRQ in the Interrupt Controller
	//alt_ic_irq_enable (PB_IRQ_INTERRUPT_CONTROLLER_ID, PB_IRQ);
    // Register the PB interrupt handler
	//alt_ic_isr_register (PB_IRQ_INTERRUPT_CONTROLLER_ID, PB_IRQ, PB_isr, NULL, NULL);
    // Unmask the PB IRQ
    //IOWR_ALTERA_AVALON_PIO_IRQ_MASK(PB_BASE, 0x01);

	// set up the I2C
	i2c_dev = alt_avalon_i2c_open(ACCEL_I2C_NAME);	// verified as found
    if (NULL==i2c_dev)    {
    	alt_putstr("Error: Cannot find I2C Peripheral\r\n");
    }

	printf("\r\n++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++\r\n");
	// Check DIP switch state
	dip_sw_stat = IORD_ALTERA_AVALON_PIO_DATA(DIP_SW_BASE);
	if (dip_sw_stat == 0x2 || dip_sw_stat == 0x3) {
		demo_accel = 1;
		demo_power = 0;
		printf("Accelerometer demo selected\r\n\n");
	} else if (dip_sw_stat == 0x0 || dip_sw_stat == 0x1) {
		demo_accel = 0;
		demo_power = 1;
		printf("Power/Temp demo selected\r\n\n");
	}else {
		demo_accel = 0;
		demo_power = 0;
	}


	if (demo_accel) {
		// Run Accelerometer RGB LED demo
		init_accel ();


		// Set Up PWM Counter
		IOWR_32DIRECT(PWM24X3_BASE,PWM_PERD,2000000);	// Period = 20ms
		// Enable PWM [8:6]=En[2:0], 95:3]=Clr[2:0], [2:0]=Inv[2:0]
		IOWR_32DIRECT(PWM24X3_BASE,PWM_CTRL,0x0003F);

		// Infinite loop
		while(1) {
			if (flash_led == 1) {
				blink_LED();
			} else {
				get_accel();
				//printf("\r\nX-Axis : %2d\r\n", x_value);
				//printf("Y-Axis : %2d\r\n", y_value);
				//printf("Z-Axis : %2d\r\n", z_value);
				// update corresponding PWM channel with value read * 8192 (8-bit -> 24-bit)
				IOWR_32DIRECT(PWM24X3_BASE,PWM_PERD,2000000);	// Period = 20ms
				IOWR_32DIRECT(PWM24X3_BASE,PWM_CTRL,0x0003F);
				IOWR_32DIRECT(PWM24X3_BASE,PWM_R,(gammaCorrected8to24(x_value)));
				IOWR_32DIRECT(PWM24X3_BASE,PWM_G,(gammaCorrected8to24(y_value)));
				IOWR_32DIRECT(PWM24X3_BASE,PWM_B,(gammaCorrected8to24(z_value)));
				//usleep(200000);

				//dispTemp();
				//printf("\r\n");
				//dispFS1606();
				usleep(600000);
				usleep(600000);
			}
		}
	} else {
		// Keep PWM from driving RGB LED
		IOWR_32DIRECT(PWM24X3_BASE,PWM_PERD,2000000);	// Period = 20ms
		IOWR_32DIRECT(PWM24X3_BASE,PWM_CTRL,0x00038);
		IOWR_32DIRECT(PWM24X3_BASE,PWM_R,0);
		IOWR_32DIRECT(PWM24X3_BASE,PWM_G,0);
		IOWR_32DIRECT(PWM24X3_BASE,PWM_B,0);
		// Run Power and die Temp demo (interrupt-driven)
		// FS1606 Registers:
		//    0x0D = Vout[7:0] = decimal(0x0D[7:0]*0.02+0.6 for Vout>1.8V
		//                     = decimal(0x0D[7:0]*0.01+0.3 for others
		//    0x0E = Vout[7:0] = decimal(0x0E[7:0]/32-(9.05-0.24*decimal0x1A[7:2])) for Vout>1.8V

		dispTemp();
		printf("\r\n");
		dispFS1606();

	}
	return 0;
}

// **********************************************************************
// init_accel - Initialize the 3-axis accelerometer.
//            - Enable all 3 axes
//            - Enable INT2 to sense activity
//            - Enable INT2 to interrupt the NIOS-V
// **********************************************************************

void init_accel ()
{
	// set device register addr
	alt_avalon_i2c_master_target_set(i2c_dev, LIS3DH_addr);

	// Write multiple consecutive registers
	wData[0]= 0x80 | CTRL_REG1;	// Register Address 0x20
	wData[1]= 0x27;				// 10Hz mode, low power off, enable axis Z Y X
	wData[2]= 0x00;				// all filters disabled
	i2c_status = alt_avalon_i2c_master_tx (i2c_dev,wData, 3, ALT_AVALON_I2C_NO_INTERRUPTS);
	if (i2c_status != ALT_AVALON_I2C_SUCCESS) {
	   printf("Error Writing to Accelerometer CTRL_REG1\r\n");
	} else {
		//printf("Successful Write to Accelerometer CTRL_REG1\r\n");
	}

	// Write multiple consecutive registers
	wData[0]= 0x80 | CTRL_REG2; // Register address 0x21
	wData[1]= 0x01;				// Hi Pass
	alt_avalon_i2c_master_tx (i2c_dev,wData, 2, ALT_AVALON_I2C_NO_INTERRUPTS);

	// Write multiple consecutive registers
	wData[0]= 0x80 | CTRL_REG3; // Register address 0x22
	wData[1]= 0x00;				// all interrupts disabled
	wData[2]= 0x00;				// continuous update, little endian, 2g full scale, low resolution, no selftest
	alt_avalon_i2c_master_tx (i2c_dev,wData, 3, ALT_AVALON_I2C_NO_INTERRUPTS);

	// Disconnect SDO/SA Pullup
	wData[0]= 0x80 | CTRL_REG0;
	wData[1]= 0x90;
    alt_avalon_i2c_master_tx(i2c_dev, wData, 2, ALT_AVALON_I2C_NO_INTERRUPTS);

	// Set Activity registers
	wData[0]= 0x80 | CTRL_REG6;
	wData[1]= 0x08;
	alt_avalon_i2c_master_tx(i2c_dev, wData, 2, ALT_AVALON_I2C_NO_INTERRUPTS);

	wData[0]= 0x80 | ACT_THS;
	wData[1]= 0x10;
    alt_avalon_i2c_master_tx(i2c_dev, wData, 2, ALT_AVALON_I2C_NO_INTERRUPTS);

	wData[0]= 0x80 | ACT_DUR;
	wData[1]= 0x05;
    alt_avalon_i2c_master_tx(i2c_dev, wData, 2, ALT_AVALON_I2C_NO_INTERRUPTS);

    // Register the INT2 interrupt handler
    alt_ic_isr_register (ACCEL_IRQ_IRQ_INTERRUPT_CONTROLLER_ID, ACCEL_IRQ_IRQ, INT2_isr, NULL, NULL);
	// Enable INT2 IRQ in the Interrupt Controller
	alt_ic_irq_enable (ACCEL_IRQ_IRQ_INTERRUPT_CONTROLLER_ID, ACCEL_IRQ_IRQ);
    // Unmask the INT2 pin IRQ
    IOWR_ALTERA_AVALON_PIO_IRQ_MASK(ACCEL_IRQ_BASE, 0x02);

}

// **********************************************************************
// get_accel - Read axis signed data from the accelerometer.
//           - convert data to absolute value (all positive).
//           - results returned in x_value, y_value, and z_value.
// **********************************************************************
void get_accel ()
{
	// set device register addr
	alt_avalon_i2c_master_target_set(i2c_dev, LIS3DH_addr);
	// read y-axis data from accelerometer
	wData[0]= 0x80 | OUT_Y_L;       // read y-register and increment
	i2c_status = alt_avalon_i2c_master_tx_rx(i2c_dev, wData, 1, rData, 2, ALT_AVALON_I2C_NO_INTERRUPTS);
	y_value = rData[1];
    if (y_value < 0)  	y_value = ~y_value + 1;

	// read x-axis data from accelerometer
	wData[0]= 0x80 | OUT_X_L;       // read x-register and increment
    alt_avalon_i2c_master_tx_rx(i2c_dev, wData, 1, rData, 2, ALT_AVALON_I2C_NO_INTERRUPTS);
	x_value = rData[1];
    if (x_value < 0)  	x_value = ~x_value + 1;

	// read z-axis data from accelerometer
	wData[0]= 0x80 | OUT_Z_L;       // read z-register and increment
    alt_avalon_i2c_master_tx_rx(i2c_dev, wData, 1, rData, 2, ALT_AVALON_I2C_NO_INTERRUPTS);
	z_value = rData[1];
    if (z_value < 0)  	z_value = ~z_value + 1;

    //printf ("X-axis = %d, Y-axis = %d, Z-axis = %d\r\n", x_value, y_value, z_value);
}

// **********************************************************************
// gammaCorrected8to24 - Calculate 24-bit PWM output from 7-bit
//                       absolute value brightness (Accelerometer reading)
// **********************************************************************
alt_u32 gammaCorrected8to24(alt_u8 brightness)
{
	return (alt_u32)(brightness * brightness * 1038);
}


// **********************************************************************
// blink_LED - Start Blink Patter on RGB LED
//           - PWM pulse at 99.99%
//           - QUick White -> Off -> White -> Off
//           - Slow Red -> Off -> Green -> Off -> Blue -> Off
// **********************************************************************
void blink_LED () {

	//alt_putstr("In blink_LED\r\n");
	// Set Up PWM Counter
	IOWR_32DIRECT(PWM24X3_BASE,PWM_PERD,2000000);	// Period = 20ms
	// Enable PWM [8:6]=En[2:0], 95:3]=Clr[2:0], [2:0]=Inv[2:0]
	IOWR_32DIRECT(PWM24X3_BASE,PWM_CTRL,0x0003F);
	// White twice
	IOWR_32DIRECT(PWM24X3_BASE,PWM_R,0x00FFFFF0);
	IOWR_32DIRECT(PWM24X3_BASE,PWM_G,0x00FFFFF0);
	IOWR_32DIRECT(PWM24X3_BASE,PWM_B,0x00FFFFF0);
	usleep(200000);
	IOWR_32DIRECT(PWM24X3_BASE,PWM_CTRL,0x00000);
	usleep(150000);
	IOWR_32DIRECT(PWM24X3_BASE,PWM_CTRL,0x0003F);
	usleep(200000);
	IOWR_32DIRECT(PWM24X3_BASE,PWM_CTRL,0x00000);
	usleep(150000);
	IOWR_32DIRECT(PWM24X3_BASE,PWM_CTRL,0x0003F);
	usleep(200000);
	IOWR_32DIRECT(PWM24X3_BASE,PWM_CTRL,0x00000);
	usleep(300000);

	// Red
	IOWR_32DIRECT(PWM24X3_BASE,PWM_CTRL,0x00020);
	usleep(600000);
	IOWR_32DIRECT(PWM24X3_BASE,PWM_CTRL,0x00000);
	usleep(300000);
	// Green
	IOWR_32DIRECT(PWM24X3_BASE,PWM_CTRL,0x00010);
	usleep(600000);
	IOWR_32DIRECT(PWM24X3_BASE,PWM_CTRL,0x00000);
	usleep(300000);
	// Blue
	IOWR_32DIRECT(PWM24X3_BASE,PWM_CTRL,0x00008);
	usleep(600000);
	IOWR_32DIRECT(PWM24X3_BASE,PWM_CTRL,0x00000);
	usleep(300000);

}



// *******************************************************************
// dispTemp - Read Agilex-5 die temperature via the MailBox Client
//          - Display highest reading of each sensor location
//********************************************************************

void dispTemp()
{

	printf("\r\n");

	id = 0x5;					//<any 4-bit number>
	cmd = cmd_get_temp;
	arg[0] = 0<<16 | 0x01;		//TSD location 0
	arg_length = 1;
	cmd_length = 1;
	resp_buf_len = 1;
	ret_code = mailbox_client_send_cmd(fd, id, cmd, arg, arg_length, cmd_length, input_data, resp_buf, resp_buf_len);
	if(ret_code == 0)
	{
		printf("Agilex-5E Location 0 Sensor 1 Temp. = %ld.%02dC\r\n",(resp_buf[0]>>8) & 0x0FF, fracT(resp_buf[0]&0x0FF));
	}

   	// Sensor Location 1 has 1 sensors + highest ([0])
   	resp_buf_len = 5;
   	arg[0] = 1<<16 | 0x01;		//TSD location 1
   	ret_code = mailbox_client_send_cmd(fd, id, cmd, arg, arg_length, cmd_length, input_data, resp_buf, resp_buf_len);
   	if(ret_code == 0)
   	{
   		printf("Agilex-5E Location 1 Highest  Temp. = %ld.%02dC\r\n",(resp_buf[0]>>8) & 0x0FF, fracT(resp_buf[0]&0x0FF));
   	}

   	// Sensor Location 3 has 1 sensors + highest ([0])
   	resp_buf_len = 4;
   	arg[0] = 3<<16 | 0x01;		//TSD location 3
   	ret_code = mailbox_client_send_cmd(fd, id, cmd, arg, arg_length, cmd_length, input_data, resp_buf, resp_buf_len);
   	if(ret_code == 0)
   	{
   		printf("Agilex-5E Location 3 Highest  Temp. = %ld.%02dC\r\n",(resp_buf[0]>>8) & 0x0FF, fracT(resp_buf[0]&0x0FF));
   	}

   	// Sensor Location 4 has 1 sensors + highest ([0]) - Sensor 2 N/A
   	resp_buf_len = 6;
   	arg[0] = 4<<16 | 0x01;		//TSD location 4
   	ret_code = mailbox_client_send_cmd(fd, id, cmd, arg, arg_length, cmd_length, input_data, resp_buf, resp_buf_len);
   	if(ret_code == 0)
   	{
   		printf("Agilex-5E Location 4 Highest  Temp. = %ld.%02dC\r\n",(resp_buf[0]>>8) & 0x0FF, fracT(resp_buf[0]&0x0FF));
   	}

}


//********************************************************************
// FS1606 uPOL functions

//********************************************************************
// dispFS1606 - Display FS1606 voltage/current telemetry
//********************************************************************
void dispFS1606 ()
{
	printf ("FS1606 U6 (0.75V FPGA Core Voltage) Telemetry Data:\r\n");
	FS1606_telemetry(U6_addr);

}

//********************************************************************
// FS1606_telemetry - Reads the Vin Vout, and Iout of a FS16106-0600
//                  - Display the numbers in V.vvv and A.aaa format
//********************************************************************
void FS1606_telemetry(alt_u8 dev_addr)
{
	// set device register addr
	alt_avalon_i2c_master_target_set(i2c_dev, dev_addr);

	// Read Vin/Vout/Iout
	readFS1606(dev_addr);
	printf ("Vin   : %02d.%02d V\n\r", Vin/1000, Vin%1000);
	printf ("Vout  : %02d.%03d V\n\r", Vout/1000, Vout%1000);
	printf ("Iout  : %0d mA\n\r", nIout);

	printf("\n");
}

//*********************************************************************
// readFS1606 - Reads the Vin Vout, and Iout registers of a FS16106-0600
//            - perform calculations
//            - Results:
//            - Vin  = Input Voltage (V)
//            - Vout = Output Voltage (mV)
//            - Iout = Output Current (mA)
//*********************************************************************
void readFS1606(alt_u8 dev_addr)
{
	alt_u16 G_dec;
	
	// Read Vin Reg 0x0C
    wData[0] = 0x0C;
    i2c_status = alt_avalon_i2c_master_tx_rx(i2c_dev, wData, 1, rData, 1, ALT_AVALON_I2C_NO_INTERRUPTS);
	if (i2c_status != ALT_AVALON_I2C_SUCCESS) {
	   printf("Error Reading from U6 Vin Reg\r\n");
	} else {
		//printf("Successful Reading from U6 Vin Reg\r\n");
	    // Calculate Vin.
	    Vin = (alt_u16)((float)(rData[0] / 16.0f) * 1000);
	    //printf ("Reg 0x0C Vin value = %d\r\n", rData[0]);
	}

 
	// Read Vout Reg 0x0D
    wData[0] = 0x0D;
    alt_avalon_i2c_master_tx_rx(i2c_dev, wData, 1, rData, 1, ALT_AVALON_I2C_NO_INTERRUPTS);
    //printf ("Reg 0x0D Vout value = %d\r\n", rData[0]);
    	Vout = (alt_u16)(rData[0] * 10) + 300;
    
    // Read Reg 0x1A to be used in Iout calculation
    wData[0] = 0x1A;
    alt_avalon_i2c_master_tx_rx(i2c_dev, wData, 1, rData, 1, ALT_AVALON_I2C_NO_INTERRUPTS);
    G_dec = (alt_u16)(rData[0] >> 2);
    //printf ("G_dec value = %d\r\n", G_dec);
	// Read Iout Reg 0x0E
    wData[0] = 0x0E;
    alt_avalon_i2c_master_tx_rx(i2c_dev, wData, 1, rData, 1, ALT_AVALON_I2C_NO_INTERRUPTS);
    //printf ("Reg 0x0E Iout value = %d\r\n", rData[0]);
	Iout = ((float)rData[0] / 32.0f) - ((9.05-(0.24*(float)G_dec))*((float)Vout / 1000.0f)) - (0.356*(float)G_dec) + 13.1;
	nIout = (alt_u16)(Iout * 1000.0f);

	//// Read FS1606 Temp Reg 0x0F
    //wData[0] = 0x0F;
    //alt_avalon_i2c_master_tx_rx(i2c_dev, wData, 1, rData, 1, ALT_AVALON_I2C_NO_INTERRUPTS);
    //// Calculate FS1606 Temperature.
    //FS1606_temp = (rData[0]);
    //printf ("FS1606 Temperature = %d C\r\n", rData[0]);
}


/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

//********************************************************************
//  fracT - Fraction for Temperature reading.
//        - Looks at 2 bits of 8-bit LSB to calculate a 2-digit fraction
//        - bit7=.50, bit6=0.25
//        - Return - 8-bit 2-digit fraction without (75, 50, 25, 00)
// *******************************************************************
alt_u8 fracT(alt_u32 fraction)
{
	alt_u8 fval;

	fval = (alt_u8) fraction;
	fval = fval >> 6;	// keep only 2 bits
	//printf(" fval= 0x%1X ",fval);
    switch (fval) {
    case 0 :
    	fval = 0;
    	break;
    case 1 :
    	fval = 25;
    	break;
    case 2 :
    	fval = 50;
    	break;
    case 3 :
    	fval = 75;
    	break;
    }
    return fval;
}


//********************************************************************
// Enable Interval Timer Interrupts
//********************************************************************
void enableRTIinterrupts(void)
{
	// Clear pending RTI irq before exiting
	IOWR_ALTERA_AVALON_TIMER_STATUS(RTI_2S_BASE, ALTERA_AVALON_TIMER_STATUS_TO_MSK);
	alt_ic_irq_enable (RTI_2S_IRQ_INTERRUPT_CONTROLLER_ID, RTI_2S_IRQ);

}


//********************************************************************
// Disable Interval Timer Interrupts
//********************************************************************
void disableRTIinterrupts(void)
{
	alt_ic_irq_disable (RTI_2S_IRQ_INTERRUPT_CONTROLLER_ID, RTI_2S_IRQ);

}

//********************************************************************
// Start Interval Timer for 2 second timeout and enable its interrupt
//********************************************************************
void startRTI(void)
{
	IOWR_ALTERA_AVALON_TIMER_STATUS(RTI_2S_BASE, ALTERA_AVALON_TIMER_STATUS_TO_MSK);
	IOWR_ALTERA_AVALON_TIMER_CONTROL (RTI_2S_BASE, ALTERA_AVALON_TIMER_CONTROL_START_MSK | ALTERA_AVALON_TIMER_CONTROL_ITO_MSK);
	alt_ic_irq_enable (RTI_2S_IRQ_INTERRUPT_CONTROLLER_ID, RTI_2S_IRQ);

}


//********************************************************************
// rti_isr - RTI_2s interrupt service routine (2 second timeout).
//********************************************************************
void rti_isr (void* context)
{
	// disable 2s RTI
	IOWR_ALTERA_AVALON_TIMER_CONTROL(RTI_2S_BASE, 0);

	// Clear pending RTI irq before exiting
	IOWR_ALTERA_AVALON_TIMER_STATUS(RTI_2S_BASE, ALTERA_AVALON_TIMER_STATUS_TO_MSK);

	// Place holder for ISR actions



}

//********************************************************************
// INT2_isr - LIS3DH accelerometr INT2 interrupt.
//          - Activity / no Activity sensing
//          - INT2 goes High when there is activity
//          - INT2 goes Low when there is no activity
 //********************************************************************
void INT2_isr (void* context)
{

	//alt_putstr("In INT2 ISR\r\n");

	accel_pio = IORD_ALTERA_AVALON_PIO_DATA(ACCEL_IRQ_BASE);
	if (accel_pio && 0x02) {
		//alt_putstr("INT2 went High\r\n");
		// No accelerometer activity - Start LED Flashing routine
		flash_led = 1;
	} else {
		//alt_putstr("INT2 went Low\r\n");
		// Accelerometer activity detected - user tilt sensing to PWM RGB LED
		flash_led = 0;
	}
   // Clear interrupt bit
   IOWR_ALTERA_AVALON_PIO_EDGE_CAP(ACCEL_IRQ_BASE, 0x02);
}
