#
# SPDX-FileCopyrightText: Copyright (C) 2024 Arrow Electronics, Inc. 
# SPDX-License-Identifier: MIT-0 
#

set_location_assignment PIN_AC68  -to REFCLK_3B0 -comment IOBANK_3B_B
set_instance_assignment -name IO_STANDARD "1.3V True Differential Signaling" -to REFCLK_3B0
set_instance_assignment -name INPUT_TERMINATION DIFFERENTIAL -to REFCLK_3B0

# Bank HVIO_6D
set_location_assignment PIN_A23  -to FPGA_25M_CLK
set_instance_assignment -name IO_STANDARD "3.3-V LVCMOS" -to FPGA_25M_CLK

# Bank HVIO_5A
set_location_assignment PIN_CK134  -to FPGA_RST_n
set_instance_assignment -name IO_STANDARD "3.3-V LVCMOS" -to FPGA_RST_n

# Bank HVIO_6D (3.3V)
set_location_assignment PIN_B30  -to FPGA_PB[0]
set_instance_assignment -name IO_STANDARD "3.3-V LVCMOS" -to FPGA_PB[0]
set_location_assignment PIN_A30  -to FPGA_PB[1]
set_instance_assignment -name IO_STANDARD "3.3-V LVCMOS" -to FPGA_PB[1]

# Bank HVIO_5A

set_location_assignment PIN_CK125  -to LED0R
set_instance_assignment -name IO_STANDARD "3.3-V LVCMOS" -to LED0R
set_location_assignment PIN_CL125  -to LED0G
set_instance_assignment -name IO_STANDARD "3.3-V LVCMOS" -to LED0G
set_location_assignment PIN_BR118  -to LED0B
set_instance_assignment -name IO_STANDARD "3.3-V LVCMOS" -to LED0B

set_location_assignment PIN_CF118  -to LED1R
set_instance_assignment -name IO_STANDARD "3.3-V LVCMOS" -to LED1R
set_location_assignment PIN_BW118  -to LED1G
set_instance_assignment -name IO_STANDARD "3.3-V LVCMOS" -to LED1G
set_location_assignment PIN_CA118  -to LED1B
set_instance_assignment -name IO_STANDARD "3.3-V LVCMOS" -to LED1B


