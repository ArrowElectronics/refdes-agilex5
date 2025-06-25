/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * 
 * This code is used for evaluation purposes only.
 *
 * This program runs on a NIOS-V. It interfaces with the user via UART
 * connected to a terminal or terminal emulator such as TeraTerm at 19200 baud.
 * It does the following:
 * - Prints out available commands the user can perform
 * - Initializes the MIRA220 Camera registers
 * - Initializes the MIPI D-PHY, CSI2, and VVP IP blocks to pass 1600x900
 *   images, scale them to 1920x1080 and store them in 3 frame buffers located
 *   in LPDDR4.
 * - Initializes the ADV7511 HDMI driver to accept 24-bit RGB data from the
 *   egress VVP IP blocks which read video data from the frame buffers.
 * - Output video is only driven once the frame buffers have content.
 * - Camera exposure can be manually changed to adjust for lighting condition:
 *   - 12 steps ranging from 5ms to 60ms (max) in increments of 5ms
 *   - FPGA_PB2 : Increase Exposure
 *   _ FPGA_PB3 : Decrease Exposure
*/

//#define debug

#include "stdio.h"
#include "system.h"
#include "alt_types.h"
#include "io.h"
#include <sys/alt_sys_init.h>
#include "sys/alt_stdio.h"
#include "sys/alt_irq.h"
#include "altera_avalon_pio_regs.h"
#include "altera_avalon_i2c.h"
#include "altera_avalon_i2c_regs.h"
#include "altera_avalon_sysid_qsys.h"
#include "altera_avalon_sysid_qsys_regs.h"


//I2C parameters
#define MIRA220_i2c_addr   0x54
#define mux_i2c_addr       0x70
#define hdmi_i2c_addr      0x39
#define cr00300_i2c_addr   0x52

#define MIRA220_REG_CHIP_VER            0x001D	// 0x01D:[31:0], 0x01E[23:0], 0x025:[7:0]
#define MIRA220_REG_CHIP_REV            0x003A	// 0x03A[7:0]
#define MIRA220_REG_SW_RESET            0x0040
#define MIRA220_REG_EXPOSURE	        0x100C
#define MIRA220_REG_VBLANK              0x1012

#define MIRA220_TEST_PATTERN_CFG_REG	0x2091
#define MIRA220_TEST_PATTERN_ENABLE     1     // [0] = 1
#define MIRA220_TEST_PATTERN_VERT_GRAD  0x00  //[6:4] = 0x0
#define MIRA220_TEST_PATTERN_DIAG_GRAD  0x10  //[6:4] = 0x1
#define MIRA220_TEST_PATTERN_Walking_1  0x40  //[6:4] = 0x1
#define MIRA220_TEST_PATTERN_Walking_0  0x50  //[6:4] = 0x1

#define MIRA220_IMAGER_STATE_REG        0x1003
#define MIRA220_IMAGER_MASTER_EXPOSURE  0x10

#define MIRA220_IMAGER_RUN_REG			0x10F0
#define MIRA220_IMAGER_RUN_START		0x01
#define MIRA220_IMAGER_RUN_STOP			0x00

#define MIRA220_MIPI_SOFT_RESET_REG 	0x5004
#define MIRA220_MIPI_SOFT_RESET_DPHY	0x01
#define MIRA220_MIPI_SOFT_RESET_NONE	0x00

#define MIRA220_MIPI_RST_CFG_REG		0x5011
#define MIRA220_MIPI_RST_CFG_ACTIVE 	0x00
#define MIRA220_MIPI_RST_CFG_SUSPEND 	0x01
#define MIRA220_MIPI_RST_CFG_STANDBY 	0x02


// DPHY
#define IP_ID                   (0x00 * 1)
#define RX_CAP                  (0x08 * 1)
#define DPHY_CSR                (0x10 * 1)
#define CLK_CSR                 (0x1C * 1)
#define CLK_STATUS              (0x1D * 4)
#define DLANE_CSR_0             (0x20 * 4)
#define DLANE_STATUS_0          (0x21 * 4)
#define RX_DLANE0_DESKEW_DELAY  (0x22 * 4)
#define RX_DLANE0_ERR           (0x23 * 4)
#define RX_CAL_REG_CTRL         (0x60 * 4)
#define RX_CAL_STATUS           (0x61 * 4)
#define MIRA220_RESETn          0x00
#define MIRA220_ENABLE          0x01

#define LPDDR4_BUFFER_0         0x80000000
#define LPDDR4_BUFFER_1         0x81000000
#define LPDDR4_BUFFER_2         0x82000000
#define lpddr4_status           0x05000400

#define HIST_CONTROL            0x014C
#define HIST_STATUS             0x0140
#define HIST_H_START            0x0150
#define HIST_V_START            0x0154
#define HIST_H_END              0x0158
#define HIST_V_END              0x015C
#define NUM_HIST_BINS           256
#define ROI_STATISTICS_START    0x200 + (4 * NUM_HIST_BINS)

#define WBC_IMG_WIDTH           0x0120
#define WBC_IMG_HEIGHT          0x0124
#define WBC_CFA_00_COLOR_SCALER 0x0150
#define WBC_CFA_01_COLOR_SCALER 0x0154
#define WBC_CFA_10_COLOR_SCALER 0x0158
#define WBC_CFA_11_COLOR_SCALER 0x015C
#define WBC_COMMIT              0x0148
#define WBC_CONTROL             0x014C

#define BLC_IMG_WIDTH             0x0120
#define BLC_IMG_HEIGHT            0x0124
#define BLC_CFA_00_BLACK_PEDASTAL 0x0150
#define BLC_CFA_00_COLOR_SCALER   0x0154
#define BLC_CFA_01_BLACK_PEDASTAL 0x0158
#define BLC_CFA_01_COLOR_SCALER   0x015C
#define BLC_CFA_10_BLACK_PEDASTAL 0x0160
#define BLC_CFA_10_COLOR_SCALER   0x0164
#define BLC_CFA_11_BLACK_PEDASTAL 0x0168
#define BLC_CFA_11_COLOR_SCALER   0x016C
#define BLC_COMMIT                0x0148
#define BLC_CONTROL               0x014C

#define DEMOSAIC_IMG_WIDTH      0x0120
#define DEMOSAIC_IMG_HEIGHT     0x0124
#define DEMOSAIC_CONTROL        0x014C

#define VFW_IRQ_CONTROL         0x0100
#define VFW_IRQ_STATUS          0x0104
#define VFW_IMG_INFO_WIDTH      0x0120
#define VFW_IMG_INFO_HEIGHT     0x0124
#define VFW_STATUS              0x0140
#define VFW_BUFFER_AVAILABLE    0x0144
#define VFW_BUFFER_WRITE_COUNT  0x0148
#define VFW_BUFFER_START_ADDR   0x014C
#define VFW_COMMIT              0x0164
#define VFW_BUFFER_ACKNOWLEDGE  0x0168
#define VFW_RUN                 0x016C
#define VFW_NUM_BUFFERS         0x0170
#define VFW_BUFFER_BASE         0x0174
#define VFW_INTER_BUFFER_OFFSET 0x0178
#define VFW_INTER_LINE_OFFSET   0x017C

#define VFR_COMMIT                      0x0190
#define VFR_NUM_BEFFER_SETS             0x0194
#define VFR_BUFFER_MODE                 0x0198
#define VFR_STARTING_BUFFER_SET         0x019C
#define VFR_RUN                         0x01A0
#define VFR_BUFFER_0_BASE               0x01B0
#define VFR_BUFFER_0_NUM_BUFFERS        0x01B4
#define VFR_BUFFER_0_INTER_LINE_OFFSET  0x01BC
#define VFR_BUFFER_0_WIDTH              0x01C0
#define VFR_BUFFER_0_HEIGHT             0x01C4
#define VFR_BUFFER_1_BASE               0x01F0
#define VFR_BUFFER_1_NUM_BUFFERS        0x01F4
#define VFR_BUFFER_1_INTER_LINE_OFFSET  0x01FC
#define VFR_BUFFER_1_WIDTH              0x0200
#define VFR_BUFFER_1_HEIGHT             0x0204
#define VFR_BUFFER_2_BASE               0x0230
#define VFR_BUFFER_2_NUM_BUFFERS        0x0234
#define VFR_BUFFER_2_INTER_LINE_OFFSET  0x023C
#define VFR_BUFFER_2_WIDTH              0x0240
#define VFR_BUFFER_2_HEIGHT             0x0244

#define file1  "C:/Naji/vb1_content.txt"

void signOn ();
void lpddr4_cal_test();
void hdmi_i2c_test();
void init_TPG ();
alt_8 poke(alt_u16 addr, alt_u8 val, alt_u8 len);
alt_8 peek(alt_u16 addr, alt_u8 len);
alt_u8 init_MIRA220 ();
void init_adv7511 ();
void VFW_isr (void* context);
void MIRA220_OTP_read(alt_u16 reg_addr);
void PB_isr (void* context);

volatile char uart_rd;
alt_u8 wData[20];
alt_u8 rData[256];

unsigned char  uart_rx_char;

alt_u32 lpddr4_cal_status;
alt_u32 buffer_start_addr;
alt_u8  dphy_reg8;
alt_u8  DPHY_RX_DESKEW;
alt_u32 global_var;

FILE *fptr;

struct mira220_reg {
	alt_u16 address;
	alt_u8 val;
};

alt_u8 exp_time_index;

