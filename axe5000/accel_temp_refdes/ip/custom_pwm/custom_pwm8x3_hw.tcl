# TCL File Generated by Component Editor 24.3.1
# Tue Jan 28 11:41:27 CST 2025
# DO NOT MODIFY


# 
# custom_pwm8x3_hw "custom_pwm" v1.0
#  2025.01.28.11:41:27
# 
# 

# 
# request TCL package from ACDS 24.3.1
# 
package require -exact qsys 24.3.1


# 
# module custom_pwm8x3_hw
# 
set_module_property DESCRIPTION ""
set_module_property NAME custom_pwm8x3_hw
set_module_property VERSION 1.0
set_module_property INTERNAL false
set_module_property OPAQUE_ADDRESS_MAP true
set_module_property BSP_CPU false
set_module_property AUTHOR ""
set_module_property DISPLAY_NAME custom_pwm
set_module_property INSTANTIATE_IN_SYSTEM_MODULE true
set_module_property EDITABLE true
set_module_property REPORT_TO_TALKBACK false
set_module_property ALLOW_GREYBOX_GENERATION false
set_module_property REPORT_HIERARCHY false
set_module_property LOAD_ELABORATION_LIMIT 0
set_module_property PRE_COMP_MODULE_ENABLED false


# 
# file sets
# 
add_fileset custom_pwm8x3 QUARTUS_SYNTH "" ""
set_fileset_property custom_pwm8x3 TOP_LEVEL custom_pwm8x3
set_fileset_property custom_pwm8x3 ENABLE_RELATIVE_INCLUDE_PATHS false
set_fileset_property custom_pwm8x3 ENABLE_FILE_OVERWRITE_MODE false
add_fileset_file cust_PwmCSR.vhd VHDL PATH cust_PwmCSR.vhd
add_fileset_file cust_PwmDataMux.vhd VHDL PATH cust_PwmDataMux.vhd
add_fileset_file cust_PwmRegisters.vhd VHDL PATH cust_PwmRegisters.vhd
add_fileset_file cust_pwm.vhd VHDL PATH cust_pwm.vhd TOP_LEVEL_FILE

add_fileset custom_pwm8x3 SIM_VERILOG "" ""
set_fileset_property custom_pwm8x3 TOP_LEVEL custom_pwm8x3
set_fileset_property custom_pwm8x3 ENABLE_RELATIVE_INCLUDE_PATHS false
set_fileset_property custom_pwm8x3 ENABLE_FILE_OVERWRITE_MODE false
add_fileset_file cust_PwmCSR.vhd VHDL PATH cust_PwmCSR.vhd
add_fileset_file cust_PwmDataMux.vhd VHDL PATH cust_PwmDataMux.vhd
add_fileset_file cust_PwmRegisters.vhd VHDL PATH cust_PwmRegisters.vhd
add_fileset_file cust_pwm.vhd VHDL PATH cust_pwm.vhd TOP_LEVEL_FILE

add_fileset custom_pwm8x3 SIM_VHDL "" ""
set_fileset_property custom_pwm8x3 TOP_LEVEL custom_pwm8x3
set_fileset_property custom_pwm8x3 ENABLE_RELATIVE_INCLUDE_PATHS false
set_fileset_property custom_pwm8x3 ENABLE_FILE_OVERWRITE_MODE false
add_fileset_file cust_PwmCSR.vhd VHDL PATH cust_PwmCSR.vhd
add_fileset_file cust_PwmDataMux.vhd VHDL PATH cust_PwmDataMux.vhd
add_fileset_file cust_PwmRegisters.vhd VHDL PATH cust_PwmRegisters.vhd
add_fileset_file cust_pwm.vhd VHDL PATH cust_pwm.vhd TOP_LEVEL_FILE


