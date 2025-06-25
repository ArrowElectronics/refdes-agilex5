set CRUVI_HX 1
set CRUVI_HY 0

set_location_assignment PIN_CK134  -to FPGA_RST_n
set_instance_assignment -name IO_STANDARD "3.3-V LVCMOS" -to FPGA_RST_n

set_location_assignment PIN_A23  -to FPGA_Clock
set_instance_assignment -name IO_STANDARD "3.3-V LVCMOS" -to FPGA_Clock

# Necessary in 24.2 and greater
set_location_assignment PIN_BR102   -to OSC_CLK_1
set_instance_assignment -name IO_STANDARD "1.8 V" -to OSC_CLK_1

set_location_assignment PIN_CK125  -to LED0R
set_instance_assignment -name IO_STANDARD "3.3-V LVCMOS" -to LED0R
set_location_assignment PIN_CL125  -to LED0G
set_instance_assignment -name IO_STANDARD "3.3-V LVCMOS" -to LED0G
set_location_assignment PIN_BR118  -to LED0B
set_instance_assignment -name IO_STANDARD "3.3-V LVCMOS" -to LED0B

set_location_assignment PIN_CF118  -to LED1R
set_instance_assignment -name IO_STANDARD "3.3-V LVCMOS" -to LED1R


set_location_assignment PIN_AK107  -to LPDDR4A_CK_P -comment IOBANK_3A_B
set_location_assignment PIN_AK104  -to LPDDR4A_CK_N -comment IOBANK_3A_B
set_location_assignment PIN_AG111  -to LPDDR4A_RST -comment IOBANK_3A_B
#set_instance_assignment -name IO_STANDARD "1.1-V LVSTL" -to LPDDR4A_RST
set_location_assignment PIN_M105  -to LPDDR4A_REFCK_p -comment IOBANK_3A_B
set_instance_assignment -name IO_STANDARD "1.1V True Differential Signaling" -to LPDDR4A_REFCK_p
set_instance_assignment -name INPUT_TERMINATION DIFFERENTIAL -to LPDDR4A_REFCK_p
set_location_assignment PIN_T105  -to LPDDR4A_CS_N -comment IOBANK_3A_B
#set_instance_assignment -name IO_STANDARD "1.1-V LVSTL" -to LPDDR4A_CS_N
set_location_assignment PIN_V108  -to LPDDR4A_CKE -comment IOBANK_3A_B
#set_instance_assignment -name IO_STANDARD "1.1-V LVSTL" -to LPDDR4A_CKE
set_location_assignment PIN_T114  -to LPDDR4A_CA[0] -comment IOBANK_3A_B
#set_instance_assignment -name IO_STANDARD "1.1-V LVSTL" -to LPDDR4A_CA[0]
set_location_assignment PIN_P114  -to LPDDR4A_CA[1] -comment IOBANK_3A_B
#set_instance_assignment -name IO_STANDARD "1.1-V LVSTL" -to LPDDR4A_CA[1]
set_location_assignment PIN_V117  -to LPDDR4A_CA[2] -comment IOBANK_3A_B
#set_instance_assignment -name IO_STANDARD "1.1-V LVSTL" -to LPDDR4A_CA[2]
set_location_assignment PIN_T117  -to LPDDR4A_CA[3] -comment IOBANK_3A_B
#set_instance_assignment -name IO_STANDARD "1.1-V LVSTL" -to LPDDR4A_CA[3]
set_location_assignment PIN_M114  -to LPDDR4A_CA[4] -comment IOBANK_3A_B
#set_instance_assignment -name IO_STANDARD "1.1-V LVSTL" -to LPDDR4A_CA[4]
set_location_assignment PIN_K114  -to LPDDR4A_CA[5] -comment IOBANK_3A_B
#set_instance_assignment -name IO_STANDARD "1.1-V LVSTL" -to LPDDR4A_CA[5]
set_location_assignment PIN_B128  -to LPDDR4A_DQ[0] -comment IOBANK_3A_B
#set_instance_assignment -name IO_STANDARD "1.1-V LVSTL" -to LPDDR4A_DQ[0]
set_location_assignment PIN_A128  -to LPDDR4A_DQ[1] -comment IOBANK_3A_B
#set_instance_assignment -name IO_STANDARD "1.1-V LVSTL" -to LPDDR4A_DQ[1]
set_location_assignment PIN_B130  -to LPDDR4A_DQ[2] -comment IOBANK_3A_B
#set_instance_assignment -name IO_STANDARD "1.1-V LVSTL" -to LPDDR4A_DQ[2]
set_location_assignment PIN_A130  -to LPDDR4A_DQ[3] -comment IOBANK_3A_B
#set_instance_assignment -name IO_STANDARD "1.1-V LVSTL" -to LPDDR4A_DQ[3]
set_location_assignment PIN_B116  -to LPDDR4A_DQ[4] -comment IOBANK_3A_B
#set_instance_assignment -name IO_STANDARD "1.1-V LVSTL" -to LPDDR4A_DQ[4]
set_location_assignment PIN_A116  -to LPDDR4A_DQ[5] -comment IOBANK_3A_B
#set_instance_assignment -name IO_STANDARD "1.1-V LVSTL" -to LPDDR4A_DQ[5]
set_location_assignment PIN_B113  -to LPDDR4A_DQ[6] -comment IOBANK_3A_B
#set_instance_assignment -name IO_STANDARD "1.1-V LVSTL" -to LPDDR4A_DQ[6]
set_location_assignment PIN_A113  -to LPDDR4A_DQ[7] -comment IOBANK_3A_B
#set_instance_assignment -name IO_STANDARD "1.1-V LVSTL" -to LPDDR4A_DQ[7]
set_location_assignment PIN_F117  -to LPDDR4A_DQ[8] -comment IOBANK_3A_B
#set_instance_assignment -name IO_STANDARD "1.1-V LVSTL" -to LPDDR4A_DQ[8]
set_location_assignment PIN_H117  -to LPDDR4A_DQ[9] -comment IOBANK_3A_B
#set_instance_assignment -name IO_STANDARD "1.1-V LVSTL" -to LPDDR4A_DQ[9]
set_location_assignment PIN_K117  -to LPDDR4A_DQ[10] -comment IOBANK_3A_B
#set_instance_assignment -name IO_STANDARD "1.1-V LVSTL" -to LPDDR4A_DQ[10]
set_location_assignment PIN_M117  -to LPDDR4A_DQ[11] -comment IOBANK_3A_B
#set_instance_assignment -name IO_STANDARD "1.1-V LVSTL" -to LPDDR4A_DQ[11]
set_location_assignment PIN_H108  -to LPDDR4A_DQ[12] -comment IOBANK_3A_B
#set_instance_assignment -name IO_STANDARD "1.1-V LVSTL" -to  LPDDR4A_DQ[12]
set_location_assignment PIN_F108  -to LPDDR4A_DQ[13] -comment IOBANK_3A_B
#set_instance_assignment -name IO_STANDARD "1.1-V LVSTL" -to  LPDDR4A_DQ[13]
set_location_assignment PIN_M108  -to LPDDR4A_DQ[14] -comment IOBANK_3A_B
#set_instance_assignment -name IO_STANDARD "1.1-V LVSTL" -to  LPDDR4A_DQ[14]
set_location_assignment PIN_K108  -to LPDDR4A_DQ[15] -comment IOBANK_3A_B
#set_instance_assignment -name IO_STANDARD "1.1-V LVSTL" -to LPDDR4A_DQ[15]
set_location_assignment PIN_H98   -to LPDDR4A_DQ[16] -comment IOBANK_3A_T
#set_instance_assignment -name IO_STANDARD "1.1-V LVSTL" -to LPDDR4A_DQ[16]
set_location_assignment PIN_F98   -to LPDDR4A_DQ[17] -comment IOBANK_3A_T
#set_instance_assignment -name IO_STANDARD "1.1-V LVSTL" -to LPDDR4A_DQ[17]
set_location_assignment PIN_M98   -to LPDDR4A_DQ[18] -comment IOBANK_3A_T
#set_instance_assignment -name IO_STANDARD "1.1-V LVSTL" -to LPDDR4A_DQ[18]
set_location_assignment PIN_K98   -to LPDDR4A_DQ[19] -comment IOBANK_3A_T
#set_instance_assignment -name IO_STANDARD "1.1-V LVSTL" -to LPDDR4A_DQ[19]
set_location_assignment PIN_K87   -to LPDDR4A_DQ[20] -comment IOBANK_3A_T
#set_instance_assignment -name IO_STANDARD "1.1-V LVSTL" -to LPDDR4A_DQ[20]
set_location_assignment PIN_M87   -to LPDDR4A_DQ[21] -comment IOBANK_3A_T
#set_instance_assignment -name IO_STANDARD "1.1-V LVSTL" -to LPDDR4A_DQ[21]
set_location_assignment PIN_F84   -to LPDDR4A_DQ[22] -comment IOBANK_3A_T
#set_instance_assignment -name IO_STANDARD "1.1-V LVSTL" -to LPDDR4A_DQ[22]
set_location_assignment PIN_D84   -to LPDDR4A_DQ[23] -comment IOBANK_3A_T
#set_instance_assignment -name IO_STANDARD "1.1-V LVSTL" -to LPDDR4A_DQ[23]
set_location_assignment PIN_A106   -to LPDDR4A_DQ[24] -comment IOBANK_3A_T
#set_instance_assignment -name IO_STANDARD "1.1-V LVSTL" -to LPDDR4A_DQ[24]
set_location_assignment PIN_B103   -to LPDDR4A_DQ[25] -comment IOBANK_3A_T
#set_instance_assignment -name IO_STANDARD "1.1-V LVSTL" -to LPDDR4A_DQ[25]
set_location_assignment PIN_B106   -to LPDDR4A_DQ[26] -comment IOBANK_3A_T
#set_instance_assignment -name IO_STANDARD "1.1-V LVSTL" -to LPDDR4A_DQ[26]
set_location_assignment PIN_A110   -to LPDDR4A_DQ[27] -comment IOBANK_3A_T
#set_instance_assignment -name IO_STANDARD "1.1-V LVSTL" -to LPDDR4A_DQ[27]
set_location_assignment PIN_B91   -to LPDDR4A_DQ[28] -comment IOBANK_3A_T
#set_instance_assignment -name IO_STANDARD "1.1-V LVSTL" -to LPDDR4A_DQ[28]
set_location_assignment PIN_A94   -to LPDDR4A_DQ[29] -comment IOBANK_3A_T
#set_instance_assignment -name IO_STANDARD "1.1-V LVSTL" -to LPDDR4A_DQ[29]
set_location_assignment PIN_B88   -to LPDDR4A_DQ[30] -comment IOBANK_3A_T
#set_instance_assignment -name IO_STANDARD "1.1-V LVSTL" -to LPDDR4A_DQ[30]
set_location_assignment PIN_A91   -to LPDDR4A_DQ[31] -comment IOBANK_3A_T
#set_instance_assignment -name IO_STANDARD "1.1-V LVSTL" -to LPDDR4A_DQ[31]
set_location_assignment PIN_F114   -to LPDDR4A_DQSA1_p -comment IOBANK_3A_B
set_location_assignment PIN_D114   -to LPDDR4A_DQSA1_n -comment IOBANK_3A_B
#set_instance_assignment -name IO_STANDARD "Differential 1.1-V LVSTL" -to LPDDR4A_DQSA1_p
#set_instance_assignment -name IO_STANDARD "Differential 1.1-V LVSTL" -to LPDDR4A_DQSA1_n
set_location_assignment PIN_B122   -to LPDDR4A_DQSA0_p -comment IOBANK_3A_B
set_location_assignment PIN_A125   -to LPDDR4A_DQSA0_n -comment IOBANK_3A_B
#set_instance_assignment -name IO_STANDARD "Differential 1.1-V LVSTL" -to LPDDR4A_DQSA0_p
#set_instance_assignment -name IO_STANDARD "Differential 1.1-V LVSTL" -to LPDDR4A_DQSA0_n
set_location_assignment PIN_A101   -to LPDDR4A_DQSB1_p -comment IOBANK_3A_T
set_location_assignment PIN_B101   -to LPDDR4A_DQSB1_n -comment IOBANK_3A_T
#set_instance_assignment -name IO_STANDARD "Differential 1.1-V LVSTL" -to LPDDR4A_DQSB1_p
#set_instance_assignment -name IO_STANDARD "Differential 1.1-V LVSTL" -to LPDDR4A_DQSB1_n
set_location_assignment PIN_F95   -to LPDDR4A_DQSB0_p -comment IOBANK_3A_T
set_location_assignment PIN_D95   -to LPDDR4A_DQSB0_n -comment IOBANK_3A_T
#set_instance_assignment -name IO_STANDARD "Differential 1.1-V LVSTL" -to LPDDR4A_DQSB0_p
#set_instance_assignment -name IO_STANDARD "Differential 1.1-V LVSTL" -to LPDDR4A_DQSB0_n
set_location_assignment PIN_F105   -to LPDDR4A_DMA1 -comment IOBANK_3A_B
#set_instance_assignment -name IO_STANDARD "1.1-V LVSTL" -to LPDDR4A_DMA1
set_location_assignment PIN_B119   -to LPDDR4A_DMA0 -comment IOBANK_3A_B
#set_instance_assignment -name IO_STANDARD "1.1-V LVSTL" -to LPDDR4A_DMA0
set_location_assignment PIN_B97   -to LPDDR4A_DMB1 -comment IOBANK_3A_T
#set_instance_assignment -name IO_STANDARD "1.1-V LVSTL" -to LPDDR4A_DMB1
set_location_assignment PIN_H87   -to LPDDR4A_DMB0 -comment IOBANK_3A_T
#set_instance_assignment -name IO_STANDARD "1.1-V LVSTL" -to LPDDR4A_DMB0
set_location_assignment PIN_AK111   -to LPDDR4A_OCT_RZQIN -comment IOBANK_3A_B
#set_instance_assignment -name IO_STANDARD "1.1-V LVSTL" -to LPDDR4A_OCT_RZQIN