// Camera exposure time setting for adjusting exposure due to exterior lighting
alt_u16 exp_time[] = {
		0x016C,	// 5ms
		0x02D8,	// 10ms
		0x0445,	// 15ms
		0x05B1,	// 20ms
		0x071D,	// 25ms
		0x0889,	// 30ms
		0x09F5,	// 35ms
		0x0B61,	// 40ms
		0x0CCE,	// 45ms
		0x0E3A,	// 50ms
		0x0FA6,	// 55ms
		0x10C9	// 59ms
};
// 1600_1400_30fps_12b_2lanes
static const struct mira220_reg full_1600_900_60fps_12b_2lanes_reg[] = {
		// 60fps
		{0x1003,0x2},  //nitial Upload
		{0x6006,0x0},  //nitial Upload
		{0x6012,0x1},  //nitial Upload
		{0x6013,0x0},  //nitial Upload
		{0x6006,0x1},  //nitial Upload
		{0x205D,0x0},  //nitial Upload
		{0x2063,0x0},  //nitial Upload
		{0x24DC,0x13},  //nitial Upload
		{0x24DD,0x3},  //nitial Upload
		{0x24DE,0x3},  //nitial Upload
		{0x24DF,0x0},  //nitial Upload
		{0x400A,0x8},  //nitial Upload
		{0x400B,0x0},  //nitial Upload
		{0x401A,0x8},  //nitial Upload
		{0x401B,0x0},  //nitial Upload
		{0x4006,0x8},  //nitial Upload
		{0x401C,0x6F},  //nitial Upload
		{0x204B,0x3},  //nitial Upload
		{0x205B,0x64},  //nitial Upload
		{0x205C,0x0},  //nitial Upload
		{0x4018,0x3F},  //nitial Upload
		{0x403B,0xB},  //nitial Upload
		{0x403E,0xE},  //nitial Upload
		{0x402B,0x6},  //nitial Upload
		{0x401E,0x2},  //nitial Upload
		{0x4038,0x3B},  //nitial Upload
		{0x1077,0x0},  //nitial Upload
		{0x1078,0x0},  //nitial Upload
		{0x1009,0x8},  //nitial Upload
		{0x100A,0x0},  //nitial Upload
		{0x110F,0x8},  //nitial Upload
		{0x1110,0x0},  //nitial Upload
		{0x1006,0x2},  //nitial Upload
		{0x402C,0x64},  //nitial Upload
		{0x3064,0x0},  //nitial Upload
		{0x3065,0xF0},  //nitial Upload
		{0x4013,0x13},  //nitial Upload
		{0x401F,0x9},  //nitial Upload
		{0x4020,0x13},  //nitial Upload
		{0x4044,0x75},  //nitial Upload
		{0x4027,0x0},  //nitial Upload
		{0x3215,0x69},  //nitial Upload
		{0x3216,0xF},  //nitial Upload
		{0x322B,0x69},  //nitial Upload
		{0x322C,0xF},  //nitial Upload
		{0x4051,0x80},  //nitial Upload
		{0x4052,0x10},  //nitial Upload
		{0x4057,0x80},  //nitial Upload
		{0x4058,0x10},  //nitial Upload
		{0x3212,0x59},  //nitial Upload
		{0x4047,0x8F},  //nitial Upload
		{0x4026,0x10},  //nitial Upload
		{0x4032,0x53},  //nitial Upload
		{0x4036,0x17},  //nitial Upload
		{0x50B8,0xF4},  //nitial Upload
		{0x3016,0x0},  //nitial Upload
		{0x3017,0x2C},  //nitial Upload
		{0x3018,0x8C},  //nitial Upload
		{0x3019,0x45},  //nitial Upload
		{0x301A,0x5},  //nitial Upload
		{0x3013,0xA},  //nitial Upload
		{0x301B,0x0},  //nitial Upload
		{0x301C,0x4},  //nitial Upload
		{0x301D,0x88},  //nitial Upload
		{0x301E,0x45},  //nitial Upload
		{0x301F,0x5},  //nitial Upload
		{0x3020,0x0},  //nitial Upload
		{0x3021,0x4},  //nitial Upload
		{0x3022,0x88},  //nitial Upload
		{0x3023,0x45},  //nitial Upload
		{0x3024,0x5},  //nitial Upload
		{0x3025,0x0},  //nitial Upload
		{0x3026,0x4},  //nitial Upload
		{0x3027,0x88},  //nitial Upload
		{0x3028,0x45},  //nitial Upload
		{0x3029,0x5},  //nitial Upload
		{0x302F,0x0},  //nitial Upload
		{0x3056,0x0},  //nitial Upload
		{0x3057,0x0},  //nitial Upload
		{0x3300,0x1},  //nitial Upload
		{0x3301,0x0},  //nitial Upload
		{0x3302,0xB0},  //nitial Upload
		{0x3303,0xB0},  //nitial Upload
		{0x3304,0x16},  //nitial Upload
		{0x3305,0x15},  //nitial Upload
		{0x3306,0x1},  //nitial Upload
		{0x3307,0x0},  //nitial Upload
		{0x3308,0x30},  //nitial Upload
		{0x3309,0xA0},  //nitial Upload
		{0x330A,0x16},  //nitial Upload
		{0x330B,0x15},  //nitial Upload
		{0x330C,0x1},  //nitial Upload
		{0x330D,0x0},  //nitial Upload
		{0x330E,0x30},  //nitial Upload
		{0x330F,0xA0},  //nitial Upload
		{0x3310,0x16},  //nitial Upload
		{0x3311,0x15},  //nitial Upload
		{0x3312,0x1},  //nitial Upload
		{0x3313,0x0},  //nitial Upload
		{0x3314,0x30},  //nitial Upload
		{0x3315,0xA0},  //nitial Upload
		{0x3316,0x16},  //nitial Upload
		{0x3317,0x15},  //nitial Upload
		{0x3318,0x1},  //nitial Upload
		{0x3319,0x0},  //nitial Upload
		{0x331A,0x30},  //nitial Upload
		{0x331B,0xA0},  //nitial Upload
		{0x331C,0x16},  //nitial Upload
		{0x331D,0x15},  //nitial Upload
		{0x331E,0x1},  //nitial Upload
		{0x331F,0x0},  //nitial Upload
		{0x3320,0x30},  //nitial Upload
		{0x3321,0xA0},  //nitial Upload
		{0x3322,0x16},  //nitial Upload
		{0x3323,0x15},  //nitial Upload
		{0x3324,0x1},  //nitial Upload
		{0x3325,0x0},  //nitial Upload
		{0x3326,0x30},  //nitial Upload
		{0x3327,0xA0},  //nitial Upload
		{0x3328,0x16},  //nitial Upload
		{0x3329,0x15},  //nitial Upload
		{0x332A,0x2B},  //nitial Upload
		{0x332B,0x0},  //nitial Upload
		{0x332C,0x30},  //nitial Upload
		{0x332D,0xA0},  //nitial Upload
		{0x332E,0x16},  //nitial Upload
		{0x332F,0x15},  //nitial Upload
		{0x3330,0x1},  //nitial Upload
		{0x3331,0x0},  //nitial Upload
		{0x3332,0x10},  //nitial Upload
		{0x3333,0xA0},  //nitial Upload
		{0x3334,0x16},  //nitial Upload
		{0x3335,0x15},  //nitial Upload
		{0x3058,0x8},  //nitial Upload
		{0x3059,0x0},  //nitial Upload
		{0x305A,0x9},  //nitial Upload
		{0x305B,0x0},  //nitial Upload
		{0x3336,0x1},  //nitial Upload
		{0x3337,0x0},  //nitial Upload
		{0x3338,0x90},  //nitial Upload
		{0x3339,0xB0},  //nitial Upload
		{0x333A,0x16},  //nitial Upload
		{0x333B,0x15},  //nitial Upload
		{0x333C,0x1F},  //nitial Upload
		{0x333D,0x0},  //nitial Upload
		{0x333E,0x10},  //nitial Upload
		{0x333F,0xA0},  //nitial Upload
		{0x3340,0x16},  //nitial Upload
		{0x3341,0x15},  //nitial Upload
		{0x3342,0x52},  //nitial Upload
		{0x3343,0x0},  //nitial Upload
		{0x3344,0x10},  //nitial Upload
		{0x3345,0x80},  //nitial Upload
		{0x3346,0x16},  //nitial Upload
		{0x3347,0x15},  //nitial Upload
		{0x3348,0x1},  //nitial Upload
		{0x3349,0x0},  //nitial Upload
		{0x334A,0x10},  //nitial Upload
		{0x334B,0x80},  //nitial Upload
		{0x334C,0x16},  //nitial Upload
		{0x334D,0x1D},  //nitial Upload
		{0x334E,0x1},  //nitial Upload
		{0x334F,0x0},  //nitial Upload
		{0x3350,0x50},  //nitial Upload
		{0x3351,0x84},  //nitial Upload
		{0x3352,0x16},  //nitial Upload
		{0x3353,0x1D},  //nitial Upload
		{0x3354,0x18},  //nitial Upload
		{0x3355,0x0},  //nitial Upload
		{0x3356,0x10},  //nitial Upload
		{0x3357,0x84},  //nitial Upload
		{0x3358,0x16},  //nitial Upload
		{0x3359,0x1D},  //nitial Upload
		{0x335A,0x80},  //nitial Upload
		{0x335B,0x2},  //nitial Upload
		{0x335C,0x10},  //nitial Upload
		{0x335D,0xC4},  //nitial Upload
		{0x335E,0x14},  //nitial Upload
		{0x335F,0x1D},  //nitial Upload
		{0x3360,0xA5},  //nitial Upload
		{0x3361,0x0},  //nitial Upload
		{0x3362,0x10},  //nitial Upload
		{0x3363,0x84},  //nitial Upload
		{0x3364,0x16},  //nitial Upload
		{0x3365,0x1D},  //nitial Upload
		{0x3366,0x1},  //nitial Upload
		{0x3367,0x0},  //nitial Upload
		{0x3368,0x90},  //nitial Upload
		{0x3369,0x84},  //nitial Upload
		{0x336A,0x16},  //nitial Upload
		{0x336B,0x1D},  //nitial Upload
		{0x336C,0x12},  //nitial Upload
		{0x336D,0x0},  //nitial Upload
		{0x336E,0x10},  //nitial Upload
		{0x336F,0x84},  //nitial Upload
		{0x3370,0x16},  //nitial Upload
		{0x3371,0x15},  //nitial Upload
		{0x3372,0x32},  //nitial Upload
		{0x3373,0x0},  //nitial Upload
		{0x3374,0x30},  //nitial Upload
		{0x3375,0x84},  //nitial Upload
		{0x3376,0x16},  //nitial Upload
		{0x3377,0x15},  //nitial Upload
		{0x3378,0x26},  //nitial Upload
		{0x3379,0x0},  //nitial Upload
		{0x337A,0x10},  //nitial Upload
		{0x337B,0x84},  //nitial Upload
		{0x337C,0x16},  //nitial Upload
		{0x337D,0x15},  //nitial Upload
		{0x337E,0x80},  //nitial Upload
		{0x337F,0x2},  //nitial Upload
		{0x3380,0x10},  //nitial Upload
		{0x3381,0xC4},  //nitial Upload
		{0x3382,0x14},  //nitial Upload
		{0x3383,0x15},  //nitial Upload
		{0x3384,0xA9},  //nitial Upload
		{0x3385,0x0},  //nitial Upload
		{0x3386,0x10},  //nitial Upload
		{0x3387,0x84},  //nitial Upload
		{0x3388,0x16},  //nitial Upload
		{0x3389,0x15},  //nitial Upload
		{0x338A,0x41},  //nitial Upload
		{0x338B,0x0},  //nitial Upload
		{0x338C,0x10},  //nitial Upload
		{0x338D,0x80},  //nitial Upload
		{0x338E,0x16},  //nitial Upload
		{0x338F,0x15},  //nitial Upload
		{0x3390,0x2},  //nitial Upload
		{0x3391,0x0},  //nitial Upload
		{0x3392,0x10},  //nitial Upload
		{0x3393,0xA0},  //nitial Upload
		{0x3394,0x16},  //nitial Upload
		{0x3395,0x15},  //nitial Upload
		{0x305C,0x18},  //nitial Upload
		{0x305D,0x0},  //nitial Upload
		{0x305E,0x19},  //nitial Upload
		{0x305F,0x0},  //nitial Upload
		{0x3396,0x1},  //nitial Upload
		{0x3397,0x0},  //nitial Upload
		{0x3398,0x90},  //nitial Upload
		{0x3399,0x30},  //nitial Upload
		{0x339A,0x56},  //nitial Upload
		{0x339B,0x57},  //nitial Upload
		{0x339C,0x1},  //nitial Upload
		{0x339D,0x0},  //nitial Upload
		{0x339E,0x10},  //nitial Upload
		{0x339F,0x20},  //nitial Upload
		{0x33A0,0xD6},  //nitial Upload
		{0x33A1,0x17},  //nitial Upload
		{0x33A2,0x1},  //nitial Upload
		{0x33A3,0x0},  //nitial Upload
		{0x33A4,0x10},  //nitial Upload
		{0x33A5,0x28},  //nitial Upload
		{0x33A6,0xD6},  //nitial Upload
		{0x33A7,0x17},  //nitial Upload
		{0x33A8,0x3},  //nitial Upload
		{0x33A9,0x0},  //nitial Upload
		{0x33AA,0x10},  //nitial Upload
		{0x33AB,0x20},  //nitial Upload
		{0x33AC,0xD6},  //nitial Upload
		{0x33AD,0x17},  //nitial Upload
		{0x33AE,0x61},  //nitial Upload
		{0x33AF,0x0},  //nitial Upload
		{0x33B0,0x10},  //nitial Upload
		{0x33B1,0x20},  //nitial Upload
		{0x33B2,0xD6},  //nitial Upload
		{0x33B3,0x15},  //nitial Upload
		{0x33B4,0x1},  //nitial Upload
		{0x33B5,0x0},  //nitial Upload
		{0x33B6,0x10},  //nitial Upload
		{0x33B7,0x20},  //nitial Upload
		{0x33B8,0xD6},  //nitial Upload
		{0x33B9,0x1D},  //nitial Upload
		{0x33BA,0x1},  //nitial Upload
		{0x33BB,0x0},  //nitial Upload
		{0x33BC,0x50},  //nitial Upload
		{0x33BD,0x20},  //nitial Upload
		{0x33BE,0xD6},  //nitial Upload
		{0x33BF,0x1D},  //nitial Upload
		{0x33C0,0x2C},  //nitial Upload
		{0x33C1,0x0},  //nitial Upload
		{0x33C2,0x10},  //nitial Upload
		{0x33C3,0x20},  //nitial Upload
		{0x33C4,0xD6},  //nitial Upload
		{0x33C5,0x1D},  //nitial Upload
		{0x33C6,0x1},  //nitial Upload
		{0x33C7,0x0},  //nitial Upload
		{0x33C8,0x90},  //nitial Upload
		{0x33C9,0x20},  //nitial Upload
		{0x33CA,0xD6},  //nitial Upload
		{0x33CB,0x1D},  //nitial Upload
		{0x33CC,0x83},  //nitial Upload
		{0x33CD,0x0},  //nitial Upload
		{0x33CE,0x10},  //nitial Upload
		{0x33CF,0x20},  //nitial Upload
		{0x33D0,0xD6},  //nitial Upload
		{0x33D1,0x15},  //nitial Upload
		{0x33D2,0x1},  //nitial Upload
		{0x33D3,0x0},  //nitial Upload
		{0x33D4,0x10},  //nitial Upload
		{0x33D5,0x30},  //nitial Upload
		{0x33D6,0xD6},  //nitial Upload
		{0x33D7,0x15},  //nitial Upload
		{0x33D8,0x1},  //nitial Upload
		{0x33D9,0x0},  //nitial Upload
		{0x33DA,0x10},  //nitial Upload
		{0x33DB,0x20},  //nitial Upload
		{0x33DC,0xD6},  //nitial Upload
		{0x33DD,0x15},  //nitial Upload
		{0x33DE,0x1},  //nitial Upload
		{0x33DF,0x0},  //nitial Upload
		{0x33E0,0x10},  //nitial Upload
		{0x33E1,0x20},  //nitial Upload
		{0x33E2,0x56},  //nitial Upload
		{0x33E3,0x15},  //nitial Upload
		{0x33E4,0x7},  //nitial Upload
		{0x33E5,0x0},  //nitial Upload
		{0x33E6,0x10},  //nitial Upload
		{0x33E7,0x20},  //nitial Upload
		{0x33E8,0x16},  //nitial Upload
		{0x33E9,0x15},  //nitial Upload
		{0x3060,0x26},  //nitial Upload
		{0x3061,0x0},  //nitial Upload
		{0x302A,0xFF},  //nitial Upload
		{0x302B,0xFF},  //nitial Upload
		{0x302C,0xFF},  //nitial Upload
		{0x302D,0xFF},  //nitial Upload
		{0x302E,0x3F},  //nitial Upload
		{0x3013,0xB},  //nitial Upload
		{0x102B,0x2C},  //nitial Upload
		{0x102C,0x1},  //nitial Upload
		{0x1035,0x54},  //nitial Upload
		{0x1036,0x0},  //nitial Upload
		{0x3090,0x2A},  //nitial Upload
		{0x3091,0x1},  //nitial Upload
		{0x30C6,0x5},  //nitial Upload
		{0x30C7,0x0},  //nitial Upload
		{0x30C8,0x0},  //nitial Upload
		{0x30C9,0x0},  //nitial Upload
		{0x30CA,0x0},  //nitial Upload
		{0x30CB,0x0},  //nitial Upload
		{0x30CC,0x0},  //nitial Upload
		{0x30CD,0x0},  //nitial Upload
		{0x30CE,0x0},  //nitial Upload
		{0x30CF,0x5},  //nitial Upload
		{0x30D0,0x0},  //nitial Upload
		{0x30D1,0x0},  //nitial Upload
		{0x30D2,0x0},  //nitial Upload
		{0x30D3,0x0},  //nitial Upload
		{0x30D4,0x0},  //nitial Upload
		{0x30D5,0x0},  //nitial Upload
		{0x30D6,0x0},  //nitial Upload
		{0x30D7,0x0},  //nitial Upload
		{0x30F3,0x5},  //nitial Upload
		{0x30F4,0x0},  //nitial Upload
		{0x30F5,0x0},  //nitial Upload
		{0x30F6,0x0},  //nitial Upload
		{0x30F7,0x0},  //nitial Upload
		{0x30F8,0x0},  //nitial Upload
		{0x30F9,0x0},  //nitial Upload
		{0x30FA,0x0},  //nitial Upload
		{0x30FB,0x0},  //nitial Upload
		{0x30D8,0x5},  //nitial Upload
		{0x30D9,0x0},  //nitial Upload
		{0x30DA,0x0},  //nitial Upload
		{0x30DB,0x0},  //nitial Upload
		{0x30DC,0x0},  //nitial Upload
		{0x30DD,0x0},  //nitial Upload
		{0x30DE,0x0},  //nitial Upload
		{0x30DF,0x0},  //nitial Upload
		{0x30E0,0x0},  //nitial Upload
		{0x30E1,0x5},  //nitial Upload
		{0x30E2,0x0},  //nitial Upload
		{0x30E3,0x0},  //nitial Upload
		{0x30E4,0x0},  //nitial Upload
		{0x30E5,0x0},  //nitial Upload
		{0x30E6,0x0},  //nitial Upload
		{0x30E7,0x0},  //nitial Upload
		{0x30E8,0x0},  //nitial Upload
		{0x30E9,0x0},  //nitial Upload
		{0x30F3,0x5},  //nitial Upload
		{0x30F4,0x2},  //nitial Upload
		{0x30F5,0x0},  //nitial Upload
		{0x30F6,0x17},  //nitial Upload
		{0x30F7,0x1},  //nitial Upload
		{0x30F8,0x0},  //nitial Upload
		{0x30F9,0x0},  //nitial Upload
		{0x30FA,0x0},  //nitial Upload
		{0x30FB,0x0},  //nitial Upload
		{0x30D8,0x3},  //nitial Upload
		{0x30D9,0x1},  //nitial Upload
		{0x30DA,0x0},  //nitial Upload
		{0x30DB,0x19},  //nitial Upload
		{0x30DC,0x1},  //nitial Upload
		{0x30DD,0x0},  //nitial Upload
		{0x30DE,0x0},  //nitial Upload
		{0x30DF,0x0},  //nitial Upload
		{0x30E0,0x0},  //nitial Upload
		{0x30A2,0x5},  //nitial Upload
		{0x30A3,0x2},  //nitial Upload
		{0x30A4,0x0},  //nitial Upload
		{0x30A5,0x22},  //nitial Upload
		{0x30A6,0x0},  //nitial Upload
		{0x30A7,0x0},  //nitial Upload
		{0x30A8,0x0},  //nitial Upload
		{0x30A9,0x0},  //nitial Upload
		{0x30AA,0x0},  //nitial Upload
		{0x30AB,0x5},  //nitial Upload
		{0x30AC,0x2},  //nitial Upload
		{0x30AD,0x0},  //nitial Upload
		{0x30AE,0x22},  //nitial Upload
		{0x30AF,0x0},  //nitial Upload
		{0x30B0,0x0},  //nitial Upload
		{0x30B1,0x0},  //nitial Upload
		{0x30B2,0x0},  //nitial Upload
		{0x30B3,0x0},  //nitial Upload
		{0x30BD,0x5},  //nitial Upload
		{0x30BE,0x9F},  //nitial Upload
		{0x30BF,0x0},  //nitial Upload
		{0x30C0,0x7D},  //nitial Upload
		{0x30C1,0x0},  //nitial Upload
		{0x30C2,0x0},  //nitial Upload
		{0x30C3,0x0},  //nitial Upload
		{0x30C4,0x0},  //nitial Upload
		{0x30C5,0x0},  //nitial Upload
		{0x30B4,0x4},  //nitial Upload
		{0x30B5,0x9C},  //nitial Upload
		{0x30B6,0x0},  //nitial Upload
		{0x30B7,0x7D},  //nitial Upload
		{0x30B8,0x0},  //nitial Upload
		{0x30B9,0x0},  //nitial Upload
		{0x30BA,0x0},  //nitial Upload
		{0x30BB,0x0},  //nitial Upload
		{0x30BC,0x0},  //nitial Upload
		{0x30FC,0x5},  //nitial Upload
		{0x30FD,0x0},  //nitial Upload
		{0x30FE,0x0},  //nitial Upload
		{0x30FF,0x0},  //nitial Upload
		{0x3100,0x0},  //nitial Upload
		{0x3101,0x0},  //nitial Upload
		{0x3102,0x0},  //nitial Upload
		{0x3103,0x0},  //nitial Upload
		{0x3104,0x0},  //nitial Upload
		{0x3105,0x5},  //nitial Upload
		{0x3106,0x0},  //nitial Upload
		{0x3107,0x0},  //nitial Upload
		{0x3108,0x0},  //nitial Upload
		{0x3109,0x0},  //nitial Upload
		{0x310A,0x0},  //nitial Upload
		{0x310B,0x0},  //nitial Upload
		{0x310C,0x0},  //nitial Upload
		{0x310D,0x0},  //nitial Upload
		{0x3099,0x5},  //nitial Upload
		{0x309A,0x96},  //nitial Upload
		{0x309B,0x0},  //nitial Upload
		{0x309C,0x6},  //nitial Upload
		{0x309D,0x0},  //nitial Upload
		{0x309E,0x0},  //nitial Upload
		{0x309F,0x0},  //nitial Upload
		{0x30A0,0x0},  //nitial Upload
		{0x30A1,0x0},  //nitial Upload
		{0x310E,0x5},  //nitial Upload
		{0x310F,0x2},  //nitial Upload
		{0x3110,0x0},  //nitial Upload
		{0x3111,0x2B},  //nitial Upload
		{0x3112,0x0},  //nitial Upload
		{0x3113,0x0},  //nitial Upload
		{0x3114,0x0},  //nitial Upload
		{0x3115,0x0},  //nitial Upload
		{0x3116,0x0},  //nitial Upload
		{0x3117,0x5},  //nitial Upload
		{0x3118,0x2},  //nitial Upload
		{0x3119,0x0},  //nitial Upload
		{0x311A,0x2C},  //nitial Upload
		{0x311B,0x0},  //nitial Upload
		{0x311C,0x0},  //nitial Upload
		{0x311D,0x0},  //nitial Upload
		{0x311E,0x0},  //nitial Upload
		{0x311F,0x0},  //nitial Upload
		{0x30EA,0x0},  //nitial Upload
		{0x30EB,0x0},  //nitial Upload
		{0x30EC,0x0},  //nitial Upload
		{0x30ED,0x0},  //nitial Upload
		{0x30EE,0x0},  //nitial Upload
		{0x30EF,0x0},  //nitial Upload
		{0x30F0,0x0},  //nitial Upload
		{0x30F1,0x0},  //nitial Upload
		{0x30F2,0x0},  //nitial Upload
		{0x313B,0x3},  //nitial Upload
		{0x313C,0x31},  //nitial Upload
		{0x313D,0x0},  //nitial Upload
		{0x313E,0x7},  //nitial Upload
		{0x313F,0x0},  //nitial Upload
		{0x3140,0x68},  //nitial Upload
		{0x3141,0x0},  //nitial Upload
		{0x3142,0x34},  //nitial Upload
		{0x3143,0x0},  //nitial Upload
		{0x31A0,0x3},  //nitial Upload
		{0x31A1,0x16},  //nitial Upload
		{0x31A2,0x0},  //nitial Upload
		{0x31A3,0x8},  //nitial Upload
		{0x31A4,0x0},  //nitial Upload
		{0x31A5,0x7E},  //nitial Upload
		{0x31A6,0x0},  //nitial Upload
		{0x31A7,0x8},  //nitial Upload
		{0x31A8,0x0},  //nitial Upload
		{0x31A9,0x3},  //nitial Upload
		{0x31AA,0x16},  //nitial Upload
		{0x31AB,0x0},  //nitial Upload
		{0x31AC,0x8},  //nitial Upload
		{0x31AD,0x0},  //nitial Upload
		{0x31AE,0x7E},  //nitial Upload
		{0x31AF,0x0},  //nitial Upload
		{0x31B0,0x8},  //nitial Upload
		{0x31B1,0x0},  //nitial Upload
		{0x31B2,0x3},  //nitial Upload
		{0x31B3,0x16},  //nitial Upload
		{0x31B4,0x0},  //nitial Upload
		{0x31B5,0x8},  //nitial Upload
		{0x31B6,0x0},  //nitial Upload
		{0x31B7,0x7E},  //nitial Upload
		{0x31B8,0x0},  //nitial Upload
		{0x31B9,0x8},  //nitial Upload
		{0x31BA,0x0},  //nitial Upload
		{0x3120,0x5},  //nitial Upload
		{0x3121,0x45},  //nitial Upload
		{0x3122,0x0},  //nitial Upload
		{0x3123,0x1D},  //nitial Upload
		{0x3124,0x0},  //nitial Upload
		{0x3125,0xA9},  //nitial Upload
		{0x3126,0x0},  //nitial Upload
		{0x3127,0x6D},  //nitial Upload
		{0x3128,0x0},  //nitial Upload
		{0x3129,0x5},  //nitial Upload
		{0x312A,0x15},  //nitial Upload
		{0x312B,0x0},  //nitial Upload
		{0x312C,0xA},  //nitial Upload
		{0x312D,0x0},  //nitial Upload
		{0x312E,0x45},  //nitial Upload
		{0x312F,0x0},  //nitial Upload
		{0x3130,0x1D},  //nitial Upload
		{0x3131,0x0},  //nitial Upload
		{0x3132,0x5},  //nitial Upload
		{0x3133,0x7D},  //nitial Upload
		{0x3134,0x0},  //nitial Upload
		{0x3135,0xA},  //nitial Upload
		{0x3136,0x0},  //nitial Upload
		{0x3137,0xA9},  //nitial Upload
		{0x3138,0x0},  //nitial Upload
		{0x3139,0x6D},  //nitial Upload
		{0x313A,0x0},  //nitial Upload
		{0x3144,0x5},  //nitial Upload
		{0x3145,0x0},  //nitial Upload
		{0x3146,0x0},  //nitial Upload
		{0x3147,0x30},  //nitial Upload
		{0x3148,0x0},  //nitial Upload
		{0x3149,0x0},  //nitial Upload
		{0x314A,0x0},  //nitial Upload
		{0x314B,0x0},  //nitial Upload
		{0x314C,0x0},  //nitial Upload
		{0x314D,0x3},  //nitial Upload
		{0x314E,0x0},  //nitial Upload
		{0x314F,0x0},  //nitial Upload
		{0x3150,0x31},  //nitial Upload
		{0x3151,0x0},  //nitial Upload
		{0x3152,0x0},  //nitial Upload
		{0x3153,0x0},  //nitial Upload
		{0x3154,0x0},  //nitial Upload
		{0x3155,0x0},  //nitial Upload
		{0x31D8,0x5},  //nitial Upload
		{0x31D9,0x3A},  //nitial Upload
		{0x31DA,0x0},  //nitial Upload
		{0x31DB,0x2E},  //nitial Upload
		{0x31DC,0x0},  //nitial Upload
		{0x31DD,0x9E},  //nitial Upload
		{0x31DE,0x0},  //nitial Upload
		{0x31DF,0x7E},  //nitial Upload
		{0x31E0,0x0},  //nitial Upload
		{0x31E1,0x5},  //nitial Upload
		{0x31E2,0x4},  //nitial Upload
		{0x31E3,0x0},  //nitial Upload
		{0x31E4,0x4},  //nitial Upload
		{0x31E5,0x0},  //nitial Upload
		{0x31E6,0x73},  //nitial Upload
		{0x31E7,0x0},  //nitial Upload
		{0x31E8,0x4},  //nitial Upload
		{0x31E9,0x0},  //nitial Upload
		{0x31EA,0x5},  //nitial Upload
		{0x31EB,0x0},  //nitial Upload
		{0x31EC,0x0},  //nitial Upload
		{0x31ED,0x0},  //nitial Upload
		{0x31EE,0x0},  //nitial Upload
		{0x31EF,0x0},  //nitial Upload
		{0x31F0,0x0},  //nitial Upload
		{0x31F1,0x0},  //nitial Upload
		{0x31F2,0x0},  //nitial Upload
		{0x31F3,0x0},  //nitial Upload
		{0x31F4,0x0},  //nitial Upload
		{0x31F5,0x0},  //nitial Upload
		{0x31F6,0x0},  //nitial Upload
		{0x31F7,0x0},  //nitial Upload
		{0x31F8,0x0},  //nitial Upload
		{0x31F9,0x0},  //nitial Upload
		{0x31FA,0x0},  //nitial Upload
		{0x31FB,0x5},  //nitial Upload
		{0x31FC,0x0},  //nitial Upload
		{0x31FD,0x0},  //nitial Upload
		{0x31FE,0x0},  //nitial Upload
		{0x31FF,0x0},  //nitial Upload
		{0x3200,0x0},  //nitial Upload
		{0x3201,0x0},  //nitial Upload
		{0x3202,0x0},  //nitial Upload
		{0x3203,0x0},  //nitial Upload
		{0x3204,0x0},  //nitial Upload
		{0x3205,0x0},  //nitial Upload
		{0x3206,0x0},  //nitial Upload
		{0x3207,0x0},  //nitial Upload
		{0x3208,0x0},  //nitial Upload
		{0x3209,0x0},  //nitial Upload
		{0x320A,0x0},  //nitial Upload
		{0x320B,0x0},  //nitial Upload
		{0x3164,0x5},  //nitial Upload
		{0x3165,0x14},  //nitial Upload
		{0x3166,0x0},  //nitial Upload
		{0x3167,0xC},  //nitial Upload
		{0x3168,0x0},  //nitial Upload
		{0x3169,0x44},  //nitial Upload
		{0x316A,0x0},  //nitial Upload
		{0x316B,0x1F},  //nitial Upload
		{0x316C,0x0},  //nitial Upload
		{0x316D,0x5},  //nitial Upload
		{0x316E,0x7C},  //nitial Upload
		{0x316F,0x0},  //nitial Upload
		{0x3170,0xC},  //nitial Upload
		{0x3171,0x0},  //nitial Upload
		{0x3172,0xA8},  //nitial Upload
		{0x3173,0x0},  //nitial Upload
		{0x3174,0x6F},  //nitial Upload
		{0x3175,0x0},  //nitial Upload
		{0x31C4,0x5},  //nitial Upload
		{0x31C5,0x24},  //nitial Upload
		{0x31C6,0x1},  //nitial Upload
		{0x31C7,0x4},  //nitial Upload
		{0x31C8,0x0},  //nitial Upload
		{0x31C9,0x5},  //nitial Upload
		{0x31CA,0x24},  //nitial Upload
		{0x31CB,0x1},  //nitial Upload
		{0x31CC,0x4},  //nitial Upload
		{0x31CD,0x0},  //nitial Upload
		{0x31CE,0x5},  //nitial Upload
		{0x31CF,0x24},  //nitial Upload
		{0x31D0,0x1},  //nitial Upload
		{0x31D1,0x4},  //nitial Upload
		{0x31D2,0x0},  //nitial Upload
		{0x31D3,0x5},  //nitial Upload
		{0x31D4,0x73},  //nitial Upload
		{0x31D5,0x0},  //nitial Upload
		{0x31D6,0xB1},  //nitial Upload
		{0x31D7,0x0},  //nitial Upload
		{0x3176,0x5},  //nitial Upload
		{0x3177,0x10},  //nitial Upload
		{0x3178,0x0},  //nitial Upload
		{0x3179,0x56},  //nitial Upload
		{0x317A,0x0},  //nitial Upload
		{0x317B,0x0},  //nitial Upload
		{0x317C,0x0},  //nitial Upload
		{0x317D,0x0},  //nitial Upload
		{0x317E,0x0},  //nitial Upload
		{0x317F,0x5},  //nitial Upload
		{0x3180,0x6A},  //nitial Upload
		{0x3181,0x0},  //nitial Upload
		{0x3182,0xAD},  //nitial Upload
		{0x3183,0x0},  //nitial Upload
		{0x3184,0x0},  //nitial Upload
		{0x3185,0x0},  //nitial Upload
		{0x3186,0x0},  //nitial Upload
		{0x3187,0x0},  //nitial Upload
		{0x100C,0x7E},  //nitial Upload
		{0x100D,0x0},  //nitial Upload
		{0x1115,0x7E},  //nitial Upload
		{0x1116,0x0},  //nitial Upload
		{0x1012,0xDF},  //nitial Upload
		{0x1013,0x2B},  //nitial Upload
		{0x1002,0x4},  //nitial Upload
		{0x0043,0x0},  //ensor Control Mode.SLEEP_POWER_MODE(0)
		{0x0043,0x0},  //ensor Control Mode.IDLE_POWER_MODE(0)
		{0x0043,0x4},  //ensor Control Mode.SYSTEM_CLOCK_ENABLE(0)
		{0x0043,0xC},  //ensor Control Mode.SRAM_CLOCK_ENABLE(0)
		{0x1002,0x4},  //ensor Control Mode.IMAGER_RUN_CONT(0)
		{0x1001,0x41},  //ensor Control Mode.EXT_EVENT_SEL(0)
		{0x10F2,0x1},  //ensor Control Mode.NB_OF_FRAMES_A(0)
		{0x10F3,0x0},  //ensor Control Mode.NB_OF_FRAMES_A(1)
		{0x1111,0x1},  //ensor Control Mode.NB_OF_FRAMES_B(0)
		{0x1112,0x0},  //ensor Control Mode.NB_OF_FRAMES_B(1)
		{0x0012,0x0},  //O Drive Strength.DIG_DRIVE_STRENGTH(0)
		{0x0012,0x0},  //O Drive Strength.CCI_DRIVE_STRENGTH(0)
		{0x1001,0x41},  //eadout && Exposure.EXT_EXP_PW_SEL(0)
		{0x10D0,0x0},  //eadout && Exposure.EXT_EXP_PW_DELAY(0)
		{0x10D1,0x0},  //eadout && Exposure.EXT_EXP_PW_DELAY(1)
		{0x1012,0x91},  //eadout && Exposure.VBLANK_A(0)
		{0x1013,0xD},  //eadout && Exposure.VBLANK_A(1)
		{0x1103,0x91},  //eadout && Exposure.VBLANK_B(0)
		{0x1104,0xD},  //eadout && Exposure.VBLANK_B(1)
		{0x100C,0x80},  //eadout && Exposure.EXP_TIME_A(0)
		{0x100D,0x0},  //eadout && Exposure.EXP_TIME_A(1)
		{0x1115,0x80},  //eadout && Exposure.EXP_TIME_B(0)
		{0x1116,0x0},  //eadout && Exposure.EXP_TIME_B(1)
		{0x102B,0x10},  //eadout && Exposure.ROW_LENGTH_A(0)
		{0x102C,0x2},  //eadout && Exposure.ROW_LENGTH_A(1)
		{0x1113,0x30},  //eadout && Exposure.ROW_LENGTH_B(0)
		{0x1114,0x1},  //eadout && Exposure.ROW_LENGTH_B(1)
		{0x2008,0x20},  //orizontal ROI.HSIZE_A(0)
		{0x2009,0x3},  //orizontal ROI.HSIZE_A(1)
		{0x2098,0x20},  //orizontal ROI.HSIZE_B(0)
		{0x2099,0x3},  //orizontal ROI.HSIZE_B(1)
		{0x200A,0x0},  //orizontal ROI.HSTART_A(0)
		{0x200B,0x0},  //orizontal ROI.HSTART_A(1)
		{0x209A,0x0},  //orizontal ROI.HSTART_B(0)
		{0x209B,0x0},  //orizontal ROI.HSTART_B(1)
		{0x207D,0x40},  //orizontal ROI.MIPI_HSIZE(0)
		{0x207E,0x6},  //orizontal ROI.MIPI_HSIZE(1)
		{0x107D,0xFA},  //ertical ROI.VSTART0_A(0)
		{0x107E,0x0},  //ertical ROI.VSTART0_A(1)
		{0x1087,0x84},  //ertical ROI.VSIZE0_A(0)
		{0x1088,0x3},  //ertical ROI.VSIZE0_A(1)
		{0x1105,0x0},  //ertical ROI.VSTART0_B(0)
		{0x1106,0x0},  //ertical ROI.VSTART0_B(1)
		{0x110A,0x78},  //ertical ROI.VSIZE0_B(0)
		{0x110B,0x5},  //ertical ROI.VSIZE0_B(1)
		{0x107D,0xFA},  //ertical ROI.VSTART1_A(0)
		{0x107E,0x0},  //ertical ROI.VSTART1_A(1)
		{0x107F,0x0},  //ertical ROI.VSTART1_A(2)
		{0x1087,0x84},  //ertical ROI.VSIZE1_A(0)
		{0x1088,0x3},  //ertical ROI.VSIZE1_A(1)
		{0x1089,0x0},  //ertical ROI.VSIZE1_A(2)
		{0x1105,0x0},  //ertical ROI.VSTART1_B(0)
		{0x1106,0x0},  //ertical ROI.VSTART1_B(1)
		{0x1107,0x0},  //ertical ROI.VSTART1_B(2)
		{0x110A,0x78},  //ertical ROI.VSIZE1_B(0)
		{0x110B,0x5},  //ertical ROI.VSIZE1_B(1)
		{0x110C,0x0},  //ertical ROI.VSIZE1_B(2)
		{0x107D,0xFA},  //ertical ROI.VSTART2_A(0)
		{0x107E,0x0},  //ertical ROI.VSTART2_A(1)
		{0x107F,0x0},  //ertical ROI.VSTART2_A(2)
		{0x1080,0x0},  //ertical ROI.VSTART2_A(3)
		{0x1081,0x0},  //ertical ROI.VSTART2_A(4)
		{0x1087,0x84},  //ertical ROI.VSIZE2_A(0)
		{0x1088,0x3},  //ertical ROI.VSIZE2_A(1)
		{0x1089,0x0},  //ertical ROI.VSIZE2_A(2)
		{0x108A,0x0},  //ertical ROI.VSIZE2_A(3)
		{0x108B,0x0},  //ertical ROI.VSIZE2_A(4)
		{0x1105,0x0},  //ertical ROI.VSTART2_B(0)
		{0x1106,0x0},  //ertical ROI.VSTART2_B(1)
		{0x1107,0x0},  //ertical ROI.VSTART2_B(2)
		{0x1108,0x0},  //ertical ROI.VSTART2_B(3)
		{0x1109,0x0},  //ertical ROI.VSTART2_B(4)
		{0x110A,0x78},  //ertical ROI.VSIZE2_B(0)
		{0x110B,0x5},  //ertical ROI.VSIZE2_B(1)
		{0x110C,0x0},  //ertical ROI.VSIZE2_B(2)
		{0x110D,0x0},  //ertical ROI.VSIZE2_B(3)
		{0x110E,0x0},  //ertical ROI.VSIZE2_B(4)
		{0x209C,0x0},  //irroring && Flipping.HFLIP_A(0)
		{0x209D,0x0},  //irroring && Flipping.HFLIP_B(0)
		{0x1095,0x0},  //irroring && Flipping.VFLIP(0)
		{0x2063,0x0},  //irroring && Flipping.BIT_ORDER(0)
		{0x6006,0x0},  //IPI.TX_CTRL_EN(0)
		{0x5004,0x1},  //IPI.datarate
		{0x5086,0x2},  //IPI.datarate
		{0x5087,0x4E},  //IPI.datarate
		{0x5088,0x0},  //IPI.datarate
		{0x5090,0x0},  //IPI.datarate
		{0x5091,0x8},  //IPI.datarate
		{0x5092,0x14},  //IPI.datarate
		{0x5093,0xF},  //IPI.datarate
		{0x5094,0x6},  //IPI.datarate
		{0x5095,0x32},  //IPI.datarate
		{0x5096,0xE},  //IPI.datarate
		{0x5097,0x0},  //IPI.datarate
		{0x5098,0x11},  //IPI.datarate
		{0x5004,0x0},  //IPI.datarate
		{0x2066,0x6C},  //IPI.datarate
		{0x2067,0x7},  //IPI.datarate
		{0x206E,0x7E},  //IPI.datarate
		{0x206F,0x6},  //IPI.datarate
		{0x20AC,0x7E},  //IPI.datarate
		{0x20AD,0x6},  //IPI.datarate
		{0x2076,0xC8},  //IPI.datarate
		{0x2077,0x0},  //IPI.datarate
		{0x20B4,0xC8},  //IPI.datarate
		{0x20B5,0x0},  //IPI.datarate
		{0x2078,0x1E},  //IPI.datarate
		{0x2079,0x4},  //IPI.datarate
		{0x20B6,0x1E},  //IPI.datarate
		{0x20B7,0x4},  //IPI.datarate
		{0x207A,0xD4},  //IPI.datarate
		{0x207B,0x4},  //IPI.datarate
		{0x20B8,0xD4},  //IPI.datarate
		{0x20B9,0x4},  //IPI.datarate
		{0x208D,0x4},  //IPI.CSI2_DTYPE(0)
		{0x208E,0x0},  //IPI.CSI2_DTYPE(1)
		{0x207C,0x0},  //IPI.VC_ID(0)
		{0x6001,0x7},  //IPI.TINIT(0)
		{0x6002,0xD8},  //IPI.TINIT(1)
		{0x6010,0x0},  //IPI.FRAME_MODE(0)
		{0x6010,0x0},  //IPI.EMBEDDED_FRAME_MODE(0)
		{0x6011,0x0},  //IPI.DATA_ENABLE_POLARITY(0)
		{0x6011,0x0},  //IPI.HSYNC_POLARITY(0)
		{0x6011,0x0},  //IPI.VSYNC_POLARITY(0)
		{0x6012,0x1},  //IPI.LANE(0)
		{0x6013,0x0},  //IPI.CLK_MODE(0)
		{0x6016,0x0},  //IPI.FRAME_COUNTER(0)
		{0x6017,0x0},  //IPI.FRAME_COUNTER(1)
		{0x6037,0x1},  //IPI.LINE_COUNT_RAW8(0)
		{0x6037,0x3},  //IPI.LINE_COUNT_RAW10(0)
		{0x6037,0x7},  //IPI.LINE_COUNT_RAW12(0)
		{0x6039,0x1},  //IPI.LINE_COUNT_EMB(0)
		{0x6018,0x0},  //IPI.CCI_READ_INTERRUPT_EN(0)
		{0x6018,0x0},  //IPI.CCI_WRITE_INTERRUPT_EN(0)
		{0x6065,0x0},  //IPI.TWAKE_TIMER(0)
		{0x6066,0x0},  //IPI.TWAKE_TIMER(1)
		{0x601C,0x0},  //IPI.SKEW_CAL_EN(0)
		{0x601D,0x0},  //IPI.SKEW_COUNT(0)
		{0x601E,0x22},  //IPI.SKEW_COUNT(1)
		{0x601F,0x0},  //IPI.SCRAMBLING_EN(0)
		{0x6003,0x1},  //IPI.INIT_SKEW_EN(0)
		{0x6004,0x7A},  //IPI.INIT_SKEW(0)
		{0x6005,0x12},  //IPI.INIT_SKEW(1)
		{0x6006,0x1},  //IPI.TX_CTRL_EN(0)
		{0x4006,0x8},  //rocessing.BSP(0)
		{0x209E,0x2},  //rocessing.BIT_DEPTH(0)
		{0x2045,0x1},  //rocessing.CDS_RNC(0)
		{0x2048,0x1},  //rocessing.CDS_IMG(0)
		{0x204B,0x3},  //rocessing.RNC_EN(0)
		{0x205B,0x64},  //rocessing.RNC_DARK_TARGET(0)
		{0x205C,0x0},  //rocessing.RNC_DARK_TARGET(1)
		{0x24DC,0x12},  //efect Pixel Correction.DC_ENABLE(0)
		{0x24DC,0x10},  //efect Pixel Correction.DC_MODE(0)
		{0x24DC,0x0},  //efect Pixel Correction.DC_REPLACEMENT_VALUE(0)
		{0x24DD,0x0},  //efect Pixel Correction.DC_LIMIT_LOW(0)
		{0x24DE,0x0},  //efect Pixel Correction.DC_LIMIT_HIGH(0)
		{0x24DF,0x0},  //efect Pixel Correction.DC_LIMIT_HIGH_MODE(0)
		{0x10D7,0x0},  //llumination Trigger.ILLUM_EN(0)
		{0x10D8,0x2},  //llumination Trigger.ILLUM_POL(0)
		{0x205D,0x0},  //istogram.HIST_EN(0)
		{0x205E,0x0},  //istogram.HIST_USAGE_RATIO(0)
		{0x2063,0x0},  //istogram.PIXEL_DATA_SUPP(0)
		{0x2063,0x0},  //istogram.PIXEL_TRANSMISSION(0)
		{0x2091,0x0},  //est Pattern Generator.TPG_EN(0)
		{0x2091,0x10},  //est Pattern Generator.TPG_CONFIG(0)
		//{0x1003,0x10},  //oftware Trigger.IMAGER_STATE(0)
		//{0x10F0,0x1},  //oftware Trigger.IMAGER_RUN(0)


};

