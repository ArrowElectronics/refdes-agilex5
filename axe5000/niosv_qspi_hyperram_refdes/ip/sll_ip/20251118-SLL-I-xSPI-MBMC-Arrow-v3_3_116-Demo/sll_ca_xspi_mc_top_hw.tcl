# ************************************************************************
# *
# * SYNAPTIC LABORATORIES CONFIDENTIAL
# * ----------------------------------
# *
# *  (c) 2017 Synaptic Laboratories Limited
# *  All Rights Reserved.
# *
# * NOTICE:  All information contained herein is, and remains
# * the property of Synaptic Laboratories Limited and its suppliers,
# * if any.  The intellectual and technical concepts contained
# * herein are proprietary to Synaptic Laboratories Limited
# * and its suppliers and may be covered by U.S. and Foreign Patents,
# * patents in process, and are protected by trade secret or copyright law.
# * Dissemination of this information or reproduction of this material
# * is strictly forbidden unless prior written permission is obtained
# * from Synaptic Laboratories Limited
# *
# * Modification of this file is strictly forbidden unless prior written
# * permission is obtained from Synaptic Laboratories Limited
#
#########################################################################################################################

#
# DO NOT MODIFY
#

#
# Memory_Controller "SLL Memory Controller"
#  20175.02.10.15:04:00
#

#
# request TCL package from ACDS 15.0
#
package require -exact qsys 15.0
package require fileutil

#---------------------------------------------------------
# source include file for procedures used in this script
#---------------------------------------------------------
source sll_ca_xspi_mc_top_hw_proc.tcl

#---------------------------------------------------------
# module SLL Memory Controller
#---------------------------------------------------------
set_module_property NAME          sll_xspi_mc_avmm_top
set_module_property DISPLAY_NAME "SLL Avalon xSPI Memory Controller IP (xSPI-MC-Demo)"   ;
set_module_property DESCRIPTION  "\
    SLL Avalon xSPI Memory Controller (xSPI-MC) IP \
        for Arrow AXE5000-AXE3000 FPGA board"  ;
set_module_property AUTHOR       "Synaptic Laboratories Limited (SLL)"
set_module_property GROUP        "Synaptic Labs/Memory/xSPI"

set_module_property VERSION 3.3.116  ;

# Indicates whether you can edit the IP component in the Component Editor.
#
set_module_property EDITABLE true

# An IP component which is marked as internal does not appear in the IP Catalog.
# This feature allows you to hide the sub-IP- components of a larger composed IP component.
#
set_module_property INTERNAL false

# A path to an icon to display in the IP component's parameter editor.
#
# set_module_property ICON_PATH

# For composed IP components created using a _hw.tcl file that include children that are
# memory-mapped slaves, specifies whether the children's addresses are visible to downstream software tools.
# When true, the children's address are not visible. When false, the children's addresses are visible.
#
set_module_property OPAQUE_ADDRESS_MAP true

# If true, this IP component is implemented by HDL provided by the IP component.
# If false, the IP component will create exported interfaces allowing the implementation to be connected in the parent.
#
set_module_property INSTANTIATE_IN_SYSTEM_MODULE true

# A list of device family supported by this IP component.
#
# set_module_property SUPPORTED_DEVICE_FAMILIES

#
set_module_property   REPORT_HIERARCHY            false
set_module_property   REPORT_TO_TALKBACK          false
set_module_property   ALLOW_GREYBOX_GENERATION    false

#----------------------------------------------------
# file sets
#----------------------------------------------------
add_fileset           QUARTUS_SYNTH     QUARTUS_SYNTH                       synth_fileset_callback
#set_fileset_property  QUARTUS_SYNTH     TOP_LEVEL                           sll_xspi_mc_avmm_top
set_fileset_property  QUARTUS_SYNTH     ENABLE_RELATIVE_INCLUDE_PATHS       false
set_fileset_property  QUARTUS_SYNTH     ENABLE_FILE_OVERWRITE_MODE          true

add_fileset           SIM_VERILOG       SIM_VERILOG                         sim_fileset_callback
#set_fileset_property  SIM_VERILOG       TOP_LEVEL                           sll_xspi_mc_avmm_top
set_fileset_property  SIM_VERILOG       ENABLE_RELATIVE_INCLUDE_PATHS       false
set_fileset_property  SIM_VERILOG       ENABLE_FILE_OVERWRITE_MODE          true

add_fileset           SIM_VHDL          SIM_VHDL                            sim_fileset_callback
#set_fileset_property  SIM_VHDL          TOP_LEVEL                           sll_xspi_mc_avmm_top
set_fileset_property  SIM_VHDL          ENABLE_RELATIVE_INCLUDE_PATHS       false
set_fileset_property  SIM_VHDL          ENABLE_FILE_OVERWRITE_MODE          true