# 
# parameters
# 
add_parameter NUM_CHANNELS INTEGER 3
set_parameter_property NUM_CHANNELS DEFAULT_VALUE 3
set_parameter_property NUM_CHANNELS DISPLAY_NAME NUM_CHANNELS
set_parameter_property NUM_CHANNELS UNITS None
set_parameter_property NUM_CHANNELS ALLOWED_RANGES -2147483648:2147483647
set_parameter_property NUM_CHANNELS AFFECTS_GENERATION false
set_parameter_property NUM_CHANNELS HDL_PARAMETER true
set_parameter_property NUM_CHANNELS EXPORT true
add_parameter CHANNEL_WIDTH INTEGER 8
set_parameter_property CHANNEL_WIDTH DEFAULT_VALUE 8
set_parameter_property CHANNEL_WIDTH DISPLAY_NAME CHANNEL_WIDTH
set_parameter_property CHANNEL_WIDTH UNITS None
set_parameter_property CHANNEL_WIDTH ALLOWED_RANGES -2147483648:2147483647
set_parameter_property CHANNEL_WIDTH AFFECTS_GENERATION false
set_parameter_property CHANNEL_WIDTH HDL_PARAMETER true
set_parameter_property CHANNEL_WIDTH EXPORT true
add_parameter ADDR_WIDTH INTEGER 4
set_parameter_property ADDR_WIDTH DEFAULT_VALUE 4
set_parameter_property ADDR_WIDTH DISPLAY_NAME ADDR_WIDTH
set_parameter_property ADDR_WIDTH UNITS None
set_parameter_property ADDR_WIDTH ALLOWED_RANGES -2147483648:2147483647
set_parameter_property ADDR_WIDTH AFFECTS_GENERATION false
set_parameter_property ADDR_WIDTH HDL_PARAMETER true
set_parameter_property ADDR_WIDTH EXPORT true


# 
# display items
# 


# 
# connection point avalon_slave_0
# 
add_interface avalon_slave_0 avalon end
set_interface_property avalon_slave_0 addressGroup 0
set_interface_property avalon_slave_0 addressUnits WORDS
set_interface_property avalon_slave_0 associatedClock clock_sink
set_interface_property avalon_slave_0 associatedReset reset_sink
set_interface_property avalon_slave_0 bitsPerSymbol 8
set_interface_property avalon_slave_0 bridgedAddressOffset ""
set_interface_property avalon_slave_0 bridgesToMaster ""
set_interface_property avalon_slave_0 burstOnBurstBoundariesOnly false
set_interface_property avalon_slave_0 burstcountUnits WORDS
set_interface_property avalon_slave_0 explicitAddressSpan 0
set_interface_property avalon_slave_0 holdTime 0
set_interface_property avalon_slave_0 linewrapBursts false
set_interface_property avalon_slave_0 maximumPendingReadTransactions 0
set_interface_property avalon_slave_0 maximumPendingWriteTransactions 0
set_interface_property avalon_slave_0 minimumResponseLatency 1
set_interface_property avalon_slave_0 readLatency 0
set_interface_property avalon_slave_0 readWaitTime 1
set_interface_property avalon_slave_0 setupTime 0
set_interface_property avalon_slave_0 timingUnits Cycles
set_interface_property avalon_slave_0 transparentBridge false
set_interface_property avalon_slave_0 waitrequestAllowance 0
set_interface_property avalon_slave_0 writeWaitTime 0
set_interface_property avalon_slave_0 dfhFeatureGuid 0
set_interface_property avalon_slave_0 dfhGroupId 0
set_interface_property avalon_slave_0 dfhParameterId ""
set_interface_property avalon_slave_0 dfhParameterName ""
set_interface_property avalon_slave_0 dfhParameterVersion ""
set_interface_property avalon_slave_0 dfhParameterData ""
set_interface_property avalon_slave_0 dfhParameterDataLength ""
set_interface_property avalon_slave_0 dfhFeatureMajorVersion 0
set_interface_property avalon_slave_0 dfhFeatureMinorVersion 0
set_interface_property avalon_slave_0 dfhFeatureId 35
set_interface_property avalon_slave_0 dfhFeatureType 3
set_interface_property avalon_slave_0 ENABLED true
set_interface_property avalon_slave_0 EXPORT_OF ""
set_interface_property avalon_slave_0 PORT_NAME_MAP ""
set_interface_property avalon_slave_0 CMSIS_SVD_VARIABLES ""
set_interface_property avalon_slave_0 SVD_ADDRESS_GROUP ""
set_interface_property avalon_slave_0 IPXACT_REGISTER_MAP_VARIABLES ""
set_interface_property avalon_slave_0 SV_INTERFACE_TYPE ""
set_interface_property avalon_slave_0 SV_INTERFACE_MODPORT_TYPE ""