ALT_AVALON_I2C_DEV_t *hdmi_i2c_dev, *camera_i2c_dev;
ALT_AVALON_I2C_STATUS_CODE hdmi_i2c_status, mipi_i2c_status;

int main()
{

    // Initialize all of the HAL drivers used in this design (UART, SPI, onchip flash, etc.)
    alt_sys_init();
    //alt_putstr("I am Here\r\n");

	//IOWR_32DIRECT (MIPI_SYSTEM_0_MIPI_DPHY_BASE,RX_DLANE0_DESKEW_DELAY, DPHY_RX_DESKEW);
	//IOWR_32DIRECT (MIPI_SYSTEM_0_MIPI_DPHY_BASE,DPHY_CSR, 0x01);

    // Camera in Reset
    IOWR_ALTERA_AVALON_PIO_DATA(PIO_MIPI_BASE, MIRA220_RESETn);

	// activate sign of life in FPGA
    IOWR_ALTERA_AVALON_PIO_DATA(PIO_LED_BASE, 0x03);  // Only Red LED on

    camera_i2c_dev = alt_avalon_i2c_open(MIPI_I2C_NAME);
    if (NULL==camera_i2c_dev)    {
    	alt_putstr("Error: Cannot find MIPI I2C Peripheral\r\n");
    }

    hdmi_i2c_dev = alt_avalon_i2c_open(HDMI_I2C_NAME);
    if (NULL==hdmi_i2c_dev)    {
    	alt_putstr("Error: Cannot find HDMI I2C Peripheral\r\n");
    }

    // start at mid exposure
    exp_time_index = 6;

    // Register the VFW interrupt handler
	alt_ic_isr_register (MIPI_SYSTEM_0_VVP_VFW_IRQ_INTERRUPT_CONTROLLER_ID, MIPI_SYSTEM_0_VVP_VFW_IRQ, VFW_isr, NULL, NULL);
	// Enable VFW IRQ in the Interrupt Controller
	alt_ic_irq_enable (MIPI_SYSTEM_0_VVP_VFW_IRQ_INTERRUPT_CONTROLLER_ID, MIPI_SYSTEM_0_VVP_VFW_IRQ);

	// Enable PB IRQ in the Interrupt Controller
	alt_ic_irq_enable (FPGA_PB_IRQ_INTERRUPT_CONTROLLER_ID, FPGA_PB_IRQ);
    // Register the PB interrupt handler
	alt_ic_isr_register (FPGA_PB_IRQ_INTERRUPT_CONTROLLER_ID, FPGA_PB_IRQ, PB_isr, NULL, NULL);
    // Unmask the PB IRQ for both pins
    IOWR_ALTERA_AVALON_PIO_IRQ_MASK(FPGA_PB_BASE, 0x03);

    printf("\r\n++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++\r\n");
	global_var = IORD_ALTERA_AVALON_SYSID_QSYS_ID(SYSID_BASE);
	// Print Camera Model - Quartus version
	printf("System ID: 0x%04X-%02X.%01X.%01X\r\n",(alt_u16)(global_var >> 16), (alt_u8)((global_var & 0x0FF00) >> 8), (alt_u8)((global_var & 0x00F0) >> 4), (alt_u8)((global_var & 0x000F)));

    //printf("Enable the VFW to RUN with interrupts\r\n");
	IOWR_32DIRECT (MIPI_SYSTEM_0_VVP_VFW_BASE,VFW_IRQ_CONTROL, 0x01);	// Field Write IRQ bit
	IOWR_32DIRECT (MIPI_SYSTEM_0_VVP_VFW_BASE,VFW_RUN, 0x01);	// RUN
	IOWR_32DIRECT (MIPI_SYSTEM_0_VVP_VFW_BASE,VFW_COMMIT, 0x01);	// COMMIT
	IOWR_32DIRECT(MIPI_SYSTEM_0_VVP_VFW_BASE,VFW_BUFFER_ACKNOWLEDGE,0x00);	// BUFFER_ACKNOWLEDGE

	hdmi_i2c_test();
    init_adv7511 ();


    // set up the TPG (in output path to HDMI)
    init_TPG();

    //set the address of the device using
    alt_avalon_i2c_master_target_set(camera_i2c_dev,MIRA220_i2c_addr);


    // Initialize the camera and VVP input path IP
    init_MIRA220 ();



	// activate sign of life in FPGA
    IOWR_ALTERA_AVALON_PIO_DATA(PIO_LED_BASE, 0x05);  // Only Green LED on

    signOn();

    // Dummy infinite loop
    while(1) {
        // Read ASCII character from UART
        uart_rx_char = alt_getchar();
        printf("%c\r\n", uart_rx_char);

        // If key pressed is T/t, the accelerometer x/y/z axes are read and values displayed
        switch (uart_rx_char) {
        case 'B' : // Select Color Bars from TPG
        case 'b' :
        	IOWR_32DIRECT (HDMI_SYSTEM_0_HDMI_VVP_CVO_BASE,0x0154, 0x04);	// TPG
            break;
        case 'V' : // Select Video Path
        case 'v' :
        	IOWR_32DIRECT (HDMI_SYSTEM_0_HDMI_VVP_CVO_BASE,0x0154, 0x08);	// Video
            break;
        case 'M' : // LPDDR4 test
        case 'm' :
        	lpddr4_cal_test();
            break;
        case 'T' : // MIRA220 Test Pattern Enable
        case 't' :
            alt_avalon_i2c_master_target_set(camera_i2c_dev,MIRA220_i2c_addr);
        	poke(MIRA220_TEST_PATTERN_CFG_REG, MIRA220_TEST_PATTERN_DIAG_GRAD | MIRA220_TEST_PATTERN_ENABLE, 1);
        	alt_putstr("  MIRA220 Vertical Gradient Test Pattern Enabled\r\n");
            break;
        case 'U' : // MIRA220 Test Pattern Disable
        case 'u' :
            alt_avalon_i2c_master_target_set(camera_i2c_dev,MIRA220_i2c_addr);
        	poke(MIRA220_TEST_PATTERN_CFG_REG, 0, 1);
        	alt_putstr("  MIRA220 Test Pattern Disabled\r\n");
            break;
        case 'I' : // Increase MIPI DPHY Deskew
        case 'i' :
      	    if (exp_time_index != 12) {
      		  exp_time_index++;
      		  // set exposure
      		  poke(MIRA220_REG_EXPOSURE,   exp_time[exp_time_index] & 0x0FF, 1);
      		  poke(MIRA220_REG_EXPOSURE+1, exp_time[exp_time_index] >> 8, 1);
      	    }
    	    printf("Exposure Index is : %d\r\n>",exp_time_index);
    		break;
        case 'D' : // Decrease MIPI Deskew
        case 'd' :
       	  if (exp_time_index != 0) {
       		exp_time_index--;
       		// set exposure
       		poke(MIRA220_REG_EXPOSURE,   exp_time[exp_time_index] & 0x0FF, 1);
       		poke(MIRA220_REG_EXPOSURE+1, exp_time[exp_time_index] >> 8, 1);
       	   }
       	   printf("Exposure Index is : %d\r\n>",exp_time_index);
            break;
#ifdef debug
        case 'W' : // Read Video Frame Writer Version and ID (0x0000)
        case 'w' :
        	// Return Value should be 0x6AF7_0249
        	printf ("VFW VID_PID    : 0x%08X\n\r", IORD_32DIRECT (MIPI_SYSTEM_0_VVP_VFW_BASE,0x0000));
        	printf ("VFW IP Version : 0x%08X\n\r", IORD_32DIRECT (MIPI_SYSTEM_0_VVP_VFW_BASE,0x0004));
        	printf ("VFW RUN Status : 0x%02X\n\r", IORD_32DIRECT (MIPI_SYSTEM_0_VVP_VFW_BASE,0x016C));
        	printf ("VFW Max Width  : %d\n\r", IORD_32DIRECT (MIPI_SYSTEM_0_VVP_VFW_BASE,0x0014));
        	printf ("VFW Max Height : %d\n\r", IORD_32DIRECT (MIPI_SYSTEM_0_VVP_VFW_BASE,0x0010));
        	printf ("Number of Bits per Color Sample : %d\r\n", IORD_32DIRECT (MIPI_SYSTEM_0_VVP_VFW_BASE,0x0018));
        	printf ("Number of Color Planes          : %d\r\n", IORD_32DIRECT (MIPI_SYSTEM_0_VVP_VFW_BASE,0x001C));
        	printf ("Number of Pixels in Parallel    : %d\r\n", IORD_32DIRECT (MIPI_SYSTEM_0_VVP_VFW_BASE,0x0020));
            break;
        case 'S' : // Read Video Frame Writer Version and ID (0x0000)
        case 's' :
        	// Report a few DPHY Register Content
        	printf ("IP ID             (0x00) : 0x%02X\n\r", IORD_8DIRECT (MIPI_SYSTEM_0_MIPI_DPHY_BASE,0x00));
        	printf ("IP_CAP            (0x01) : 0x%02X\n\r", IORD_8DIRECT (MIPI_SYSTEM_0_MIPI_DPHY_BASE,0x01));
        	printf ("D0_CAP            (0x03) : 0x%02X\n\r", IORD_8DIRECT (MIPI_SYSTEM_0_MIPI_DPHY_BASE,0x03));
        	printf ("RX CAP            (0x08) : 0x%02X\n\r", IORD_8DIRECT (MIPI_SYSTEM_0_MIPI_DPHY_BASE,0x08));
        	printf ("DPHY_CSR          (0x10) : 0x%02X\n\r", IORD_8DIRECT (MIPI_SYSTEM_0_MIPI_DPHY_BASE,0x10));
        	printf ("CLK_CSR           (0x1C) : 0x%02X\n\r", IORD_8DIRECT (MIPI_SYSTEM_0_MIPI_DPHY_BASE,0x1C));
        	printf ("CLK_STAT          (0x1D) : 0x%02X\n\n\r", IORD_8DIRECT (MIPI_SYSTEM_0_MIPI_DPHY_BASE,0x1D));
        	printf ("RX_DLANE0_DSKW_DEL(0x22) : %d\r\n",     IORD_8DIRECT (MIPI_SYSTEM_0_MIPI_DPHY_BASE,0x22));
        	printf ("DLANE_CSR_0       (0x20) : 0x%02X\n\r", IORD_8DIRECT (MIPI_SYSTEM_0_MIPI_DPHY_BASE,0x20));
        	printf ("DLANE_STAT_0      (0x21) : 0x%02X\n\r", IORD_8DIRECT (MIPI_SYSTEM_0_MIPI_DPHY_BASE,0x21));
        	printf ("RX_DLANE0_ERR     (0x23) : 0x%02X\r\n\n", IORD_8DIRECT (MIPI_SYSTEM_0_MIPI_DPHY_BASE,0x23));
        	printf ("RX_DLANE1_DSKW_DEL(0x26) : %d\r\n",     IORD_8DIRECT (MIPI_SYSTEM_0_MIPI_DPHY_BASE,0x26));
        	printf ("DLANE_CSR_1       (0x24) : 0x%02X\n\r", IORD_8DIRECT (MIPI_SYSTEM_0_MIPI_DPHY_BASE,0x24));
        	printf ("DLANE_STAT_1      (0x25) : 0x%02X\n\r", IORD_8DIRECT (MIPI_SYSTEM_0_MIPI_DPHY_BASE,0x25));
        	printf ("RX_DLANE1_ERR     (0x27) : 0x%02X\r\n\n", IORD_8DIRECT (MIPI_SYSTEM_0_MIPI_DPHY_BASE,0x27));
        	printf ("RX_CAL_REG_CTRL   (0x60) : 0x%02X\r\n", IORD_8DIRECT (MIPI_SYSTEM_0_MIPI_DPHY_BASE,0x60));
        	printf ("RX_CAL_STATUS     (0x61) : 0x%02X\r\n", IORD_8DIRECT (MIPI_SYSTEM_0_MIPI_DPHY_BASE,0x61));

     		break;
        case 'R' : // MIRA220 Test Pattern Disable
        case 'r' :
        	printf("\nHistogram VID_PID: 0x%08X\n\r",IORD_32DIRECT(MIPI_SYSTEM_0_VVP_HISTOGRAM_BASE,0x0000));
        	// Start sampling new histogram
        	IOWR_32DIRECT(MIPI_SYSTEM_0_VVP_HISTOGRAM_BASE,HIST_CONTROL,1 << 31);
        	alt_putstr("Start Sampling\r\n");
        	// wait for it to be done
        	while ((IORD_32DIRECT(MIPI_SYSTEM_0_VVP_HISTOGRAM_BASE,HIST_STATUS) & 0x04) == 0x00);
        	// Remove Request
        	IOWR_32DIRECT(MIPI_SYSTEM_0_VVP_HISTOGRAM_BASE,HIST_CONTROL,0x0000);
      		// Read some data
        	for (alt_u16 j=0; j<NUM_HIST_BINS; j++) {
        		printf("Bin %d at address 0x%04X = 0x%04X\r\n", j, ROI_STATISTICS_START+(4*j), IORD_32DIRECT(MIPI_SYSTEM_0_VVP_HISTOGRAM_BASE,(ROI_STATISTICS_START+(4*j))));
        	}
            break;
#endif
   	default :
			signOn();
    		break;
        }
        alt_putstr("\r\n>");
    }

return 0;
}