#######################################################################################################################
# Information Tab
#######################################################################################################################
#
add_display_item        ""          "Info"                                          GROUP tab

add_display_item        "Info"      "Synaptic Laboratories Limited (SLL)"        GROUP ""

add_display_item        "Info"      "License And Confidentiality Agreement"         GROUP ""
add_display_item        "Info"      "SLL xSPI Memory Controller (xSPI-MC)" GROUP ""
add_display_item        "Info"      "Installation of License Key"                   GROUP ""
add_display_item        "Info"      "Copyright Notice"                              GROUP ""

add_display_item        "Synaptic Laboratories Limited (SLL)"                    GUI_INFO_LOGO       ICON  "sll_logo.png"

add_display_item    "License And Confidentiality Agreement"   GUI_INFO_LICENSE                             TEXT    "<html>\
    <p><b>By Using SLL xSPI Memory Controller (xSPI-MC) IP,  <br/>\
    You acknowledge that You have read the accompanying  <br/>\
    License and Confidentiality Agreement, understand it, <br/>
    accept it and agree to be bound by all its Terms.</b></p></html>"

add_display_item        "SLL xSPI Memory Controller (xSPI-MC)"                 GUI_INFO_ABOUT      TEXT  "<html>\
    <p>Synaptic Laboratories Ltd (SLL) xSPI Memory Controller (xSPI-MC) provisions a <br/>\
    single Memory memory channel with support for up to 2 Memory memory devices.</p>\
    <p><br/>You can instantiate multiple instances of SLL xSPI-MC IP in your design.</p>\
    <p><br/>This version of SLL xSPI-MC IP supports both HyperRAM and HyperFlash devices.</p>\
    <p><br/>Visit <a href=\"www.synaptic-labs.com\">www.synaptic-labs.com</a> to access free documentation, free reference designs and <br/>\
    to download the latest version of this IP.</p></html>"

add_display_item    "Installation of License Key"   GUI_INFO_INSTALL_KEY                             TEXT    "<html>\
    <p>The accompanying License Credential with embedded License Key provides a description <br/>\
    of the License Type, Target Application, Supported Device/s, and what capabilities   <br/>\
    have been enabled/disabled under Your License. The full terms and conditions contained<br/>\
    in the License Credential with embedded License Key are included by reference into the<br/>\
    License and Confidentiality Agreement. <br/>\
    <p><br/>Your License Credential with embedded License Key is typically found:  <br/>\
    (a) in the xSPI-MC IP folder; or (b) as an attachment sent to you by e-mail.</p>\
    <p><br/>That License Key must be installed (copied and pasted) in Quartus Prime to synthesise designs<br/>\
    using this xSPI-MC IP. If required, search ''Intel FPGA Software Installation and Licensing Quick Start'' <br/>\
    on the Internet to find instructions on how to install License Keys into Quartus Prime.</p></html>"

add_display_item    "Copyright Notice"   GUI_INFO_COPYRIGHT                             TEXT    "<html>\
    <p><b>(c) 2018 Synaptic Laboratories Limited. All Rights Reserved. </b></p>\
    <p><br/>The intellectual and technical concepts contained herein are the proprietary property of<br/>
    Synaptic Laboratories Limited and its suppliers and may be covered by U.S. and <br/>
    Foreign Patents, patents in process, and are protected by confidentiality agreements, <br/>
    trade secret or copyright law. Reproduction of this material is strictly forbidden unless <br/>
    prior written permission is obtained from Synaptic Laboratories Limited. </p></html>"




#######################################################################################################################
# Master Configuration Tab
#######################################################################################################################
#
proc_add_master_configuration


#######################################################################################################################
# Clock Configuration Tab
#######################################################################################################################
#
proc_add_clock_configuration


#######################################################################################################################
#IAVS0 configuration
#######################################################################################################################
proc_add_iavs_config IAVS0


#######################################################################################################################
#Device configuration
#######################################################################################################################
for {set dev 0} {$dev < 2} {incr dev} {

    proc_add_dev_info $dev

}


#-------------------------------------------------------------------------------
# DETECT DEVICE FAMILY
#----------------------------------------------------------------------------

add_parameter           DEVICE_FAMILY   STRING "Unknown"
set_parameter_property  DEVICE_FAMILY   VISIBLE false
set_parameter_property  DEVICE_FAMILY   SYSTEM_INFO {DEVICE_FAMILY}


#######################################################################################################################
#######################################################################################################################
##
##  HDL PARAMETERS
##
#######################################################################################################################
#######################################################################################################################