if { $CRUVI_HX == 1} {
set_location_assignment PIN_V58  -to MIPI_LINK_p[1]
set_location_assignment PIN_T58  -to MIPI_LINK_n[1]
set_instance_assignment -name IO_STANDARD "DPHY" -to MIPI_LINK_p[1]
set_instance_assignment -name IO_STANDARD "DPHY" -to MIPI_LINK_n[1]

set_location_assignment PIN_P55  -to MIPI_LINK_p[0]
set_location_assignment PIN_T55  -to MIPI_LINK_n[0]
set_instance_assignment -name IO_STANDARD "DPHY" -to MIPI_LINK_p[0]
set_instance_assignment -name IO_STANDARD "DPHY" -to MIPI_LINK_n[0]

set_location_assignment PIN_K55  -to MIPI_LINK_CLK_p
set_location_assignment PIN_M55  -to MIPI_LINK_CLK_n
set_instance_assignment -name IO_STANDARD "DPHY" -to MIPI_LINK_CLK_p
set_instance_assignment -name IO_STANDARD "DPHY" -to MIPI_LINK_CLK_n

set_location_assignment PIN_BU109  -to MIPI_SDA
set_instance_assignment -name IO_STANDARD "3.3-V LVCMOS" -to MIPI_SDA
#set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to MIPI_SDA
set_location_assignment PIN_BR109  -to MIPI_SCL
set_instance_assignment -name IO_STANDARD "3.3-V LVCMOS" -to MIPI_SCL
#set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to MIPI_SCL
set_location_assignment PIN_BR112  -to MIPI_ENABLE
set_instance_assignment -name IO_STANDARD "3.3-V LVCMOS" -to MIPI_ENABLE
set_location_assignment PIN_AC79  -to MIPI_RZQ
set_instance_assignment -name IO_STANDARD "1.2-V" -to MIPI_RZQ
set_location_assignment PIN_AC68  -to MIPI_REFCLK_p
set_instance_assignment -name IO_STANDARD "1.2V True Differential Signaling" -to MIPI_REFCLK_p
set_instance_assignment -name INPUT_TERMINATION DIFFERENTIAL -to MIPI_REFCLK_p
}
if { $CRUVI_HY == 1} {
set_location_assignment PIN_F77  -to MIPI_LINK_p[1]
set_location_assignment PIN_H77  -to MIPI_LINK_n[1]
set_instance_assignment -name IO_STANDARD "DPHY" -to MIPI_LINK_p[1]
set_instance_assignment -name IO_STANDARD "DPHY" -to MIPI_LINK_n[1]

set_location_assignment PIN_K77  -to MIPI_LINK_p[0]
set_location_assignment PIN_M77  -to MIPI_LINK_n[0]
set_instance_assignment -name IO_STANDARD "DPHY" -to MIPI_LINK_p[0]
set_instance_assignment -name IO_STANDARD "DPHY" -to MIPI_LINK_n[0]

set_location_assignment PIN_D74  -to MIPI_LINK_CLK_p
set_location_assignment PIN_F74  -to MIPI_LINK_CLK_n
set_instance_assignment -name IO_STANDARD "DPHY" -to MIPI_LINK_CLK_p
set_instance_assignment -name IO_STANDARD "DPHY" -to MIPI_LINK_CLK_n

set_location_assignment PIN_CD135  -to MIPI_SDA
set_instance_assignment -name IO_STANDARD "3.3-V LVCMOS" -to MIPI_SDA
#set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to MIPI_SDA
set_location_assignment PIN_CD134  -to MIPI_SCL
set_instance_assignment -name IO_STANDARD "3.3-V LVCMOS" -to MIPI_SCL
#set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to MIPI_SCL
set_location_assignment PIN_CG134  -to MIPI_ENABLE
set_instance_assignment -name IO_STANDARD "3.3-V LVCMOS" -to MIPI_ENABLE
set_location_assignment PIN_AC79  -to MIPI_RZQ
set_instance_assignment -name IO_STANDARD "1.2-V" -to MIPI_RZQ
set_location_assignment PIN_AC68  -to MIPI_REFCLK_p
set_instance_assignment -name IO_STANDARD "1.2V True Differential Signaling" -to MIPI_REFCLK_p
set_instance_assignment -name INPUT_TERMINATION DIFFERENTIAL -to MIPI_REFCLK_p
}