/******************************************************************/

void signOn ()
{
	alt_putstr("\r\n");
	alt_putstr("Available Commands :\r\n");
	alt_putstr("  B -- Select Color Bars from TPG\r\n");
	alt_putstr("  V -- Select Normal Video path (default)\r\n");
	alt_putstr("  M -- LPDDR4 Calibration test\r\n");
	alt_putstr("  T -- MIRA220 Mono Diagonal Test Pattern Enable\r\n");
	alt_putstr("  U -- MIRA220 Mono Diagonal Test Pattern Disable (default)\r\n");
	alt_putstr("  I -- Increase Exposure\r\n");
	alt_putstr("  D -- Decrease Exposure\r\n");
#ifdef debug
	alt_putstr("  W -- Read Video Frame Writer VID_PID - Should be 0x6AF7_0249\r\n");
	alt_putstr("  R -- Histogram ROI Statistics\r\n");
	alt_putstr("  S -- DPHY 0 Status\r\n");
#endif
	alt_putstr(">");
}


/****************************************************************************/
// lpddr4_cal_test : Checking for calibration success
//      - LPDDR4 channel passes if calibration is successful
//      - 1-bit status (bit 0) is read by NIOSV
/****************************************************************************/
void lpddr4_cal_test () {
	 // Read state of LPDDR4 to see if it passed calibration
	 lpddr4_cal_status = IORD_32DIRECT(EMIF_LPDDR4_S0_AXI4LITE_BASE,lpddr4_status) & 0x03;
	 printf("LPDDR4 Calibration Status: 0x%08lX\r\n", lpddr4_cal_status);
	 if (lpddr4_cal_status & 0x01)  // bit1 is LPDDR4B status
		    alt_putstr("LPDDR4 -> Passed Calibration\r\n\n");
	 else
		    alt_putstr("LPDDR4 -> Failed. Error: Calibration\r\n\n");
}


