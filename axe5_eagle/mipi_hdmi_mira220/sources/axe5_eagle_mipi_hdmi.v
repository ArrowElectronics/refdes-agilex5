module axe5_eagle_mipi_hdmi(
   // System signals
   input         FPGA_Clock,
   input         FPGA_RST_n,
	
	// FPGA Push-buttons
	input  [3:2]  FPGA_PB,
	
	// Debug UART (19.2 kbaud)
	input         DBG_RXD,
	output        DBG_TXD,
	
	// LPDDR4B signals
   output        LPDDR4A_CK_P, LPDDR4A_CK_N, LPDDR4A_RST, 
	input         LPDDR4A_REFCK_p,
   output [5:0]  LPDDR4A_CA,
   output		  LPDDR4A_CKE, LPDDR4A_CS_N,
   inout  [31:0] LPDDR4A_DQ,
   inout         LPDDR4A_DQSA1_p, LPDDR4A_DQSA1_n, LPDDR4A_DQSA0_p, LPDDR4A_DQSA0_n,
   inout         LPDDR4A_DQSB1_p, LPDDR4A_DQSB1_n, LPDDR4A_DQSB0_p, LPDDR4A_DQSB0_n,
   inout         LPDDR4A_DMB1, LPDDR4A_DMB0, LPDDR4A_DMA1, LPDDR4A_DMA0,
   input         LPDDR4A_OCT_RZQIN,
	
	// MUX I2C (for HDMI)
   inout         MUX_I2C_SDA,
   inout         MUX_I2C_SCL,
	// HDMI Output signals
   output        HDMI_VS, HDMI_HS, HDMI_CLK, HDMI_DE, HDMI_CT_HPD, HDMI_CEC_CLK,
   output [23:0] HDMI_D,
	
	// MIPI on C_HSX (J21) - CRUVI_VADJ=1.3V
	inout         MIPI_SDA,
	inout         MIPI_SCL,
	output        MIPI_ENABLE, 
	input         MIPI_RZQ, 
	input         MIPI_REFCLK_p,
	input  [1:0]  MIPI_LINK_p, MIPI_LINK_n,
	input         MIPI_LINK_CLK_p, MIPI_LINK_CLK_n,
	output        LED0R, LED0G, LED0B,
	output        LED1R
);

	wire [2:0]   pio_led;
	wire         pio_mipi;

	wire        int_hdmi_clk;
	wire [15:0] int_hdmi16;
	wire [23:0] int_hdmi24;
	wire        int_hdmi_de;
	wire        int_hdmi_vsync;
	wire        int_hdmi_hsync;


	// I2C for HDMI (MUX_I2C)
   wire     mux_i2c_scl_i_clk, mux_i2c_scl_oe_clk , mux_i2c_sda_i, mux_i2c_sda_oe;
   assign   MUX_I2C_SCL    = mux_i2c_scl_oe_clk ? 1'b0 : 1'bz;
   assign   mux_i2c_scl_i_clk = MUX_I2C_SCL;
   assign   MUX_I2C_SDA    = mux_i2c_sda_oe ? 1'b0 : 1'bz;
   assign   mux_i2c_sda_i     = MUX_I2C_SDA;

	// I2C pins for CRUVI_HSX
   wire     camera_i2c_sda_in, camera_i2c_scl_in , camera_i2c_sda_oe, camera_i2c_scl_oe;
   assign   MIPI_SCL    = camera_i2c_scl_oe ? 1'b0 : 1'bz;
   assign   camera_i2c_scl_in = MIPI_SCL;
   assign   MIPI_SDA    = camera_i2c_sda_oe ? 1'b0 : 1'bz;
   assign   camera_i2c_sda_in = MIPI_SDA;

	assign LED0R = pio_led[2];
	assign LED0G = pio_led[1];
	assign LED0B = pio_led[0];

	assign MIPI_ENABLE   = pio_mipi;
	
	assign  HDMI_D       = int_hdmi24;

	assign  HDMI_DE      = int_hdmi_de;
	assign  HDMI_VS      = int_hdmi_vsync;
	assign  HDMI_HS      = int_hdmi_hsync;
   assign HDMI_CT_HPD   = 1'b1;
   assign HDMI_CEC_CLK  = 1'b0;

	ddio_out hdmi_clk_out (
		.ck       (int_hdmi_clk),
		.datain_h (1'b0),
		.datain_l (1'b1),
		.dataout  (HDMI_CLK)
	);
	

	
niosv_system niosv_subsystem (
        .mipi_i2c_sda_in           (camera_i2c_sda_in), 
        .mipi_i2c_scl_in           (camera_i2c_scl_in),
        .mipi_i2c_sda_oe           (camera_i2c_sda_oe), 
        .mipi_i2c_scl_oe           (camera_i2c_scl_oe),
        .fpga_clk25m_clk           (FPGA_Clock),  
        .fpga_reset_n_reset_n      (FPGA_RST_n),
        .mux_i2c_sda_in            (mux_i2c_sda_i),
        .mux_i2c_scl_in            (mux_i2c_scl_i_clk),
        .mux_i2c_sda_oe            (mux_i2c_sda_oe),
        .mux_i2c_scl_oe            (mux_i2c_scl_oe_clk),
		  .pio_led_export            (pio_led),
        .pio_mipi_export           (pio_mipi), 
		  .pio_pb_export             (FPGA_PB),
        .dbg_uart_rxd              (DBG_RXD),
        .dbg_uart_txd              (DBG_TXD),
        .lpddr4_refclk_clk         (LPDDR4A_REFCK_p),
        .lpddr4_mem_ck_mem_ck_t    (LPDDR4A_CK_P), 
        .lpddr4_mem_ck_mem_ck_c    (LPDDR4A_CK_N),
        .lpddr4_mem_mem_cke        (LPDDR4A_CKE), 
        .lpddr4_mem_reset_n_mem_reset_n    (LPDDR4A_RST),
        .lpddr4_mem_mem_cs         (LPDDR4A_CS_N), 
        .lpddr4_mem_mem_ca         (LPDDR4A_CA), 
        .lpddr4_mem_mem_dq         (LPDDR4A_DQ), 
        .lpddr4_mem_mem_dqs_t      ({LPDDR4A_DQSB1_p, LPDDR4A_DQSB0_p, LPDDR4A_DQSA1_p, LPDDR4A_DQSA0_p}), 
        .lpddr4_mem_mem_dqs_c      ({LPDDR4A_DQSB1_n, LPDDR4A_DQSB0_n, LPDDR4A_DQSA1_n, LPDDR4A_DQSA0_n}),
        .lpddr4_mem_mem_dmi        ({LPDDR4A_DMB1,LPDDR4A_DMB0,LPDDR4A_DMA1,LPDDR4A_DMA0}), 
        .lpddr4_oct_oct_rzqin      (LPDDR4A_OCT_RZQIN),
        .mipi_dphy_rzq_rzq         (MIPI_RZQ),
        .mipi_dphy_refclk_clk      (MIPI_REFCLK_p), 
        .mipi_dphy_io_dphy_link_dp (MIPI_LINK_p),
        .mipi_dphy_io_dphy_link_dn (MIPI_LINK_n), 
        .mipi_dphy_io_dphy_link_cp (MIPI_LINK_CLK_p),
        .mipi_dphy_io_dphy_link_cn (MIPI_LINK_CLK_n),
        .hdmi_vid_clock_clk        (int_hdmi_clk),  
        .hdmi_vid_out_data         (int_hdmi24), 
        .hdmi_vid_out_active       (int_hdmi_de),
        .hdmi_vid_out_v_sync       (int_hdmi_vsync), 
        .hdmi_vid_out_h_sync       (int_hdmi_hsync), 
        .hdmi_vid_out_valid        (), 
        .hdmi_vid_out_f            () 
	);


endmodule