set_location_assignment PIN_BH19  -to HDMI_VS
set_instance_assignment -name IO_STANDARD "1.8-V LVCMOS" -to HDMI_VS
set_location_assignment PIN_CF12  -to HDMI_HS
set_instance_assignment -name IO_STANDARD "1.8-V LVCMOS" -to HDMI_HS
set_location_assignment PIN_BK31  -to HDMI_CLK
set_instance_assignment -name IO_STANDARD "1.8-V LVCMOS" -to HDMI_CLK
set_location_assignment PIN_BK19  -to HDMI_DE
set_instance_assignment -name IO_STANDARD "1.8-V LVCMOS" -to HDMI_DE
set_location_assignment PIN_BW19  -to HDMI_CT_HPD
set_instance_assignment -name IO_STANDARD "1.8-V LVCMOS" -to HDMI_CT_HPD
set_location_assignment PIN_BF25  -to HDMI_CEC_CLK
set_instance_assignment -name IO_STANDARD "1.8-V LVCMOS" -to HDMI_CEC_CLK
set_location_assignment PIN_BF32  -to HDMI_D[0]
set_instance_assignment -name IO_STANDARD "1.8-V LVCMOS" -to HDMI_D[0]
set_location_assignment PIN_CH12  -to HDMI_D[1]
set_instance_assignment -name IO_STANDARD "1.8-V LVCMOS" -to HDMI_D[1]
set_location_assignment PIN_BM22  -to HDMI_D[2]
set_instance_assignment -name IO_STANDARD "1.8-V LVCMOS" -to HDMI_D[2]
set_location_assignment PIN_BF21  -to HDMI_D[3]
set_instance_assignment -name IO_STANDARD "1.8-V LVCMOS" -to HDMI_D[3]
set_location_assignment PIN_BE21  -to HDMI_D[4]
set_instance_assignment -name IO_STANDARD "1.8-V LVCMOS" -to HDMI_D[4]
set_location_assignment PIN_BP22  -to HDMI_D[5]
set_instance_assignment -name IO_STANDARD "1.8-V LVCMOS" -to HDMI_D[5]
set_location_assignment PIN_BR22  -to HDMI_D[6]
set_instance_assignment -name IO_STANDARD "1.8-V LVCMOS" -to HDMI_D[6]
set_location_assignment PIN_BE25  -to HDMI_D[7]
set_instance_assignment -name IO_STANDARD "1.8-V LVCMOS" -to HDMI_D[7]
set_location_assignment PIN_BU22  -to HDMI_D[8]
set_instance_assignment -name IO_STANDARD "1.8-V LVCMOS" -to HDMI_D[8]
set_location_assignment PIN_BW28  -to HDMI_D[9]
set_instance_assignment -name IO_STANDARD "1.8-V LVCMOS" -to HDMI_D[9]
set_location_assignment PIN_BU28  -to HDMI_D[10]
set_instance_assignment -name IO_STANDARD "1.8-V LVCMOS" -to HDMI_D[10]
set_location_assignment PIN_BM31  -to HDMI_D[11]
set_instance_assignment -name IO_STANDARD "1.8-V LVCMOS" -to HDMI_D[11]
set_location_assignment PIN_BR28  -to HDMI_D[12]
set_instance_assignment -name IO_STANDARD "1.8-V LVCMOS" -to HDMI_D[12]
set_location_assignment PIN_BM28  -to HDMI_D[13]
set_instance_assignment -name IO_STANDARD "1.8-V LVCMOS" -to HDMI_D[13]
set_location_assignment PIN_BK28  -to HDMI_D[14]
set_instance_assignment -name IO_STANDARD "1.8-V LVCMOS" -to HDMI_D[14]
set_location_assignment PIN_BH28  -to HDMI_D[15]
set_instance_assignment -name IO_STANDARD "1.8-V LVCMOS" -to HDMI_D[15]
set_location_assignment PIN_BF36  -to HDMI_D[16]
set_instance_assignment -name IO_STANDARD "1.8-V LVCMOS" -to HDMI_D[16]
set_location_assignment PIN_BE43  -to HDMI_D[17]
set_instance_assignment -name IO_STANDARD "1.8-V LVCMOS" -to HDMI_D[17]
set_location_assignment PIN_BU31   -to HDMI_D[18]
set_instance_assignment -name IO_STANDARD "1.8-V LVCMOS" -to HDMI_D[18]
set_location_assignment PIN_BP31  -to HDMI_D[19]
set_instance_assignment -name IO_STANDARD "1.8-V LVCMOS" -to HDMI_D[19]
set_location_assignment PIN_BR31  -to HDMI_D[20]
set_instance_assignment -name IO_STANDARD "1.8-V LVCMOS" -to HDMI_D[20]
set_location_assignment PIN_BF29  -to HDMI_D[21]
set_instance_assignment -name IO_STANDARD "1.8-V LVCMOS" -to HDMI_D[21]
set_location_assignment PIN_BF40  -to HDMI_D[22]
set_instance_assignment -name IO_STANDARD "1.8-V LVCMOS" -to HDMI_D[22]
set_location_assignment PIN_BE29  -to HDMI_D[23]
set_instance_assignment -name IO_STANDARD "1.8-V LVCMOS" -to HDMI_D[23]

set_location_assignment PIN_F4  -to MUX_I2C_SDA
set_instance_assignment -name IO_STANDARD "1.8-V LVCMOS" -to MUX_I2C_SDA
set_location_assignment PIN_D4  -to MUX_I2C_SCL
set_instance_assignment -name IO_STANDARD "1.8-V LVCMOS" -to MUX_I2C_SCL

set_location_assignment PIN_BK22  -to DBG_TXD
set_instance_assignment -name IO_STANDARD "1.8-V LVCMOS" -to DBG_TXD
set_location_assignment PIN_CH4  -to DBG_RXD
set_instance_assignment -name IO_STANDARD "1.8-V LVCMOS" -to DBG_RXD

set_location_assignment PIN_B30  -to FPGA_PB[2]
set_instance_assignment -name IO_STANDARD "3.3-V LVCMOS" -to FPGA_PB[2]
set_location_assignment PIN_A30  -to FPGA_PB[3]
set_instance_assignment -name IO_STANDARD "3.3-V LVCMOS" -to FPGA_PB[3]