/****************************************************************************/
// hdmi_i2c_test : Tests I2C access to HDMI ADV7511 device
//      - set the I2C MUX selection to SC1 (0x05) to communicate with ADV7511
//      - Reads address F9 to confirm it is 0x7C
/****************************************************************************/
void hdmi_i2c_test () {
	// Select HDMI_I2C on TCA9544A MUX then read HDMI I2C (SC1)
#ifdef debug
	alt_putstr("Selecting HDMI_I2C (SC1) on TCA9544A MUX\r\n");
#endif
	alt_avalon_i2c_master_target_set(hdmi_i2c_dev,mux_i2c_addr);
	wData[0]=0x05;
	hdmi_i2c_status = alt_avalon_i2c_master_tx(hdmi_i2c_dev,wData, 1, ALT_AVALON_I2C_NO_INTERRUPTS);
#ifdef debug
	alt_putstr("Set HDMI_I2C MUX to SC1 (0x05)\r\n");
#endif
	if (hdmi_i2c_status != ALT_AVALON_I2C_SUCCESS) {
		alt_putstr("Error Writing to I2C_MUX\r\n");
	} else {
	    alt_avalon_i2c_master_target_set(hdmi_i2c_dev,hdmi_i2c_addr);
#ifdef debug
		alt_putstr("\r\nReading HDMI ADV7511 I2C Register Address 0xF9\r\n");
#endif
        wData[0] = 0xf9;
        hdmi_i2c_status = alt_avalon_i2c_master_tx_rx(hdmi_i2c_dev, wData, 1, rData, 1, ALT_AVALON_I2C_NO_INTERRUPTS);
        if (hdmi_i2c_status != ALT_AVALON_I2C_SUCCESS)
        	alt_putstr("No Data read from ADV7511 Address 0xF9\r\n");
        else {
#ifdef debug
        	printf("Register 0xF9 should contain 0x7C, Value read : 0x%02X\r\n",rData[0]);
#endif
        	if (rData[0] == 0x7C) {
#ifdef debug
        		printf("HDMI I2C ADV7511 -> Passed\r\n");
#endif
        	} else {
        		printf("HDMI I2C ADV7511 ->Failed. Error: Failed I2C Read of HDMI ADV7511\r\n");
        	}
        }
	}
}