proc_add_hdl_parameter  g_iavs0_addr_width          INTEGER      18
proc_add_hdl_parameter  g_iavs0_data_width          INTEGER      32
proc_add_hdl_parameter  g_iavs0_av_numsymbols       INTEGER       4
proc_add_hdl_parameter  g_iavs0_burstcount_width    INTEGER       1
proc_add_hdl_parameter  g_iavs0_linewrap_burst      INTEGER       0
proc_add_hdl_parameter  g_iavs0_register_rdata      INTEGER       0
proc_add_hdl_parameter  g_iavs0_register_wdata      INTEGER       0

proc_add_hdl_parameter  g_powerup_timer_width       INTEGER       14

proc_add_hdl_parameter  g_memory_freq_in_mhz        INTEGER       0         ;# make no initial assumptions.
proc_add_hdl_parameter  g_iavs_freq_in_mhz          INTEGER       0         ;# make no initial assumptions.

proc_add_hdl_parameter  g_same_iavs_memory_clk      INTEGER       0         ;# make no initial assumptions.

proc_add_hdl_parameter  g_device_family             STRING        "Agilex 5"


proc_add_hdl_parameter  g_dqin_width                INTEGER       8
proc_add_hdl_parameter  g_dqs_width                 INTEGER       1


#######################################################################################################################
#######################################################################################################################
#conduits
#######################################################################################################################
#######################################################################################################################

#
#clock and reset connections
#
add_interface i_hbus_clk_0   clock end

set_interface_property  i_hbus_clk_0 clockRate 0
set_interface_property  i_hbus_clk_0 ENABLED true
set_interface_property  i_hbus_clk_0 EXPORT_OF ""
set_interface_property  i_hbus_clk_0 PORT_NAME_MAP ""
set_interface_property  i_hbus_clk_0 CMSIS_SVD_VARIABLES ""
set_interface_property  i_hbus_clk_0 SVD_ADDRESS_GROUP ""

add_interface_port i_hbus_clk_0 i_hbus_clk_0 clk Input 1

add_interface i_hbus_clk_90  clock end

set_interface_property  i_hbus_clk_90 clockRate 0
set_interface_property  i_hbus_clk_90 ENABLED true
set_interface_property  i_hbus_clk_90 EXPORT_OF ""
set_interface_property  i_hbus_clk_90 PORT_NAME_MAP ""
set_interface_property  i_hbus_clk_90 CMSIS_SVD_VARIABLES ""
set_interface_property  i_hbus_clk_90 SVD_ADDRESS_GROUP ""

add_interface_port i_hbus_clk_90 i_hbus_clk_90 clk Input 1

#
# connection point clock
#
add_interface           i_iavs0_clk clock end
set_interface_property  i_iavs0_clk clockRate 0
set_interface_property  i_iavs0_clk ENABLED true
set_interface_property  i_iavs0_clk EXPORT_OF ""
set_interface_property  i_iavs0_clk PORT_NAME_MAP ""
set_interface_property  i_iavs0_clk CMSIS_SVD_VARIABLES ""
set_interface_property  i_iavs0_clk SVD_ADDRESS_GROUP ""

add_interface_port      i_iavs0_clk i_iavs0_clk clk Input 1


#
# connection point i_iavs0_rstn
#
add_interface           i_iavs0_rstn reset end
set_interface_property  i_iavs0_rstn associatedClock i_iavs0_clk
set_interface_property  i_iavs0_rstn synchronousEdges DEASSERT
set_interface_property  i_iavs0_rstn ENABLED true
set_interface_property  i_iavs0_rstn EXPORT_OF ""
set_interface_property  i_iavs0_rstn PORT_NAME_MAP ""
set_interface_property  i_iavs0_rstn CMSIS_SVD_VARIABLES ""
set_interface_property  i_iavs0_rstn SVD_ADDRESS_GROUP ""

add_interface_port      i_iavs0_rstn i_iavs0_rstn reset_n Input 1

#
# connection point iavs_s0
#

proc_add_avalon_slave  iavs0  1
set_interface_property iavs0 associatedClock            i_iavs0_clk
set_interface_property iavs0 associatedReset            i_iavs0_rstn
set_interface_property iavs0 bridgesToMaster            ""
set_interface_property iavs0 linewrapBursts             false ; # This value is typically zero for our IP.
set_interface_property iavs0 burstOnBurstBoundariesOnly true  ; # This is typically true, unless we have special burst support logic in our slave that supports non-aligned bursts



#
# connection point Conduit
#
add_interface Conduit_IO conduit end