add_interface_port avalon_slave_0 Address address Input 4
add_interface_port avalon_slave_0 WriteEn write Input 1
add_interface_port avalon_slave_0 ReadEn read Input 1
add_interface_port avalon_slave_0 ChipSelect chipselect Input 1
add_interface_port avalon_slave_0 WriteData writedata Input 32
add_interface_port avalon_slave_0 ReadData readdata Output 32
add_interface_port avalon_slave_0 WaitRequest waitrequest Output 1
set_interface_assignment avalon_slave_0 embeddedsw.configuration.isFlash 0
set_interface_assignment avalon_slave_0 embeddedsw.configuration.isMemoryDevice 0
set_interface_assignment avalon_slave_0 embeddedsw.configuration.isNonVolatileStorage 0
set_interface_assignment avalon_slave_0 embeddedsw.configuration.isPrintableDevice 0


# 
# connection point conduit_end
# 
add_interface conduit_end conduit end
set_interface_property conduit_end associatedClock ""
set_interface_property conduit_end associatedReset ""
set_interface_property conduit_end ENABLED true
set_interface_property conduit_end EXPORT_OF ""
set_interface_property conduit_end PORT_NAME_MAP ""
set_interface_property conduit_end CMSIS_SVD_VARIABLES ""
set_interface_property conduit_end SVD_ADDRESS_GROUP ""
set_interface_property conduit_end IPXACT_REGISTER_MAP_VARIABLES ""
set_interface_property conduit_end SV_INTERFACE_TYPE ""
set_interface_property conduit_end SV_INTERFACE_MODPORT_TYPE ""

add_interface_port conduit_end PwmOut conduit Output 3


# 
# connection point clock_sink
# 
add_interface clock_sink clock end
set_interface_property clock_sink ENABLED true
set_interface_property clock_sink EXPORT_OF ""
set_interface_property clock_sink PORT_NAME_MAP ""
set_interface_property clock_sink CMSIS_SVD_VARIABLES ""
set_interface_property clock_sink SVD_ADDRESS_GROUP ""
set_interface_property clock_sink IPXACT_REGISTER_MAP_VARIABLES ""
set_interface_property clock_sink SV_INTERFACE_TYPE ""
set_interface_property clock_sink SV_INTERFACE_MODPORT_TYPE ""

add_interface_port clock_sink SysClk clk Input 1


# 
# connection point reset_sink
# 
add_interface reset_sink reset end
set_interface_property reset_sink associatedClock clock_sink
set_interface_property reset_sink synchronousEdges DEASSERT
set_interface_property reset_sink ENABLED true
set_interface_property reset_sink EXPORT_OF ""
set_interface_property reset_sink PORT_NAME_MAP ""
set_interface_property reset_sink CMSIS_SVD_VARIABLES ""
set_interface_property reset_sink SVD_ADDRESS_GROUP ""
set_interface_property reset_sink IPXACT_REGISTER_MAP_VARIABLES ""
set_interface_property reset_sink SV_INTERFACE_TYPE ""
set_interface_property reset_sink SV_INTERFACE_MODPORT_TYPE ""

add_interface_port reset_sink SysReset reset Input 1


# 
# connection point interrupt_sender
# 
add_interface interrupt_sender interrupt end
set_interface_property interrupt_sender associatedClock clock_sink
set_interface_property interrupt_sender bridgedReceiverOffset ""
set_interface_property interrupt_sender bridgesToReceiver ""
set_interface_property interrupt_sender ENABLED true
set_interface_property interrupt_sender EXPORT_OF ""
set_interface_property interrupt_sender PORT_NAME_MAP ""
set_interface_property interrupt_sender CMSIS_SVD_VARIABLES ""
set_interface_property interrupt_sender SVD_ADDRESS_GROUP ""
set_interface_property interrupt_sender IPXACT_REGISTER_MAP_VARIABLES ""
set_interface_property interrupt_sender SV_INTERFACE_TYPE ""
set_interface_property interrupt_sender SV_INTERFACE_MODPORT_TYPE ""

add_interface_port interrupt_sender interrupt irq Output 1