/****************************************************************************/
// init_adv7511 : Initialize ADV7511 HDMI TX Controller
/****************************************************************************/
void init_adv7511 () {

	// 0x41[6] = 0b0 for power-up and power-down
	//wData[0] = 0x10;	// power up
	//writeI2C(HDMI_I2C_BASE, hdmi_i2c_addr, 0x41, 1);

	wData[0] = 0x41;	// Upper Register Address Byte
	wData[1] = 0x10;	// Lower Register Address Byte
	//writeI2C(MIPI_I2C_BASE, MIRA220_i2c_addr, 0x3ff9, 1);
    mipi_i2c_status = alt_avalon_i2c_master_tx(hdmi_i2c_dev,wData, 2, ALT_AVALON_I2C_NO_INTERRUPTS);
    if (hdmi_i2c_status != ALT_AVALON_I2C_SUCCESS) {
    	printf("Error Writing to ADV7511 Address 0x%02X\r\n", wData[0]);
    } else {
#ifdef debug
    	printf("Successful I2C write to ADV7511");
#endif
    }

	// Fixed registers that must be set on power up
	wData[0] = 0x98;
	wData[1] = 0x03;
	//writeI2C(HDMI_I2C_BASE, hdmi_i2c_addr, 0x98, 1);
	alt_avalon_i2c_master_tx(hdmi_i2c_dev,wData, 2, ALT_AVALON_I2C_NO_INTERRUPTS);
	wData[0] = 0x9A;
	wData[1] = 0xE0;
	//writeI2C(HDMI_I2C_BASE, hdmi_i2c_addr, 0x9A, 1);
	alt_avalon_i2c_master_tx(hdmi_i2c_dev,wData, 2, ALT_AVALON_I2C_NO_INTERRUPTS);
	wData[0] = 0x9C;
	wData[1] = 0x30;
	//writeI2C(HDMI_I2C_BASE, hdmi_i2c_addr, 0x9C, 1);
	alt_avalon_i2c_master_tx(hdmi_i2c_dev,wData, 2, ALT_AVALON_I2C_NO_INTERRUPTS);
	wData[0] = 0x9D;
	wData[1] = 0x01;
	//writeI2C(HDMI_I2C_BASE, hdmi_i2c_addr, 0x9D, 1);
	alt_avalon_i2c_master_tx(hdmi_i2c_dev,wData, 2, ALT_AVALON_I2C_NO_INTERRUPTS);
	wData[0] = 0xA2;
	wData[1] = 0xA4;
	//writeI2C(HDMI_I2C_BASE, hdmi_i2c_addr, 0xA2, 1);
	alt_avalon_i2c_master_tx(hdmi_i2c_dev,wData, 2, ALT_AVALON_I2C_NO_INTERRUPTS);
	wData[0] = 0xA3;
	wData[1] = 0xA4;
	//writeI2C(HDMI_I2C_BASE, hdmi_i2c_addr, 0xA3, 1);
	alt_avalon_i2c_master_tx(hdmi_i2c_dev,wData, 2, ALT_AVALON_I2C_NO_INTERRUPTS);
	wData[0] = 0xE0;
	wData[1] = 0xD0;
	//writeI2C(HDMI_I2C_BASE, hdmi_i2c_addr, 0xE0, 1);
	alt_avalon_i2c_master_tx(hdmi_i2c_dev,wData, 2, ALT_AVALON_I2C_NO_INTERRUPTS);
	wData[0] = 0x55;
	wData[1] = 0x02;
	//writeI2C(HDMI_I2C_BASE, hdmi_i2c_addr, 0x55, 1);
	alt_avalon_i2c_master_tx(hdmi_i2c_dev,wData, 2, ALT_AVALON_I2C_NO_INTERRUPTS);
	// Set up the video input mode:

	// 0x15[3:0]=0x1 Video Format ID (YCbCr 4:2:2, 2x pixel clock and separate syncs)
	wData[0] = 0x15;
	wData[1] = 0x01;
	//writeI2C(HDMI_I2C_BASE, hdmi_i2c_addr, 0x15, 1);
	alt_avalon_i2c_master_tx(hdmi_i2c_dev,wData, 2, ALT_AVALON_I2C_NO_INTERRUPTS);

	// Table 21 - 0x48[4:3]=01(right justified)
	// 0x48[6] = 0b1 Reverse HDMI_D bit order
	wData[0] = 0x48;
	wData[1] = 0x08;
	//writeI2C(HDMI_I2C_BASE, hdmi_i2c_addr, 0x48, 1);
	alt_avalon_i2c_master_tx(hdmi_i2c_dev,wData, 2, ALT_AVALON_I2C_NO_INTERRUPTS);

	// 0x16[7] - Output Format (1 = 4:2:2)
	// 0x16[5:4] - Input Color Depth (11=8-bit, 01=10-bit, 10=12-bit)
	// 0x16[3:2] - Video Input (style1=10 , style2=01, style3=11)
	// 0x16[0]   - Color Space Selection (1 = YCbCr)
	wData[0] = 0x16;
	wData[1] = 0xa8;
	//writeI2C(HDMI_I2C_BASE, hdmi_i2c_addr, 0x16, 1);
	alt_avalon_i2c_master_tx(hdmi_i2c_dev,wData, 2, ALT_AVALON_I2C_NO_INTERRUPTS);

	// 0x17[1] - Aspect ratio of input video (4x3 = 0b0, 16x9 = 0b1)
	wData[0] = 0x17;
	wData[1] = 0x02;
	//writeI2C(HDMI_I2C_BASE, hdmi_i2c_addr, 0x17, 1);
	alt_avalon_i2c_master_tx(hdmi_i2c_dev,wData, 2, ALT_AVALON_I2C_NO_INTERRUPTS);

	// Set up the video output mode:

	// 0xBA[7:5] - Clock Delay
	wData[0] = 0xBA;
	wData[1] = 0x03 << 5;
	//writeI2C(HDMI_I2C_BASE, hdmi_i2c_addr, 0xBA, 1);
	alt_avalon_i2c_master_tx(hdmi_i2c_dev,wData, 2, ALT_AVALON_I2C_NO_INTERRUPTS);

	// 0xAF[1] = 0b1 for HDMI – Manual HDMI or DVI mode select
	wData[0] = 0xAF;
	wData[1] = 0x06;
	//writeI2C(HDMI_I2C_BASE, hdmi_i2c_addr, 0xAF, 1);
	alt_avalon_i2c_master_tx(hdmi_i2c_dev,wData, 2, ALT_AVALON_I2C_NO_INTERRUPTS);

	// 0x40[7] - 0b1  Enable GC
	wData[0] = 0x40;
	wData[1] = 0x00;
	//writeI2C(HDMI_I2C_BASE, hdmi_i2c_addr, 0x40, 1);
	alt_avalon_i2c_master_tx(hdmi_i2c_dev,wData, 2, ALT_AVALON_I2C_NO_INTERRUPTS);


	// 0x4C[3:0] - Output Color Depth and General Control Color Depth (GC CD)
	wData[0] = 0x4C;
	wData[1] = 0x00;	// 24-bit/pixel
	//writeI2C(HDMI_I2C_BASE, hdmi_i2c_addr, 0x4C, 1);
	alt_avalon_i2c_master_tx(hdmi_i2c_dev,wData, 2, ALT_AVALON_I2C_NO_INTERRUPTS);

	// Related to embedded sync generation (See Table 33-35)

	//1080-60p settings
	wData[0] = 0x35;
	wData[1] = 0x2F;
	wData[2] = 0xE9;
	wData[3] = 0x0F;
	wData[4] = 0x00;
	wData[5] = 0x43;
	wData[6] = 0x80;
	//writeI2C(HDMI_I2C_BASE, hdmi_i2c_addr, 0x35, 6);
	alt_avalon_i2c_master_tx(hdmi_i2c_dev,wData, 7, ALT_AVALON_I2C_NO_INTERRUPTS);

	//1080-60p settings
	wData[0] = 0xD7;
	wData[1] = 0x16;
	wData[2] = 0x02;
	wData[3] = 0xC0;
	wData[4] = 0x10;
	wData[5] = 0x05;
	//writeI2C(HDMI_I2C_BASE, hdmi_i2c_addr, 0xD7, 5);
	alt_avalon_i2c_master_tx(hdmi_i2c_dev,wData, 6, ALT_AVALON_I2C_NO_INTERRUPTS);

	//1080-60p settings
	wData[0] = 0x30;
	wData[1] = 0x16;
	wData[2] = 0x02;
	wData[3] = 0xC0;
	wData[4] = 0x10;
	wData[5] = 0x05;
	//writeI2C(HDMI_I2C_BASE, hdmi_i2c_addr, 0x30, 5);
	alt_avalon_i2c_master_tx(hdmi_i2c_dev,wData, 6, ALT_AVALON_I2C_NO_INTERRUPTS);

	// 0x18[7] = 0b0 for YCbCr to RGB – CSC Disable
	// 0x18[6:5] = 0b00 for YCbCr to RGB – CSC Scaling Factor
	wData[0] = 0x18;
	wData[1] = 0x06;
	//writeI2C(HDMI_I2C_BASE, hdmi_i2c_addr, 0x18, 1);
	alt_avalon_i2c_master_tx(hdmi_i2c_dev,wData, 2, ALT_AVALON_I2C_NO_INTERRUPTS);

#ifdef debug
	printf("\r\nFinished initializing ADV7511\r\n");
#endif

}