#######################################################################################################################
#######################################################################################################################
##
##  VALIDATION is called before ELABORATION
##
#######################################################################################################################
#######################################################################################################################
#  set systemTime [clock seconds]
#  send_message INFO  "VALIDATION_CALLBACK Triggered [clock format $systemTime -format %H:%M:%S]"
#  send_message ERROR "text"

set_module_property VALIDATION_CALLBACK validate

proc validate {} {

    #
    #set Memory selectin based on Bus Protocol
    #
    proc_set_memory_ranges

    #
    #validate device configuration
    #
    proc_validate_dev_cfgs



}


#######################################################################################################################
#######################################################################################################################
##
##  ELABORATION
##
#######################################################################################################################
#######################################################################################################################

set_module_property ELABORATION_CALLBACK elaborate
proc elaborate {} {

    #++++++++++++++++++++++++++++++
    # Turn on some information messages to assist debugging the code flow / settings.
    #++++++++++++++++++++++++++++++
    #
    set v_debug 0


    #++++++++++++++++++++++++++++++
    # DATA Width
    #++++++++++++++++++++++++++++++

    set_parameter_value g_dqin_width          8
    set_parameter_value g_dqs_width           1

    #++++++++++++++++++++++++++++++
    # Set Device family
    #++++++++++++++++++++++++++++++
    #
    set_parameter_value g_device_family [ get_parameter_value DEVICE_FAMILY ]

    #++++++++++++++++++++++++++++++
    # Auto detect IAVSx clocks
    #++++++++++++++++++++++++++++++
    set v_auto_iavs0_clock_rate   [get_parameter_value GUI_IAVS0_AUTO_CLOCK_RATE]
    set v_iavs0_frequency_mhz     [expr $v_auto_iavs0_clock_rate/1000000]

    set_parameter_value g_iavs_freq_in_mhz  $v_iavs0_frequency_mhz

    #----------------------------
    #set frequency range for Avalon Channel and Memory Channel
    #----------------------------
    set_parameter_property  MEMORY_FREQ_IN_MHZ     ALLOWED_RANGES 20:200 ;
    set_parameter_property  IAVS_FREQ_OUT_IN_MHZ   ALLOWED_RANGES 20:200 ;


    #++++++++++++++++++++++++++++++
    # Auto detect HBUS clocks
    #++++++++++++++++++++++++++++++
    set_parameter_property GUI_HBUS0_AUTO_CLOCK_RATE    ENABLED    true

    set v_auto_hbus0_clock_rate   [get_parameter_value GUI_HBUS0_AUTO_CLOCK_RATE]
    set v_memory_frequency_mhz  [expr $v_auto_hbus0_clock_rate/1000000]

    set_parameter_value g_memory_freq_in_mhz     $v_memory_frequency_mhz
    set_parameter_value GUI_MEMORY_FREQ_IN_MHZ_SC  $v_memory_frequency_mhz

    #----------------------------
    #IAVS Output Clock
    #----------------------------
    set_parameter_property GUI_AV_OUT_FREQ_IN_MHZ_SC    VISIBLE    true
    set_parameter_property MEMORY_FREQ_IN_MHZ           VISIBLE    false
    set_parameter_property IAVS_FREQ_OUT_IN_MHZ         VISIBLE    false

    set_parameter_value    GUI_AV_OUT_FREQ_IN_MHZ_SC    $v_iavs0_frequency_mhz

    #----------------------------
    #Check Clock frequency
    #----------------------------
    if { [get_parameter_value GUI_SINGLE_CLK_OP]} {
       set_parameter_value g_same_iavs_memory_clk  1

       if {$v_iavs0_frequency_mhz != $v_memory_frequency_mhz} {
           send_message error  "For Single Clock operation, The IAVS0 port clock port needs to be connected to the Memory Channel clock source (i_hbus_clk_0)"
       }
    } else {
       set_parameter_value g_same_iavs_memory_clk  0

        if {($v_iavs0_frequency_mhz == $v_memory_frequency_mhz) && ($v_iavs0_frequency_mhz != 0) } {
          send_message Warning  "It is recommended to use Single Clock operation, since The IAVS0 clock port and Memory Channel clock source (i_hbus_clk_0) have the same frequency"
       }
    }

    #++++++++++++++++++++++++++++++
    # Detect Number of chipselects
    #++++++++++++++++++++++++++++++
    set                 v_num_chipselect        [get_parameter_value GUI_NUM_CHIPSELECTS]

    if { $v_debug } {
      send_message Info "elaborate : v_num_chipselect : $v_num_chipselect"
    }

    #++++++++++++++++++++++++++++++
    # DQ-DQS value
    #++++++++++++++++++++++++++++++
    set v_default_dq_dqs_skew [get_parameter_value GUI_DQ_DQS_SKEW_DEFAULT]

    if {$v_memory_frequency_mhz < 100} {
      set dq_dqs_skew_val 810
    } else {
      set dq_dqs_skew_val [expr  (80000/$v_memory_frequency_mhz)]
    }

    #++++++++++++++++++++++++++++++
    # PowerUp Timer
    #++++++++++++++++++++++++++++++
    set v_powerup_timer_dly [get_parameter_value GUI_POWERUP_TIMER]
    set v_powerup_timer_dly [expr $v_powerup_timer_dly * 1000]
    set v_powerup_timer_dly [proc_calc_timing  $v_powerup_timer_dly $v_memory_frequency_mhz]

    set v_powerup_timer_dly_log [log2ceil $v_powerup_timer_dly]

    set_parameter_value g_powerup_timer_width [expr $v_powerup_timer_dly_log + 1]

    #++++++++++++++++++++++++++++++
    # Number of Hbus Channels
    #++++++++++++++++++++++++++++++
    set v_hbus_num_channels  [get_parameter_value GUI_HBUS_CHANNELS]

     for {set ch 0} {$ch < 4} {incr ch} {
       if {$ch < $v_hbus_num_channels} {
          if {$v_default_dq_dqs_skew} {
          set_parameter_property     GUI_CH${ch}_DQ_DQS_SKEW      VISIBLE true
          set_parameter_property     GUI_CH${ch}_DQ_DQS_SKEW_MAN  VISIBLE false
          } else {
          set_parameter_property     GUI_CH${ch}_DQ_DQS_SKEW      VISIBLE false
          set_parameter_property     GUI_CH${ch}_DQ_DQS_SKEW_MAN  VISIBLE true

          set dq_dqs_skew_val [get_parameter_value GUI_CH${ch}_DQ_DQS_SKEW_MAN]
          }
       } else {
          set_parameter_property     GUI_CH${ch}_DQ_DQS_SKEW      VISIBLE false
          set_parameter_property     GUI_CH${ch}_DQ_DQS_SKEW_MAN  VISIBLE false
       }

       set_parameter_value        GUI_CH${ch}_DQ_DQS_SKEW  $dq_dqs_skew_val
    }

    #++++++++++++++++++++++++++++++
    # Adjust interfaces
    #++++++++++++++++++++++++++++++

    set_interface_property     Conduit_IO          ENABLED true
    proc_Add_Memory_Conduit_IO  $v_num_chipselect 

    #++++++++++++++++++++++++++++++
    # Device 0 parameters
    #++++++++++++++++++++++++++++++
    proc_set_device_info 0

    #++++++++++++++++++++++++++++++
    # Device 1 parameters
    #++++++++++++++++++++++++++++++
    proc_set_device_info 1

    if { $v_debug } {
      send_message Info "elaborate : Start Device Parameter Configuration"
    }

    set v_larger_dev_size                   0
    set v_total_dev_size_mb                 0
    set v_hyperflash_detected               2       ;# 0:in CS0, 1:IN CS1, 2:NONE DETECTED
    set v_linewrap8_support                 1       ;# Line Wrap suppot


    for {set dev 0} {$dev < 2} {incr dev} {

        # Do we populate this device tab?
        #
        if {$dev <  $v_num_chipselect } {

            #-----------------------------------------------------
            #  get name
            #-----------------------------------------------------
            set v_dev_name              [get_parameter_value GUI_DEV${dev}_NAME]

            #-----------------------------------------------------
            #  calculate size
            #-----------------------------------------------------
            set v_dev_size              [get_parameter_value GUI_DEV${dev}_SIZE]

            set v_total_dev_size_mb     [expr $v_total_dev_size_mb + $v_dev_size]

            if { $v_dev_size > $v_larger_dev_size } {
                set v_larger_dev_size $v_dev_size
            }

            #-----------------------------------------------------
            #  Set data width
            #-----------------------------------------------------
            set v_xdq_width  [get_parameter_value GUI_DEV${dev}_DQ_WIDTH]

            if {$v_xdq_width == 16} {
                set_parameter_value g_dqin_width  16
                set_parameter_value g_dqs_width   2
            }

            if {$v_xdq_width == 4} {
                set_parameter_value g_dqin_width  4
            }

            #-----------------------------------------------------
            # Disable LineWrap if any of the Target memory device does not support LineWrap Burst
            #-----------------------------------------------------
            set v_linewrap8_en  [get_parameter_value GUI_DEV${dev}_WRAP_SUPPORT]

            if {$v_linewrap8_en == 0} {
               set v_linewrap8_support 0
            }


            #-----------------------------------------------------
            #check whether device is flash
            #-----------------------------------------------------
            if {($v_dev_name != "none" ) && [get_parameter_value GUI_DEV${dev}_IS_FLASH] == 1} {
                  set v_hyperflash_detected $dev
            }
        }
    }

    # Configure the IAVS port based on the HB memory devices selected.
    #
    if { $v_larger_dev_size == 0 } {

        # This error message has to be put in the validate
        send_message Error "Please ensure that there is at least one memory device configured for this xSPI-MC instantiation."

    } else {

        # Process the data related items
        #
        set v_iavs0_gui_data_width                   [ get_parameter_value GUI_IAVS0_DATA_WIDTH]
        set v_iavs0_gui_av_numsymbols                [ expr $v_iavs0_gui_data_width/8]
        set v_iavs0_gui_av_numsymbols_log2           [ expr int( ceil( log($v_iavs0_gui_av_numsymbols) / log(2) ) )]

        #address is word aligned
#        set v_max_addr_width [ expr int((ceil( log($v_larger_dev_size) / log(2) )) + 19)]

        set v_dev_size_in_bytes                      [ expr  $v_total_dev_size_mb * 1024 *1024]
        set v_max_addr_width                         [ expr { [log2ceil $v_dev_size_in_bytes] - [ log2ceil $v_iavs0_gui_av_numsymbols] } ]

        set v_iavs0_addr_width                       $v_max_addr_width
        set v_iavs0_gui_burstcount                   [ get_parameter_value GUI_IAVS0_MAX_BURST_IN_WORDS]
        set v_iavs0_gui_burstcount_width             [ expr int( (ceil( log($v_iavs0_gui_burstcount) / log(2) )) + 1)]

        set_parameter_value GUI_IAVS0_ADDR_WIDTH     $v_iavs0_addr_width

        #-----------------------------------------------------------------------
        #set address Span
        #-----------------------------------------------------------------------
        set_interface_property iavs0  explicitAddressSpan   [expr (($v_total_dev_size_mb)*1024*1024)]

        #-----------------------------------------------------------------------
        #Setting linewrapBursts and burstOnBurstBoundariesOnly
        #-----------------------------------------------------------------------
        if {$v_iavs0_gui_burstcount > 1} {
            set_parameter_property GUI_IAVS0_BURST_ON_BURST_BOUNDARIES_AUTO  VISIBLE  true
            set_parameter_property GUI_IAVS0_BURST_ON_BURST_BOUNDARIES_ONLY  VISIBLE  false


            #linewrap only for burst 8
            if {$v_iavs0_gui_burstcount == 8 && $v_linewrap8_support == 1} {
               set_parameter_property GUI_IAVS0_LINEWRAP_BURST                  VISIBLE  true
            } else {
               set_parameter_property GUI_IAVS0_LINEWRAP_BURST                  VISIBLE  false
            }

            #linewrap burst only for Burst 8
            if {[get_parameter_value GUI_IAVS0_LINEWRAP_BURST] && ($v_iavs0_gui_burstcount == 8) && $v_linewrap8_support==1} {
                set_interface_property iavs0 linewrapBursts                      true;
                set_parameter_value    g_iavs0_linewrap_burst                    1
                set_parameter_value    GUI_IAVS0_BURST_ON_BURST_BOUNDARIES_AUTO  false  ; #
                set_interface_property iavs0 burstOnBurstBoundariesOnly          false  ; # This is typically true, unless we have special burst support logic in our slave that supports non-aligned bursts
            } else {
                set_parameter_property GUI_IAVS0_BURST_ON_BURST_BOUNDARIES_AUTO  VISIBLE  false
                set_parameter_property GUI_IAVS0_BURST_ON_BURST_BOUNDARIES_ONLY  VISIBLE  true

##                set_parameter_property GUI_IAVS0_BURST_ON_BURST_BOUNDARIES_ONLY  ALLOWED_RANGES {"1:true"}

                set_interface_property iavs0 linewrapBursts                      false;
                set_parameter_value    g_iavs0_linewrap_burst                    0

                if {[get_parameter_value GUI_IAVS0_BURST_ON_BURST_BOUNDARIES_ONLY] } {
                    if {$v_iavs0_gui_burstcount == 8} {
                       set_parameter_value    g_iavs0_linewrap_burst                    1
                    } else {
                       set_parameter_value    g_iavs0_linewrap_burst                    0
                    }
                    set_interface_property iavs0 burstOnBurstBoundariesOnly         true; # This is typically true, unless we have special burst support logic in our slave that supports non-aligned bursts
                } else {
                    set_interface_property iavs0 burstOnBurstBoundariesOnly         false; # This is typically true, unless we have special burst support logic in our slave that supports non-aligned bursts
                }
            }
        } else {
            set_parameter_property GUI_IAVS0_LINEWRAP_BURST                  VISIBLE  false
            set_parameter_property GUI_IAVS0_BURST_ON_BURST_BOUNDARIES_ONLY  VISIBLE  false
            set_parameter_property GUI_IAVS0_BURST_ON_BURST_BOUNDARIES_AUTO  VISIBLE  false

            set_interface_property iavs0 linewrapBursts             false ; # This value is typically zero for our IP.
            set_interface_property iavs0 burstOnBurstBoundariesOnly true  ; # This is typically true, unless we have special burst support logic in our slave that supports non-aligned bursts
            set_parameter_value    g_iavs0_linewrap_burst           0
        }

        set_parameter_property      GUI_IAVS0_WRITE_MODE    VISIBLE true

        if {[get_parameter_value GUI_IAVS0_WRITE_MODE]} {
            proc_add_avalon_conduit iavs0                   AV_READ_WRITE 2
            set_parameter_value     GUI_IAVS0_PORT_MODE     "Read/Write"
            set_parameter_property  GUI_IAVS0_BYTEENABLE    VISIBLE true
            set iavs0_write_port    1
        } else {
            proc_add_avalon_conduit iavs0                   AV_READ_ONLY  2
            set_parameter_value     GUI_IAVS0_PORT_MODE     "Read only"
            set_parameter_property  GUI_IAVS0_BYTEENABLE    VISIBLE false

            set iavs0_write_port    0
        }
        set_interface_property    iavs0                  addressGroup {1}

        #-----------------------------------------------------------------------
        # Disable i_iavs0_byteenable
        #-----------------------------------------------------------------------
        if {$iavs0_write_port==1} {
            if {[get_parameter_value GUI_IAVS0_BYTEENABLE]  } {
                set_port_property i_iavs0_byteenable TERMINATION false
            } else {
                set_port_property i_iavs0_byteenable TERMINATION true
                set_port_property i_iavs0_byteenable TERMINATION_VALUE 0xFFFFFFFFFFFFFF
            }
        }

        #----------------------------------------------------------------------------------------
        #add termination value if response is not used
        #----------------------------------------------------------------------------------------
        if {[get_parameter_value GUI_IAVS0_USE_RESPONSE]} {
            set_port_property  o_iavs0_resp        TERMINATION    false
        } else {
            set_port_property  o_iavs0_resp        TERMINATION    true
        }

        #-----------------------------------------------------------------------
        #Disable burst count signals
        #-----------------------------------------------------------------------
        if {$v_iavs0_gui_burstcount > 1} {
            set_port_property i_iavs0_burstcount   TERMINATION false
        } else {
            set_port_property i_iavs0_burstcount   TERMINATION true
            set_port_property i_iavs0_burstcount   TERMINATION_VALUE 1
        }

        #
        # Process HDL generics
        #
        set_parameter_value g_iavs0_register_rdata    [get_parameter_value GUI_IAVS0_REG_RDATA]
        set_parameter_value g_iavs0_register_wdata    [get_parameter_value GUI_IAVS0_REG_WDATA]
        set_parameter_value g_iavs0_addr_width        $v_iavs0_addr_width
        set_parameter_value g_iavs0_data_width        $v_iavs0_gui_data_width
        set_parameter_value g_iavs0_av_numsymbols     $v_iavs0_gui_av_numsymbols
        set_parameter_value g_iavs0_burstcount_width  $v_iavs0_gui_burstcount_width
    }

}