/*******************************************************/
/* init_TPG -   */
/*******************************************************/

void init_TPG ()
{

	// CVO REG_FALLBACK = 0x04 -> Force TPG
	//                    0x08 -> Force Video Input
	IOWR_32DIRECT (HDMI_SYSTEM_0_HDMI_VVP_CVO_BASE, 0x154,0x08);
	//printf ("CVO REG_FALLBACK Register : 0x%08X\r\n", IORD_32DIRECT (HDMI_SYSTEM_0_HDMI_VVP_CVO_BASE, 0x154));

	// Stop the TPG
	IOWR_32DIRECT (HDMI_SYSTEM_0_HDMI_VVP_TPG_BASE,0x0148, 0);
	IOWR_32DIRECT (HDMI_SYSTEM_0_HDMI_VVP_TPG_BASE,0x014C, 0x01);	// COMMIT
	// wait for it to go idle
	while ( (IORD_32DIRECT(HDMI_SYSTEM_0_HDMI_VVP_TPG_BASE,0x140)) & 0x01 );

	// 1920x1080
	IOWR_32DIRECT (HDMI_SYSTEM_0_HDMI_VVP_TPG_BASE,0x0120, 1920);	// IMG_INFO_WIDTH (1920)
	IOWR_32DIRECT (HDMI_SYSTEM_0_HDMI_VVP_TPG_BASE,0x0124, 1080);	// IMG_INFO_WIDTH (1080)

	// write solid color
	IOWR_32DIRECT (HDMI_SYSTEM_0_HDMI_VVP_TPG_BASE,0x0164, 0xF0);	// Red
	IOWR_32DIRECT (HDMI_SYSTEM_0_HDMI_VVP_TPG_BASE,0x0160, 0xF0);	// Green
	IOWR_32DIRECT (HDMI_SYSTEM_0_HDMI_VVP_TPG_BASE,0x015C, 0xF0);	// Blue
	IOWR_32DIRECT (HDMI_SYSTEM_0_HDMI_VVP_TPG_BASE,0x0168, 0x00);	// Bars: 0=color, 1=grey, 2=B&W, 3=mixed

	// select pattern. 0=bars, 1=solid color
	IOWR_32DIRECT (HDMI_SYSTEM_0_HDMI_VVP_TPG_BASE,0x0150, 0x00);

	// Enable TPG
	IOWR_32DIRECT (HDMI_SYSTEM_0_HDMI_VVP_TPG_BASE,0x0148, 1);
	IOWR_32DIRECT (HDMI_SYSTEM_0_HDMI_VVP_TPG_BASE,0x014C, 0x01);	// COMMIT
}


/****************************************************************************/
// MIRA220_OTP_read : Read 32-bit word from imager OTP memory
//   reg_addr : 8-bit OTP Register Address
//   returns 32-bit content in {rData[3],rData[2],rData[1],rData[0]}
/****************************************************************************/
void MIRA220_OTP_read(alt_u16 reg_addr) {

	// write 0x04 to address 0x0080 - Power On
	poke(0x0080, 0x04, 2);

	// write reg_addr to address 0x0086 - Set Address
	poke(0x0086, reg_addr, 2);

	// read from address 0x0082-0x0085 - Read Data
    // Read Camera Unique Device ID
	peek(0x0082, 4);
	printf("MIRA220 Unique Device ID at 0x%02X = %02X:%02X:%02X:%02X\r\n", reg_addr,wData[3], wData[2],wData[1], wData[0]);

	// write 0x08 to address 0x0080 - Power Off
	poke(0x0080, 0x08, 1);
}


/****************************************************************************/
// poke : Write 1 Byte to MIPI I2C
//   addr : 16-bit Register Address
//   val  : 8-bit Data Value
//   len  : =1 for 1-byte.
/****************************************************************************/
alt_8 poke(alt_u16 addr, alt_u8 val, alt_u8 len) {

	wData[0] = (alt_u8)(addr >> 8);
	wData[1] = (alt_u8)(addr & 0x0FF);
    wData[2] = val & 0xFF;

    mipi_i2c_status = alt_avalon_i2c_master_tx(camera_i2c_dev,wData, 3, ALT_AVALON_I2C_NO_INTERRUPTS);
    if (mipi_i2c_status != ALT_AVALON_I2C_SUCCESS) {
    	printf("Error Writing to MIRA220 Address 0x%02X%02X\r\n", wData[0], wData[1]);
    	return 1;
    }
    return 0;
}

/****************************************************************************/
// peek : Reads Data from MIPI I2C. Data placed in rData[]
//   addr : 16-bit Register Address
//   len  : # of bytes to read
/****************************************************************************/
alt_8 peek(alt_u16 addr, alt_u8 len) {

	wData[0] = (alt_u8)(addr >> 8);
	wData[1] = (alt_u8)(addr & 0x0FF);

	mipi_i2c_status = alt_avalon_i2c_master_tx_rx(camera_i2c_dev,wData, 2, rData, len, ALT_AVALON_I2C_NO_INTERRUPTS);
	if (mipi_i2c_status != ALT_AVALON_I2C_SUCCESS) {
		printf("Error Reading from MIRA220\r\n");
		return 1;
	}
	return 0;
}