#-----------------------------------------------------------------------------
# fileset_callback --
#-----------------------------------------------------------------------------
proc synth_fileset_callback { NAME } {


   #et device family
   set device_family     [ get_parameter_value DEVICE_FAMILY ]

   # Create the file in a temporary location
   if {[catch {create_temp_file temp.txt} temp_file]} {
      send_message error "create_temp_file $temp_file failed!"
   }
   send_message info "create_temp_file $temp_file"

   set OutputDirName  [ file dirname $temp_file  ]

   #Set Names
   set UniqueName  [get_parameter_value  GUI_UniqueName]
   set ModuleName  [string range $UniqueName end-10 end]


   #
   # Creating SDC file
   #
   # if PHY Lite interface is defined, sdc script is not created
   #


      set SdcOutFileName [file join ${OutputDirName} ${UniqueName}.sdc]

      set hbus_clk_freq      [get_parameter_value GUI_MEMORY_FREQ_IN_MHZ_SC]
      set dqs_clk_freq_in_ns [expr 1/ ($hbus_clk_freq * 1e6) * 1e9]
      set dqs_clk_freq_in_ns [format "%.3f" $dqs_clk_freq_in_ns]


      #
      #get IAVS/HBUS Clock Mode
      #
      set single_clock_mode  [get_parameter_value GUI_SINGLE_CLK_OP]

      #
      #get dq dqs skew
      #
      set dqs_dq_skew_info ""
      for {set ch 0} {$ch < 4} {incr ch} {
         set dqs_dq_skew [get_parameter_value  GUI_CH${ch}_DQ_DQS_SKEW  ]
         set dqs_dq_skew [expr $dqs_dq_skew/1000.00]

         lappend dqs_dq_skew_info $dqs_dq_skew
      }


      file copy -force sll_ca_xspi_mc_top.sdc ${SdcOutFileName}

      #replace with
      set replacementCmd [list string map [list ModuleName ${ModuleName}]]
      fileutil::updateInPlace  ${SdcOutFileName} $replacementCmd

      #replace dqs_dq_skew_info with actual clock frequency
      set replacementCmd [list string map [list dqs_dq_skew_info ${dqs_dq_skew_info}]]
      fileutil::updateInPlace  ${SdcOutFileName} $replacementCmd

      #replace dqs_clk_freq_in_ns with actual clock frequency
      set replacementCmd [list string map [list dqs_clk_freq_in_ns ${dqs_clk_freq_in_ns}]]
      fileutil::updateInPlace  ${SdcOutFileName} $replacementCmd

      #replace single_clock_mode variable with chosen parameter
      set replacementCmd [list string map [list single_clock_mode ${single_clock_mode}]]
      fileutil::updateInPlace  ${SdcOutFileName} $replacementCmd

      #replace device_family variable with chosen parameter
      set replacementCmd [list string map [list device_family ${device_family}]]
      fileutil::updateInPlace  ${SdcOutFileName} $replacementCmd

      add_fileset_file ${UniqueName}.sdc SDC PATH $SdcOutFileName

   #
   #create wrapper file
   #
   set WrapperFileName [file join ${OutputDirName} ${NAME}.sv]
   file copy -force sll_ca_xspi_mc_top_wrapper.sv ${WrapperFileName}

   set top_module   $NAME
   set replacementCmd [list string map [list sll_ca_xspi_mc_top_wrapper $top_module]]
   fileutil::updateInPlace  ${WrapperFileName} $replacementCmd

   add_fileset_file ${NAME}.sv SYSTEM_VERILOG PATH $WrapperFileName


   #
   # Create a list of verilog files.
   #
   add_fileset_file altera_gpio.sv   SYSTEM_VERILOG PATH altera_gpio_axe5.sv


   add_fileset_file sll_ca_xspi_mc_top_enc.sv   SYSTEM_VERILOG PATH sll_ca_xspi_mc_top_enc.sv


}


#-----------------------------------------------------------------------------
# fileset_callback --
#-----------------------------------------------------------------------------
#proc sim_fileset_callback { NAME } {
#
#    send_message error  "Simulation Not supported for this Demo"
#
#}


#-----------------------------------------------------------------------------
# fileset_callback --
#-----------------------------------------------------------------------------
proc sim_fileset_callback { NAME } {

   #et device family
   set device_family     [ get_parameter_value DEVICE_FAMILY ]

   # Create the file in a temporary location
   if {[catch {create_temp_file temp.txt} temp_file]} {
      send_message error "create_temp_file $temp_file failed!"
   }
   send_message info "create_temp_file $temp_file"

   set OutputDirName  [ file dirname $temp_file  ]

	 #
	 #create wrapper file
	 #
   set WrapperFileName [file join ${OutputDirName} ${NAME}.sv]   
   file copy -force sll_ca_xspi_mc_top_wrapper.sv ${WrapperFileName}
   
   set top_module   $NAME
   set replacementCmd [list string map [list sll_ca_xspi_mc_top_wrapper $top_module]]
   fileutil::updateInPlace  ${WrapperFileName} $replacementCmd

   add_fileset_file ${NAME}.sv SYSTEM_VERILOG PATH $WrapperFileName      


    #
    # Create a list of verilog files.
    #

   #altera_gpio_lite module
    add_fileset_file altera_gpio.sv   SYSTEM_VERILOG PATH altera_gpio_axe5.sv
   add_fileset_file sll_ca_xspi_mc_top_enc_sim.sv   SYSTEM_VERILOG PATH sll_ca_xspi_mc_top_enc_sim.sv


}