/****************************************************************************/
// init_MIRA220 : Initialize VVP components and MIRA220 Camera for 1600x900
/****************************************************************************/
alt_u8 init_MIRA220 () {

#ifdef debug
	// Get hardware DPHY RX Skew setting
	DPHY_RX_DESKEW = IORD_8DIRECT (MIPI_SYSTEM_0_MIPI_DPHY_BASE,0x22);
	printf("Initial DPHY deskew = %d\r\n", DPHY_RX_DESKEW);
#endif
/*
    // Initialize Black Level Correction
    IOWR_32DIRECT(MIPI_SYSTEM_0_VVP_BLC_BASE,BLC_IMG_WIDTH,1600);
    IOWR_32DIRECT(MIPI_SYSTEM_0_VVP_BLC_BASE,BLC_IMG_HEIGHT,900);
	IOWR_32DIRECT(MIPI_SYSTEM_0_VVP_BLC_BASE,BLC_CFA_00_BLACK_PEDASTAL,0);
	IOWR_32DIRECT(MIPI_SYSTEM_0_VVP_BLC_BASE,BLC_CFA_00_COLOR_SCALER,(500));	// CFA_00_COLOR_SCALER
	IOWR_32DIRECT(MIPI_SYSTEM_0_VVP_BLC_BASE,BLC_CFA_01_BLACK_PEDASTAL,0);
	IOWR_32DIRECT(MIPI_SYSTEM_0_VVP_BLC_BASE,BLC_CFA_01_COLOR_SCALER,(500));	// CFA_01_COLOR_SCALER
	IOWR_32DIRECT(MIPI_SYSTEM_0_VVP_BLC_BASE,BLC_CFA_10_BLACK_PEDASTAL,0);
	IOWR_32DIRECT(MIPI_SYSTEM_0_VVP_BLC_BASE,BLC_CFA_10_COLOR_SCALER,(500));	// CFA_10_COLOR_SCALER
	IOWR_32DIRECT(MIPI_SYSTEM_0_VVP_BLC_BASE,BLC_CFA_11_BLACK_PEDASTAL,0);
	IOWR_32DIRECT(MIPI_SYSTEM_0_VVP_BLC_BASE,BLC_CFA_11_COLOR_SCALER,(500));	// CFA_11_COLOR_SCALER
	// Bypass for now
	//IOWR_32DIRECT(MIPI_SYSTEM_0_VVP_BLC_BASE,BLC_CONTROL,0x01);
	IOWR_32DIRECT(MIPI_SYSTEM_0_VVP_BLC_BASE,BLC_COMMIT,0x01);		// COMMIT
*/

	// Initialize the White Balance Correction, in LITE mode
	IOWR_32DIRECT(MIPI_SYSTEM_0_VVP_WBC_BASE,WBC_CONTROL, (0x03 << 1));			// CONTROL.PHASE
	IOWR_32DIRECT(MIPI_SYSTEM_0_VVP_WBC_BASE,WBC_IMG_WIDTH,1600);				// IMG_INFO_WIDTH
	IOWR_32DIRECT(MIPI_SYSTEM_0_VVP_WBC_BASE,WBC_IMG_HEIGHT,900);				// IMG_INFO_HEIGHT
	IOWR_32DIRECT(MIPI_SYSTEM_0_VVP_WBC_BASE,WBC_CFA_00_COLOR_SCALER,(2048 * 111 /100));	// CFA_00_COLOR_SCALER
	IOWR_32DIRECT(MIPI_SYSTEM_0_VVP_WBC_BASE,WBC_CFA_01_COLOR_SCALER,(2048 * 110 /100));	// CFA_01_COLOR_SCALER
	IOWR_32DIRECT(MIPI_SYSTEM_0_VVP_WBC_BASE,WBC_CFA_10_COLOR_SCALER,(2048 * 110 /100));	// CFA_10_COLOR_SCALER
	IOWR_32DIRECT(MIPI_SYSTEM_0_VVP_WBC_BASE,WBC_CFA_11_COLOR_SCALER,(2048 * 108 /100));	// CFA_11_COLOR_SCALER
	IOWR_32DIRECT(MIPI_SYSTEM_0_VVP_WBC_BASE,WBC_COMMIT,0x01);		// COMMIT
	//printf("Initialized the White Balance Correction IP\r\n");

	// demosaic IP configuration
    // In LITE mode
	IOWR_32DIRECT(MIPI_SYSTEM_0_VVP_DEMOSAIC_BASE,DEMOSAIC_IMG_WIDTH,1600);
	IOWR_32DIRECT(MIPI_SYSTEM_0_VVP_DEMOSAIC_BASE,DEMOSAIC_IMG_HEIGHT,900);
	IOWR_32DIRECT(MIPI_SYSTEM_0_VVP_DEMOSAIC_BASE,DEMOSAIC_CONTROL,0x02);	// Mira2202 Color Filter BG/GR
	//printf("Initialized the DEMOSAIC IP\r\n");

/*
    // Initialize 1D LUT
    IOWR_32DIRECT(MIPI_SYSTEM_0_VVP_1D_LUT_BASE,WBC_IMG_WIDTH,1600);
    IOWR_32DIRECT(MIPI_SYSTEM_0_VVP_1D_LUT_BASE,WBC_IMG_HEIGHT,900);
    // Bypass 1D LUT for now
	//IOWR_32DIRECT(MIPI_SYSTEM_0_VVP_1D_LUT_BASE,DEMOSAIC_CONTROL,0x01);
*/

    // Initialize Histogram
    IOWR_32DIRECT(MIPI_SYSTEM_0_VVP_HISTOGRAM_BASE,WBC_IMG_WIDTH,1600);
    IOWR_32DIRECT(MIPI_SYSTEM_0_VVP_HISTOGRAM_BASE,WBC_IMG_HEIGHT,900);
    // Set up ROI in HISTOGRAM
    IOWR_32DIRECT(MIPI_SYSTEM_0_VVP_HISTOGRAM_BASE,HIST_H_START,100);
    IOWR_32DIRECT(MIPI_SYSTEM_0_VVP_HISTOGRAM_BASE,HIST_H_END,1500);
    IOWR_32DIRECT(MIPI_SYSTEM_0_VVP_HISTOGRAM_BASE,HIST_V_START,50);
    IOWR_32DIRECT(MIPI_SYSTEM_0_VVP_HISTOGRAM_BASE,HIST_V_END,850);
	IOWR_32DIRECT(MIPI_SYSTEM_0_VVP_HISTOGRAM_BASE,WBC_COMMIT,0x01);		// COMMIT

	// Initialize the Scaler, in LITE mode
	IOWR_32DIRECT(MIPI_SYSTEM_0_VVP_SCALER_BASE,0x120,1600);	// IMG_INFO_WIDTH
	IOWR_32DIRECT(MIPI_SYSTEM_0_VVP_SCALER_BASE,0x124,900);	// IMG_INFO_HEIGHT
	IOWR_32DIRECT(MIPI_SYSTEM_0_VVP_SCALER_BASE,0x148,1920);	// OUTPUT_WIDTH
	IOWR_32DIRECT(MIPI_SYSTEM_0_VVP_SCALER_BASE,0x14C,1080);	// OUTPUT_HEIGHT
	//printf("Initialized the SCALER IP\r\n");

	// Write image dimensions
	IOWR_32DIRECT (MIPI_SYSTEM_0_VVP_VFW_BASE,VFW_IMG_INFO_WIDTH, (1920*3));	// IMG_INFO_WIDTH
	IOWR_32DIRECT (MIPI_SYSTEM_0_VVP_VFW_BASE,VFW_IMG_INFO_HEIGHT, 1080);		// IMG_INFO_HEIGHT
	IOWR_32DIRECT (MIPI_SYSTEM_0_VVP_VFW_BASE,VFW_NUM_BUFFERS, 0x03);	// Num Buffers
	IOWR_32DIRECT (MIPI_SYSTEM_0_VVP_VFW_BASE,VFW_BUFFER_BASE, 0x80000000);	// BUFFER_BASE
	IOWR_32DIRECT (MIPI_SYSTEM_0_VVP_VFW_BASE,VFW_INTER_BUFFER_OFFSET, 0x01000000);	// BUFFER SPACING
	IOWR_32DIRECT (MIPI_SYSTEM_0_VVP_VFW_BASE,VFW_INTER_LINE_OFFSET, (1920*3));	// LINE SPACING
	// Commit VFW writes, and run
	IOWR_32DIRECT (MIPI_SYSTEM_0_VVP_VFW_BASE,VFW_RUN, 0x01);	// RUN
	IOWR_32DIRECT (MIPI_SYSTEM_0_VVP_VFW_BASE,VFW_COMMIT, 0x01);	// COMMIT
#ifdef debug
	printf("Initialized Video Frame Writer, and started Running with interrupts\r\n");
	//printf("IRQ CONTROL Reg: 0x%08X\r\n",IORD_32DIRECT (MIPI_SYSTEM_0_VVP_VFW_BASE,VFW_IRQ_CONTROL));
#endif

   // Camera ON
    IOWR_ALTERA_AVALON_PIO_DATA(PIO_MIPI_BASE, MIRA220_ENABLE);
    usleep (500000);
    usleep (500000);

    //set the address of the device using
    alt_avalon_i2c_master_target_set(camera_i2c_dev,MIRA220_i2c_addr);

	// MIRA220 RUN (running by default)
    //poke (MIRA220_IMAGER_RUN_REG,MIRA220_IMAGER_RUN_START,1);

#ifdef debug
	// Read Camera Unique Device ID
	MIRA220_OTP_read(MIRA220_REG_CHIP_VER);
#endif

    //peek(MIRA220_REG_MODE_SELECT,4);
    //printf("\r\nData read from  MIRA220 Stream On Register : 0x%02X\n\r", rData[0]);
    //printf("Data read from  MIRA220 Software Reset     : 0x%02X\n\r", rData[3]);

	// write selected registers
#ifdef debug
	printf("\r\nInitializing MIRA220 for 1600x900 Mode Registers ");
#endif
	for (int i = 0; i < sizeof(full_1600_900_60fps_12b_2lanes_reg)/sizeof(struct mira220_reg); i++)
	{
		poke(full_1600_900_60fps_12b_2lanes_reg[i].address, full_1600_900_60fps_12b_2lanes_reg[i].val, 1);
		//alt_putchar('.');
	}
	alt_putstr("\r\n");
	//printf("Size of Init Regs = %d\r\n", sizeof(full_1600_900_60fps_12b_2lanes_reg)/sizeof(struct mira220_reg));
	//Software Trigger.IMAGER_STATE(0)
	poke(MIRA220_IMAGER_STATE_REG,MIRA220_IMAGER_MASTER_EXPOSURE,1);

	// set exposure
	poke(MIRA220_REG_EXPOSURE,   exp_time[exp_time_index] & 0x0FF, 1);
	poke(MIRA220_REG_EXPOSURE+1, exp_time[exp_time_index] >> 8, 1);
#ifdef debug
	peek(MIRA220_REG_EXPOSURE,2);
	printf("Updated MIRA220 Exposure Register : 0x%02X%02X\n\r", rData[1], rData[0]);
	//printf("MIRA220 Soft Reset Reg = %02X\r\n", peek(0x0040, 1));
#endif
	usleep (500000);

	//Software Trigger.IMAGER_RUN(0)
	poke(MIRA220_IMAGER_RUN_REG,MIRA220_IMAGER_RUN_START,1);
    usleep (500000);

	// The Video Frame Reader gets enabled in the VFW_isr
	// Write image dimensions
	IOWR_32DIRECT (HDMI_SYSTEM_0_HDMI_VVP_VFR_BASE,VFR_NUM_BEFFER_SETS, 3);			// Num Buffer sets
	IOWR_32DIRECT (HDMI_SYSTEM_0_HDMI_VVP_VFR_BASE,VFR_BUFFER_MODE, 0);			// Buffer Mode
	IOWR_32DIRECT (HDMI_SYSTEM_0_HDMI_VVP_VFR_BASE,VFR_STARTING_BUFFER_SET, 0);			// Starting Buffer set
	// Buffer 0
	IOWR_32DIRECT (HDMI_SYSTEM_0_HDMI_VVP_VFR_BASE,VFR_BUFFER_0_BASE, 0x80000000);	// BUFFER_0_BASE
	IOWR_32DIRECT (HDMI_SYSTEM_0_HDMI_VVP_VFR_BASE,VFR_BUFFER_0_NUM_BUFFERS, 0x00000001);	// Num Buffers
	IOWR_32DIRECT (HDMI_SYSTEM_0_HDMI_VVP_VFR_BASE,VFR_BUFFER_0_INTER_LINE_OFFSET, (1920*3));	// Inter Line Offset
	IOWR_32DIRECT (HDMI_SYSTEM_0_HDMI_VVP_VFR_BASE,VFR_BUFFER_0_WIDTH, (1280*3));	// IMG_INFO_WIDTH
	IOWR_32DIRECT (HDMI_SYSTEM_0_HDMI_VVP_VFR_BASE,VFR_BUFFER_0_HEIGHT, 1080);		// IMG_INFO_HEIGHT
	// Buffer 1
	IOWR_32DIRECT (HDMI_SYSTEM_0_HDMI_VVP_VFR_BASE,VFR_BUFFER_1_BASE, 0x81000000);	// BUFFER_1_BASE
	IOWR_32DIRECT (HDMI_SYSTEM_0_HDMI_VVP_VFR_BASE,VFR_BUFFER_1_NUM_BUFFERS, 0x00000001);	// Num Buffers
	IOWR_32DIRECT (HDMI_SYSTEM_0_HDMI_VVP_VFR_BASE,VFR_BUFFER_1_INTER_LINE_OFFSET, (1920*3));	// Inter Line Offset
	IOWR_32DIRECT (HDMI_SYSTEM_0_HDMI_VVP_VFR_BASE,VFR_BUFFER_1_WIDTH, (1280*3));	// IMG_INFO_WIDTH
	IOWR_32DIRECT (HDMI_SYSTEM_0_HDMI_VVP_VFR_BASE,VFR_BUFFER_1_HEIGHT, 1080);		// IMG_INFO_HEIGHT
	// Buffer 2
	IOWR_32DIRECT (HDMI_SYSTEM_0_HDMI_VVP_VFR_BASE,VFR_BUFFER_2_BASE, 0x82000000);	// BUFFER_2_BASE
	IOWR_32DIRECT (HDMI_SYSTEM_0_HDMI_VVP_VFR_BASE,VFR_BUFFER_2_NUM_BUFFERS, 0x00000001);	// Num Buffers
	IOWR_32DIRECT (HDMI_SYSTEM_0_HDMI_VVP_VFR_BASE,VFR_BUFFER_2_INTER_LINE_OFFSET, (1920*3));	// Inter Line Offset
	IOWR_32DIRECT (HDMI_SYSTEM_0_HDMI_VVP_VFR_BASE,VFR_BUFFER_2_WIDTH, (1280*3));	// IMG_INFO_WIDTH
	IOWR_32DIRECT (HDMI_SYSTEM_0_HDMI_VVP_VFR_BASE,VFR_BUFFER_2_HEIGHT, 1080);		// IMG_INFO_HEIGHT
	// Commit VFR writes
	IOWR_32DIRECT (HDMI_SYSTEM_0_HDMI_VVP_VFR_BASE,VFR_COMMIT, 0x01);	// COMMIT
#ifdef debug
	printf("Initialized Video Frame Reader, holding it in STOP\r\n");
#endif
	return 0;
}


/* =============================================================
 * VFW_isr - Video Frame Writer interrupt service routine.
 *           Happens every time the VFW writes a frame
 *           Acknowledge the buffer write
 *           Illuminated LED0-Blue as indication
 *           Enables the Video Frame Reader to operate after frame #2 is written
 */
void VFW_isr (void* context)
{

	alt_u32 buffer_start_addr;

    IOWR_ALTERA_AVALON_PIO_DATA(PIO_LED_BASE, 0x06);  // only B on
	//alt_putstr("In VFW IRQ\r\n");
	// Read which buffer got written
	buffer_start_addr = IORD_32DIRECT(MIPI_SYSTEM_0_VVP_VFW_BASE, VFW_BUFFER_START_ADDR);
	//printf("BUFFER: 0x%08lX\r\n", buffer_start_addr);	// BUFFER_START_ADDRESS

	if (buffer_start_addr == LPDDR4_BUFFER_1) {
		// allow the Video Frame Reader to start with Buffer 0
		IOWR_32DIRECT (HDMI_SYSTEM_0_HDMI_VVP_VFR_BASE,VFR_RUN, 0x01);	// RUN
		IOWR_32DIRECT (HDMI_SYSTEM_0_HDMI_VVP_VFR_BASE,VFR_COMMIT, 0x01);	// COMMIT
		//printf("Enabled VFR to RUN\r\n");
	}

	// Acknowledge the Buffer. No need for COMMIT
	IOWR_32DIRECT(MIPI_SYSTEM_0_VVP_VFW_BASE,VFW_BUFFER_ACKNOWLEDGE,0x00);	// BUFFER_ACKNOWLEDGE

	// Clear the interrupt bit
	IOWR_32DIRECT(MIPI_SYSTEM_0_VVP_VFW_BASE,VFW_IRQ_STATUS,0x01);	// IRQ_STATUS
}

/* =============================================================
 * PB_isr - Push-Button interrupt service routine.
 *          Happens every time any of the 2 buttons are pressed
 *          PB[2]/S3
 *          PB[3]/S4
 */
void PB_isr (void* context)
{
   alt_u8 new_pb;

   // wait ~20msec debounce time
   usleep(20*1000);
   new_pb = (IORD_ALTERA_AVALON_PIO_DATA(FPGA_PB_BASE) & 0x03);

   // If PB
   if (new_pb != 0x03) {  // enter only if a button is still pressed
      if ((new_pb & 0x02) == 0x02) {		// is it pb[2]?
#ifdef debug
    	  alt_putstr("FPGA_PB2 pressed\r\n");
#endif
    	  if (exp_time_index != 12) {
    		exp_time_index++;
    		// set exposure
    		poke(MIRA220_REG_EXPOSURE,   exp_time[exp_time_index] & 0x0FF, 1);
    		poke(MIRA220_REG_EXPOSURE+1, exp_time[exp_time_index] >> 8, 1);
    	  }
    	  // wait for button to be released
    	  //while (!(IORD_ALTERA_AVALON_PIO_DATA(FPGA_PB_BASE) & 0x01));
    	  // usleep(20*1000);
    	  //alt_putstr("FPGA_PB2 released\r\n");

      } else { // must be PB[3] (S4), toggle FPGA_LED1 Red
#ifdef debug
    	 alt_putstr("FPGA_PB3 pressed\r\n");
#endif
   	  if (exp_time_index != 0) {
   		exp_time_index--;
   		// set exposure
   		poke(MIRA220_REG_EXPOSURE,   exp_time[exp_time_index] & 0x0FF, 1);
   		poke(MIRA220_REG_EXPOSURE+1, exp_time[exp_time_index] >> 8, 1);
   	  }
      }
   }
   // Clear both interrupt bits
   IOWR_ALTERA_AVALON_PIO_EDGE_CAP(FPGA_PB_BASE, 0x03);
}



