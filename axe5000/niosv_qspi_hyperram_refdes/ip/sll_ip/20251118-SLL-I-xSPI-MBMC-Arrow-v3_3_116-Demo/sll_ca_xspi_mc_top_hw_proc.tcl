
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
#######################################################################################################################
#functions used by tcl script
#######################################################################################################################

#-------------------------------------------------------------------------------
#log2ceil
#-------------------------------------------------------------------------------
proc log2ceil {num} {

    set val 0
    set i 1
    while {$i < $num} {
        set val [expr $val + 1]
        set i [expr 1 << $val]
    }

    return $val;
}

#-------------------------------------------------------------------------------
#proc set ranges for Memory memories
#-------------------------------------------------------------------------------
proc proc_set_memory_ranges {} {

   for {set dev 0} {$dev < 2} {incr dev} {

      #Get Protocol For Device
      set v_dev_protocol [get_parameter_value  GUI_DEV${dev}_PROTOCOL_MAN]

      switch $v_dev_protocol {
          "none"        {set_parameter_property GUI_DEV${dev}_MODEL ALLOWED_RANGES  "none:none"}
          "HyperRAM"    {set_parameter_property GUI_DEV${dev}_MODEL ALLOWED_RANGES { \
                          "w957d8nws_w2k_1:W957D8NWS (Winbond) 1.2V HyperRAM @125 MHz 128 Mbit Wrap 2K mode"\
                          "w957d8nws_w2k_2:W957D8NWS (Winbond) 1.2V HyperRAM @166 MHz 128 Mbit Wrap 2K mode"\
                        "w957d8nws_w2k_3:W957D8NWS (Winbond) 1.2V HyperRAM @200 MHz 128 Mbit Wrap 2K mode"}}
          default       {set_parameter_property GUI_DEV${dev}_MODEL ALLOWED_RANGES  "none:none"}
      }
   }
}


#-------------------------------------------------------------------------------
#proc get timing cycles (round up to next integer)
#-------------------------------------------------------------------------------
proc proc_calc_timing {v_tim_param clock_speed_mhz} {
     set v_tim_param_cycles [expr ${v_tim_param} * ${clock_speed_mhz}]

       if {[expr fmod($v_tim_param_cycles, 1000)] != 0 } {
          set v_tim_param_cycles [expr ($v_tim_param_cycles/1000) + 1]
       } else {
          set v_tim_param_cycles [expr ($v_tim_param_cycles)/1000]
       }
   return ${v_tim_param_cycles}
}


#-------------------------------------------------------------------------------
#set display group
#-------------------------------------------------------------------------------
proc proc_add_master_configuration  {} {

add_display_item ""                                         "Master Configuration"                              GROUP tab

add_display_item "Master Configuration"                     "Memory Channel Configuration"                    GROUP ""
add_display_item "Master Configuration"                     "Memory Channel 0 Configuration"                  GROUP ""
add_display_item "Master Configuration"                     "Memory Channel 1 Configuration"                  GROUP ""
add_display_item "Master Configuration"                     "Memory Powerup Configuration"                    GROUP ""
add_display_item "Master Configuration"                     "Memory RWDS-DQ SKEW Configuration"               GROUP ""
add_display_item "Master Configuration"                     "Derived Parameters"                              GROUP COLLAPSED

add_display_item "Memory Channel Configuration"             GUI_HBUS_CHANNELS                    PARAMETER "" ;# FPGA board
add_display_item "Memory Channel Configuration"             GUI_NUM_CHIPSELECTS                   PARAMETER "" ;# Number of Chip Select
add_display_item "Memory Powerup Configuration"             GUI_POWERUP_TIMER                     PARAMETER "" ;# Number of Chip Select

add_display_item "Memory RWDS-DQ SKEW Configuration"        GUI_DQ_DQS_SKEW_DEFAULT              PARAMETER "" ;# Include register Avalon port


proc_add_parameter      GUI_HBUS_CHANNELS           INTEGER 1 "" false "Memory Channel Configuration"
set_parameter_property  GUI_HBUS_CHANNELS           DISPLAY_NAME  "Number of Parallel Memory channels"
set_parameter_property  GUI_HBUS_CHANNELS           ALLOWED_RANGES {1}
set_parameter_property  GUI_HBUS_CHANNELS           DESCRIPTION  "Number of Parallel Memory channels"
set_parameter_property  GUI_HBUS_CHANNELS           ENABLED        true


proc_add_parameter      GUI_NUM_CHIPSELECTS         INTEGER 2 "" true "Memory Channel Configuration"
set_parameter_property  GUI_NUM_CHIPSELECTS         DISPLAY_NAME  "Number of chip selects on this memory channel"
set_parameter_property  GUI_NUM_CHIPSELECTS         ALLOWED_RANGES {2}
set_parameter_property  GUI_NUM_CHIPSELECTS         ENABLED        false
set_parameter_property  GUI_NUM_CHIPSELECTS         VISIBLE        false
set_parameter_property  GUI_NUM_CHIPSELECTS         DESCRIPTION \
    "The number of chip selects signals driven by this MBMC is always 2.\
     Chip selects wih no devices will be constantly driven by the MBMC as inactive to ensure correct operation."


proc_add_parameter      GUI_DQ_DQS_SKEW_DEFAULT  BOOLEAN true "" false  "Memory RWDS-DQ SKEW Configuration"
set_parameter_property  GUI_DQ_DQS_SKEW_DEFAULT  DISPLAY_NAME "Enable Default RWDS-DQ SKEW settings" ;
set_parameter_property  GUI_DQ_DQS_SKEW_DEFAULT  DESCRIPTION  "Enable Default RWDS-DQ SKEW settings"

proc_add_parameter      GUI_POWERUP_TIMER INTEGER 150 "microseconds" false  "Memory Powerup Configuration"
set_parameter_property  GUI_POWERUP_TIMER DISPLAY_NAME   "PowerUp Delay Timer"


#---------------------------------------------------
# Add Channels
#---------------------------------------------------

   for {set dev 0} {$dev < 2} {incr dev} {

       # Instantiate Manual Configuration
       #   The Value of the Manual configuration will be loaded into the AUTO configuration as required.
       #
       add_display_item "Memory Channel $dev Configuration"  GUI_DEV${dev}_PROTOCOL_MAN  PARAMETER ""

       if { $dev eq 0} {
          proc_add_parameter     GUI_DEV${dev}_PROTOCOL_MAN String "none" "" false "Memory Channel $dev Configuration"
          set_parameter_property GUI_DEV${dev}_PROTOCOL_MAN DISPLAY_NAME  "Protocol ${dev}"
          set_parameter_property GUI_DEV${dev}_PROTOCOL_MAN DESCRIPTION   \
              "Select the specific type of Protocol used by the memory device on this chip select signal."
          set_parameter_property GUI_DEV${dev}_PROTOCOL_MAN ENABLED        true
          set_parameter_property GUI_DEV${dev}_PROTOCOL_MAN ALLOWED_RANGES \
           {"none"}
      }

       if { $dev eq 1} {
          proc_add_parameter     GUI_DEV${dev}_PROTOCOL_MAN String "HyperRAM" "" false "Memory Channel $dev Configuration"
          set_parameter_property GUI_DEV${dev}_PROTOCOL_MAN DISPLAY_NAME  "Protocol ${dev}"
          set_parameter_property GUI_DEV${dev}_PROTOCOL_MAN DESCRIPTION   \
              "Select the specific type of Protocol used by the memory device on this chip select signal."
          set_parameter_property GUI_DEV${dev}_PROTOCOL_MAN ENABLED        true
          set_parameter_property GUI_DEV${dev}_PROTOCOL_MAN ALLOWED_RANGES \
           {"HyperRAM"}
      }


       # Instantiate Manual Configuration
       #   The Value of the Manual configuration will be loaded into the AUTO configuration as required.
       #
       add_display_item "Memory Channel $dev Configuration"  GUI_DEV${dev}_MODEL  PARAMETER ""

       if { $dev eq 0} {
          proc_add_parameter     GUI_DEV${dev}_MODEL String "none" "" false "Memory Channel $dev Configuration"
       }

       if { $dev eq 1} {
          proc_add_parameter     GUI_DEV${dev}_MODEL String "w957d8nws_w2k_1" "" false "Memory Channel $dev Configuration"
       }

       set_parameter_property GUI_DEV${dev}_MODEL DISPLAY_NAME  "Memory device on chip select ${dev}"
       set_parameter_property GUI_DEV${dev}_MODEL DESCRIPTION   \
           "Select the specific type of Memory device connected to this chip select signal."
       set_parameter_property GUI_DEV${dev}_MODEL ENABLED        true
          # Create and populate the 'Device X Info' tab.


   }

  #---------------------------------------------------
  #Add DQ-DQS Skew parameters
  #---------------------------------------------------
  for {set ch 0} {$ch < 4} {incr ch} {
    proc_add_dq_dqs_skew_param $ch
  }

}



#-------------------------------------------------------------------------------
# CLOCK and PLL configuration Tab
#-------------------------------------------------------------------------------
proc proc_add_clock_configuration {} {

add_display_item ""                                     "Clock and PLL Configuration"           GROUP tab

add_display_item "Clock and PLL Configuration"          "Clock Configuration"                   GROUP ""
add_display_item "Clock and PLL Configuration"          "Selected Configuration - Bandwidth"    GROUP ""
add_display_item "Clock and PLL Configuration"          "Selected Configuration - Clocks"       GROUP ""
add_display_item "Clock and PLL Configuration"          "Clock Introspection Report"            GROUP ""
add_display_item "Clock and PLL Configuration"          "About the PLL Integrated In This MBMC Instance"      GROUP ""


add_display_item "Clock Configuration"                  GUI_SINGLE_CLK_OP                   PARAMETER "" ;# Single Clock operation
add_display_item "Clock Configuration"                  GUI_IAVS0_AUTO_CLOCK_RATE           PARAMETER "" ;# MUST BE DISPLAYED UNDER THE GUI_SINGLE_CLK_OP
add_display_item "Clock Configuration"                  GUI_HBUS0_AUTO_CLOCK_RATE           PARAMETER "" ;# MUST BE DISPLAYED UNDER THE GUI_SINGLE_CLK_OP
add_display_item "Clock Configuration"                  GUI_IAVS0_AUTO_CLOCK_DOMAIN         PARAMETER "" ;# MUST BE DISPLAYED UNDER THE GUI_SINGLE_CLK_OP
add_display_item "Clock Configuration"                  GUI_HBUS_AUTO_CLOCK_DOMAIN          PARAMETER "" ;# MUST BE DISPLAYED UNDER THE GUI_SINGLE_CLK_OP
add_display_item "Clock Configuration"                  GUI_UniqueName                      PARAMETER "" ;# MUST BE DISPLAYED UNDER THE GUI_SINGLE_CLK_OP

###==========================================================
### Start Backwards compatability v2.12
###
add_display_item "Clock Configuration"                  MEMORY_FREQ_IN_MHZ                  PARAMETER ""  ;# MANUAL VARIABLE
add_display_item "Clock Configuration"                  IAVS_FREQ_OUT_IN_MHZ                PARAMETER ""  ;# MANUAL VARIABLE
###
### End Backwards compatability
###==========================================================

add_display_item "Selected Configuration - Clocks"      GUI_MEMORY_FREQ_IN_MHZ_SC         PARAMETER ""
add_display_item "Selected Configuration - Clocks"      GUI_AV_OUT_FREQ_IN_MHZ_SC         PARAMETER ""




## NO INTEGRATED CLOCK -> CLOCK INTROSPECTION

proc_add_parameter      GUI_IAVS0_AUTO_CLOCK_RATE       LONG 100 hertz true   "Clock Configuration"
set_parameter_property  GUI_IAVS0_AUTO_CLOCK_RATE       DISPLAY_NAME        "i_iavs0_clk frequency is"
set_parameter_property  GUI_IAVS0_AUTO_CLOCK_RATE       VISIBLE             false
set_parameter_property  GUI_IAVS0_AUTO_CLOCK_RATE       SYSTEM_INFO_TYPE    CLOCK_RATE
set_parameter_property  GUI_IAVS0_AUTO_CLOCK_RATE       SYSTEM_INFO_ARG     i_iavs0_clk


proc_add_parameter      GUI_HBUS0_AUTO_CLOCK_RATE       LONG 100 hertz true   "Clock Configuration"
set_parameter_property  GUI_HBUS0_AUTO_CLOCK_RATE       DISPLAY_NAME        "i_hbus_clk_0 frequency is"
set_parameter_property  GUI_HBUS0_AUTO_CLOCK_RATE       VISIBLE             false
set_parameter_property  GUI_HBUS0_AUTO_CLOCK_RATE       SYSTEM_INFO_TYPE    CLOCK_RATE
set_parameter_property  GUI_HBUS0_AUTO_CLOCK_RATE       SYSTEM_INFO_ARG     i_hbus_clk_0

proc_add_parameter      GUI_IAVS0_AUTO_CLOCK_DOMAIN     integer 100 "" true   "Clock Configuration"
set_parameter_property  GUI_IAVS0_AUTO_CLOCK_DOMAIN     DISPLAY_NAME        "i_iavs0_clk domain is"
set_parameter_property  GUI_IAVS0_AUTO_CLOCK_DOMAIN     VISIBLE             false
set_parameter_property  GUI_IAVS0_AUTO_CLOCK_DOMAIN     SYSTEM_INFO_TYPE    CLOCK_DOMAIN
set_parameter_property  GUI_IAVS0_AUTO_CLOCK_DOMAIN     SYSTEM_INFO_ARG     i_iavs0_clk

proc_add_parameter      GUI_HBUS_AUTO_CLOCK_DOMAIN     integer 100 "" true   "Clock Configuration"
set_parameter_property  GUI_HBUS_AUTO_CLOCK_DOMAIN     DISPLAY_NAME        "i_hbus_clk domain is"
set_parameter_property  GUI_HBUS_AUTO_CLOCK_DOMAIN     VISIBLE             false
set_parameter_property  GUI_HBUS_AUTO_CLOCK_DOMAIN     SYSTEM_INFO_TYPE    CLOCK_DOMAIN
set_parameter_property  GUI_HBUS_AUTO_CLOCK_DOMAIN     SYSTEM_INFO_ARG     i_hbus_clk_0

proc_add_parameter      GUI_UniqueName                 STRING "" "" true   "Clock Configuration"
set_parameter_property  GUI_UniqueName                 DISPLAY_NAME        "Unique Name"
set_parameter_property  GUI_UniqueName                 SYSTEM_INFO         UNIQUE_ID

###
# Open Cores only supports  single clock
#
proc_add_parameter     GUI_SINGLE_CLK_OP BOOLEAN false "" false  "Clock Configuration"
set_parameter_property GUI_SINGLE_CLK_OP ALLOWED_RANGES {"true:One clock-One clock for all the Avalon ports and the Memory channel" \
                                                         "false:Two clocks-One clock for all the Avalon ports. One clock for the Memory channel" }

set_parameter_property GUI_SINGLE_CLK_OP DISPLAY_NAME  "Avalon and Memory clock configuration"
set_parameter_property GUI_SINGLE_CLK_OP DESCRIPTION   "\
    The 'One clock for all the Avalon ports and the Memory channel' configuration has the lowest circuit area and is well suited for severely resource constrained designs.\
    The 'One clock for all the Avalon ports. One clock for the Memory channel' configuration employs a dual clock configuration. \
    In this configuration, SLL MBMC implements low-area, high-bandwidth, clock-crossing logic between the Avalon bus target and Memory channel."

##


# This variable is used to set the HyperBus frequency.
#
proc_add_parameter      MEMORY_FREQ_IN_MHZ   INTEGER   150   megahertz   false   "Clock Configuration"
set_parameter_property  MEMORY_FREQ_IN_MHZ   DISPLAY_NAME                        "Memory channel clock frequency"
set_parameter_property  MEMORY_FREQ_IN_MHZ   DESCRIPTION    "\
  This is the clock frequency used to drive the memory channel.\
  The wire-speed bandwidth of the 8-bit wide Double Data Rate (DDR) memory channel is: 2xMHz bytes per second."

# THIS VARIABLE SETS THE AVALON SHARED BUS SPEED, AND CAN SOMETIMES SET THE MEMORY FREQUENCY
#
proc_add_parameter      IAVS_FREQ_OUT_IN_MHZ   INTEGER   100   megahertz   false   "Clock Configuration"
set_parameter_property  IAVS_FREQ_OUT_IN_MHZ   DISPLAY_NAME                        "Shared Avalon clock frequency"
set_parameter_property  IAVS_FREQ_OUT_IN_MHZ   DESCRIPTION                         "\
  This is the clock frequency used to drive all the Avalon ports."


###
### End Backwards compatability
###==========================================================


## CLOCKS REPORT
#
proc_add_parameter     GUI_AV_OUT_FREQ_IN_MHZ_SC INTEGER 100 megahertz true "Selected Configuration - Clocks"
set_parameter_property GUI_AV_OUT_FREQ_IN_MHZ_SC DISPLAY_NAME   "Avalon output clock (av_out_clk) frequency"
set_parameter_property GUI_AV_OUT_FREQ_IN_MHZ_SC VISIBLE        true
set_parameter_property GUI_AV_OUT_FREQ_IN_MHZ_SC ENABLED            false
set_parameter_property GUI_AV_OUT_FREQ_IN_MHZ_SC DESCRIPTION        "\
    This is the clock frequency that the PLL in this MBMC instance generates for the clock source o_av_out_clk.\
    The o_av_out_clk is used to drive the avalon bus. It must also be connected to the i_iavs0_clk clock sink."


proc_add_parameter     GUI_MEMORY_FREQ_IN_MHZ_SC INTEGER 100 megahertz true "Selected Configuration - Clocks"
set_parameter_property GUI_MEMORY_FREQ_IN_MHZ_SC DISPLAY_NAME     "Memory channel clock frequency"
set_parameter_property GUI_MEMORY_FREQ_IN_MHZ_SC VISIBLE          true
set_parameter_property GUI_MEMORY_FREQ_IN_MHZ_SC ENABLED          false
set_parameter_property GUI_MEMORY_FREQ_IN_MHZ_SC DESCRIPTION      "\
    This is the clock frequency used to drive just the memory channel.\
    The peak sustainable bandwidth of the 8-bit wide Double Data Rate (DDR)\
    memory channel is: 2xMHz bytes per second."

}


#-------------------------------------------------------------------------------
#set display group
#-------------------------------------------------------------------------------
proc proc_validate_dev_cfgs {} {
    # variable needed to check data width
    set v_dev_xdq_width_selected   0

    #
    #get number of supported memory devices
    #
    set v_num_chipselect           [get_parameter_value GUI_NUM_CHIPSELECTS]

    #
    #get Memory channel frequency
    #
    set v_memory_frequency_mhz     [get_parameter_value GUI_MEMORY_FREQ_IN_MHZ_SC]
   

    #++++++++++++++++++++++++++++++
    #burst count
    #++++++++++++++++++++++++++++++
    set v_iavs0_gui_burstcount [ get_parameter_value GUI_IAVS0_MAX_BURST_IN_WORDS]


    #---------------------------------------------------------------
    #check configuration for generic x8
    #---------------------------------------------------------------
    set v_dev0_protocol         [get_parameter_value GUI_DEV0_PROTOCOL_MAN]
    set v_dev1_protocol         [get_parameter_value GUI_DEV1_PROTOCOL_MAN]


    #check configuration
    #---------------------------------------------------------------
    for {set dev 0} {$dev < 2} {incr dev} {
        #
        # Do we check this device tab?
        #
        if {$dev <  $v_num_chipselect } {
           set v_dev_name         [get_parameter_value GUI_DEV${dev}_NAME]
           set v_dev_max_speed    [get_parameter_value GUI_DEV${dev}_SPEED ]
           set v_dev_is_flash     [get_parameter_value GUI_DEV${dev}_IS_FLASH]
           set v_dev_is_xspi      [get_parameter_value GUI_DEV${dev}_IS_XSPI]
           set v_dev_tacc         [get_parameter_value GUI_DEV${dev}_T_ACC]
           set v_dev_tcss         [get_parameter_value GUI_DEV${dev}_T_CSS]
           set v_dev_tcsh         [get_parameter_value GUI_DEV${dev}_T_CSH]
           set v_dev_xdq_width    [get_parameter_value GUI_DEV${dev}_DQ_WIDTH]


           if {$v_dev_name != "none"} {
              #++++++++++++++++++++++++++++++
              #check whether we have different memory data widths
              #Only devices with same memory data widths are supported
              #++++++++++++++++++++++++++++++

              if {$v_dev_xdq_width_selected == 0} {
                 set v_dev_xdq_width_selected   $v_dev_xdq_width
              } else {
                 if {$v_dev_xdq_width_selected != $v_dev_xdq_width} {
                    send_message error  "Memories on Chip select 0, 1 have different I/O Data width.  \
                                         This is not supported. Please ensure that both memories have \
                                         the same  I/O Data width."
                 }
              }

              if {$v_dev_name == "w957d8nws_w2k_2" || $v_dev_name == "w957d8nws_w2k_3"} {
                send_message error  "This demo only support the memory device up to 125 Mhz.  \
                                     If you require higher frequency support, please
                                      send an email to info@synatic-labs.com for more info "
              }


              #++++++++++++++++++++++++++++++
              #Check Chip select Low (4us / 1us)
              #++++++++++++++++++++++++++++++

              #for Hyperflash, we do not double the Init latency time
              if {$v_dev_is_flash == 1} {
                set v_max_ce_low_time   [expr  3 + ($v_iavs0_gui_burstcount*2) + (  $v_dev_tacc) + $v_dev_tcss + $v_dev_tcsh]
              } else {
                set v_max_ce_low_time   [expr  3 + ($v_iavs0_gui_burstcount*2) + (2*$v_dev_tacc) + $v_dev_tcss + $v_dev_tcsh]
              }

              set vendor_tCE     4000
              set vendor_tCE_ind 1000

             #prevent error if frequency is 0
              if { $v_memory_frequency_mhz != 0} {

                 #convert to ns
                 set v_max_ce_low_time     [expr ($v_max_ce_low_time*1000) /$v_memory_frequency_mhz]
                 
                 if {($v_dev_is_flash == 0) && ($v_max_ce_low_time > $vendor_tCE_ind)} {
                    send_message Warning  "Total Chip Select Low (Tcsm) time is greater than $vendor_tCE_ind ns. \
                                           The range is acceptable for Industrial Design projects,  \
                                           For Automotive/Extended Temperature Design projects,  \
                                           please reduce Max Burst Size in the Avalon (IAVS0) Configuration Tab"
                 }
                 
                 if {($v_dev_is_flash == 0) && ($v_max_ce_low_time > $vendor_tCE)} {
                     send_message error  "Total Chip Select Low (Tcsm) time is greater than $vendor_tCE ns. \
                                         Please reduce Max Burst Size in the Avalon (IAVS0) Configuration Tab"
                 }

              }


              #++++++++++++++++++++++++++++++
              #For xSPI model, Register port needs to be enabled
              #++++++++++++++++++++++++++++++
              if {($v_dev_is_xspi == 1) && ([get_parameter_value GUI_INCLUDE_REG_AVALON] == 0)} {
                  send_message error  "Register Avalon Port needs to be enabled for this Device. \
                                      Please enable the  Register Avalon Port in the Master Configuration Tab"
              }


              #Check whether selected speed is supported on this device
              if {$v_dev_name != "none" && ($v_memory_frequency_mhz > $v_dev_max_speed) } {
                send_message error  "Current selected Frequency ($v_memory_frequency_mhz) is not supported for this device. \
                                    Please reduce the memory channel frequency."
              }
           }

        }
    }


    #check FPGA compatibility
    set v_device_family [ get_parameter_value DEVICE_FAMILY ]

    if {   $v_device_family == "Agilex 5"  ||
           $v_device_family == "AGILEX 5"  ||
           $v_device_family == "Agilex 3"  ||
           $v_device_family == "AGILEX 3" } {

           send_message Warning "In this configuration, High Clock speeds are not supported on the $v_device_family FPGA family.  \
                               If you have an R&D or Production license, please \
                               send an email to info@synatic-labs.com for more info "


          send_message Info "Ensure to add set_global_assignment -name VERILOG_MACRO CYCLONE_V_DDIO=1 in QSF file"


    }


    #Setting data width
    set v_iavs0_gui_data_width  [ get_parameter_value GUI_IAVS0_DATA_WIDTH]

    #++++++++++++++++++++++++++++++
    # Check the word width of the IAVS memory access port.
    #+++++++++++++++
    #
    if {$v_iavs0_gui_data_width != 32} {
        send_message error  "\
            The word width of IAVS0 is currently set to $v_iavs0_gui_data_width.\
            In this case, this value should be set to 32."
    }



    #
    # END ERROR MESSAGES THAT REQUIRE MANUAL INTERVENTION ON UPGRADE BETWEEN VERSIONS
    #
    #####################################################################################
}


# +-----------------------------------
# |
# | Callback function when verifying whether a given parameter is
# | valid on this release.
# |
# +-----------------------------------
##set_module_property PARAMETER_UPGRADE_CALLBACK my_parameter_upgrade
##
##proc my_parameter_upgrade {ip_core_type version parameters} {
##  send_message Error "XSPI_MC Version Upgrade - Manual Intervention Required: \
##                      For Dual Clock operation, \
##                      Ensure you connect the Avalon clock to the third port on the PLL ( instead of the fourth one)."
##
##}

#-------------------------------------------------------------------------------
#set display group
#-------------------------------------------------------------------------------
proc proc_set_display_group {NAME GROUP EXPERIMENTAL DISPLAY_NAME args} {
    add_display_item        $GROUP  $NAME               parameter
    set_parameter_property  $NAME   "DISPLAY_NAME"      "$DISPLAY_NAME"
    set display_message     "$args"
    # only show those settings in debug mode
    if { "$EXPERIMENTAL" == "1" } {
        set_parameter_property  $NAME   "STATUS"        "EXPERIMENTAL"
        set_parameter_property  $NAME   "VISIBLE"       false
    } else {
        set_parameter_property  $NAME   "VISIBLE"       true
    }

    if { [ expr { "DES_$args" != "DES_" } ] } {
        set_parameter_property  $NAME   "DESCRIPTION"   "[ join $display_message ]"
    }
}


#-------------------------------------------------------------------------------
#function : add parameter
#-------------------------------------------------------------------------------
proc proc_add_parameter {NAME TYPE DEFAULT UNITS IS_DERIVED GROUP} {
    add_parameter          $NAME  $TYPE
    set_parameter_property $NAME AFFECTS_ELABORATION    true                       ;# Set AFFECTS_ELABORATION to false for parameters that do not affect the external interface of the module.
    set_parameter_property $NAME AFFECTS_VALIDATION     true                       ;# The AFFECTS_VALIDATION property marks whether a parameter's value is used to set derived parameters, and whether the value affects validation messages.
    set_parameter_property $NAME AFFECTS_GENERATION     true                       ;# Set AFFECTS_GENERATION to false if the value of a parameter does not change the results of fileset generation.
    set_parameter_property $NAME HDL_PARAMETER          false                      ;# When true, the parameter must be passed to the HDL IP component description. The default value is false.
    set_parameter_property $NAME DERIVED                $IS_DERIVED                ;# When true, indicates that the parameter value can only be set by the IP component, and cannot be set by the user.
    set_parameter_property $NAME ENABLED                true                       ;# When false, the parameter is disabled, meaning that it is displayed, but greyed out, indicating that it is not editable on the parameter editor.
    set_parameter_property $NAME DEFAULT_VALUE          $DEFAULT
    set_parameter_property $NAME NEW_INSTANCE_VALUE     $DEFAULT
    set_parameter_property $NAME UNITS                  $UNITS                     ;# This is the GUI label that appears to the right of the parameter.
}


#-------------------------------------------------------------------------------
#function : add hdl parameter
#-------------------------------------------------------------------------------
proc proc_add_hdl_parameter {NAME TYPE DEFAULT} {
    add_parameter          $NAME  $TYPE
    set_parameter_property $NAME  AFFECTS_GENERATION    false                      ;# Set AFFECTS_GENERATION to false if the value of a parameter does not change the results of fileset generation.
    set_parameter_property $NAME  AFFECTS_ELABORATION   false                      ;# Set AFFECTS_ELABORATION to false for parameters that do not affect the external interface of the module.
    set_parameter_property $NAME  AFFECTS_VALIDATION    false                      ;# The AFFECTS_VALIDATION property marks whether a parameter's value is used to set derived parameters, and whether the value affects validation messages.
    set_parameter_property $NAME  HDL_PARAMETER         true                       ;# When true, the parameter must be passed to the HDL IP component description. The default value is false.
    set_parameter_property $NAME  DERIVED               true                       ;# When true, indicates that the parameter value can only be set by the IP component, and cannot be set by the user.
    set_parameter_property $NAME  DEFAULT_VALUE         $DEFAULT
    set_parameter_property $NAME  NEW_INSTANCE_VALUE    $DEFAULT
    set_parameter_property $NAME  VISIBLE               true                       ;# Indicates whether or not to display the parameter in the parameterization GUI.
    set_parameter_property $NAME  ENABLED               false                      ;# When false, the parameter is disabled, meaning that it is displayed, but greyed out, indicating that it is not editable on the parameter editor.
    set_parameter_property $NAME  GROUP                 "Derived Parameters"       ;# Controls the layout of parameters in GUI
    set_parameter_property $NAME  DISPLAY_NAME          $NAME
}

#-------------------------------------------------------------------------------
#function : add avalon slave
#-------------------------------------------------------------------------------

proc proc_add_avalon_slave {NAME IS_MEM} {
    add_interface             $NAME  avalon                slave
    set_interface_property    $NAME  addressUnits          WORDS
    set_interface_property    $NAME  bitsPerSymbol         8
    set_interface_property    $NAME  bridgedAddressOffset  0
    set_interface_property    $NAME  burstcountUnits       WORDS
    set_interface_property    $NAME  alwaysBurstMaxBurst   {0}
    set_interface_property    $NAME  constantBurstBehavior {0}
    set_interface_property    $NAME  holdTime              {0}
    set_interface_property    $NAME  setupTime             {0}
    set_interface_property    $NAME  writeLatency          {0}
    set_interface_property    $NAME  explicitAddressSpan   0
    set_interface_property    $NAME  timingUnits           Cycles
    set_interface_property    $NAME  isMemoryDevice        $IS_MEM

    set_interface_property    $NAME  EXPORT_OF             ""
    set_interface_property    $NAME  PORT_NAME_MAP         ""
    set_interface_property    $NAME  CMSIS_SVD_VARIABLES   ""
    set_interface_property    $NAME  SVD_ADDRESS_GROUP     ""
}

#-------------------------------------------------------------------------------
#Add skew parameters
#-------------------------------------------------------------------------------
proc proc_add_dq_dqs_skew_param {dev } {

add_display_item "Memory RWDS-DQ SKEW Configuration"  GUI_CH${dev}_DQ_DQS_SKEW     PARAMETER "" ;# FPGA board
add_display_item "Memory RWDS-DQ SKEW Configuration"  GUI_CH${dev}_DQ_DQS_SKEW_MAN PARAMETER "" ;# FPGA board


proc_add_parameter          GUI_CH${dev}_DQ_DQS_SKEW          integer 800 picoseconds true "Memory RWDS-DQ SKEW Configuration"
set_parameter_property      GUI_CH${dev}_DQ_DQS_SKEW          DISPLAY_NAME  "DQ-DQS skew on channel ${dev} in ps"
set_parameter_property      GUI_CH${dev}_DQ_DQS_SKEW          DESCRIPTION   "DQ-DQS skew on channel ${dev} in ps"
set_parameter_property      GUI_CH${dev}_DQ_DQS_SKEW          ENABLED        true
set_parameter_property      GUI_CH${dev}_DQ_DQS_SKEW          VISIBLE        true

proc_add_parameter          GUI_CH${dev}_DQ_DQS_SKEW_MAN      integer 800 picoseconds false "Memory RWDS-DQ SKEW Configuration"
set_parameter_property      GUI_CH${dev}_DQ_DQS_SKEW_MAN      DISPLAY_NAME  "M DQ-DQS skew on channel ${dev} in ps"
set_parameter_property      GUI_CH${dev}_DQ_DQS_SKEW_MAN      DESCRIPTION   "M DQ-DQS skew on channel ${dev} in ps"
set_parameter_property      GUI_CH${dev}_DQ_DQS_SKEW_MAN      ENABLED        true
set_parameter_property      GUI_CH${dev}_DQ_DQS_SKEW_MAN      VISIBLE        false


}

#-------------------------------------------------------------------------------
#procedure : proc_add_avalon_conduit
#-------------------------------------------------------------------------------

proc proc_add_avalon_conduit {NAME SLAVE_TYPE PendReads} {

        add_interface_port     $NAME  i_${NAME}_addr            address         Input   g_${NAME}_addr_width
        add_interface_port     $NAME  i_${NAME}_burstcount      burstcount      Input   g_${NAME}_burstcount_width
        add_interface_port     $NAME  o_${NAME}_wait_request    waitrequest     Output  1


    if {$SLAVE_TYPE != "AV_READ_ONLY"} {
        add_interface_port     $NAME  i_${NAME}_do_wr           write           Input   1
        add_interface_port     $NAME  i_${NAME}_byteenable      byteenable      Input   g_${NAME}_av_numsymbols
        add_interface_port     $NAME  i_${NAME}_wdata           writedata       Input   g_${NAME}_data_width

        set_interface_property $NAME  writeWaitStates                    {0}
        set_interface_property $NAME  writeWaitTime                      {0}
        set_interface_property $NAME  maximumPendingWriteTransactions    {0}    ; # This value is only used with Avalon Response codes to Write operations.  Typically, this value is 0 in our IP.
    }

    if {$SLAVE_TYPE != "AV_WRITE_ONLY"} {
        add_interface_port     $NAME  i_${NAME}_do_rd           read            Input   1
        add_interface_port     $NAME  o_${NAME}_rdata           readdata        Output  g_${NAME}_data_width
        add_interface_port     $NAME  o_${NAME}_rdata_valid     readdatavalid   Output  1
        add_interface_port     $NAME  o_${NAME}_resp            response        Output  2

        set_interface_property $NAME  maximumPendingReadTransactions     $PendReads  ; # This value is always 1, unless we have an advanced IP that is literally processing 2 or more read transactions concurrently within its pipeline.
        set_interface_property $NAME  readLatency                        {0}  ; # This value is always zero for pipelined interfaces.
        set_interface_property $NAME  readWaitTime                       {0}
    }
}

#-------------------------------------------------------------------------------
#function : Device information Menu
#-------------------------------------------------------------------------------
proc proc_add_dev_info {dev  } {

    add_display_item "" "Device ${dev} Info" GROUP tab

    add_display_item "Device ${dev} Info" "Device ${dev} Parameters"  GROUP ""
    add_display_item "Device ${dev} Info" "Device ${dev} Timings"     GROUP ""

    add_display_item "Device ${dev} Parameters"      GUI_DEV${dev}_NAME         PARAMETER ""
    add_display_item "Device ${dev} Parameters"      GUI_DEV${dev}_TYPE         PARAMETER ""
    add_display_item "Device ${dev} Parameters"      GUI_DEV${dev}_IS_FLASH     PARAMETER ""
    add_display_item "Device ${dev} Parameters"      GUI_DEV${dev}_IS_XSPI      PARAMETER ""
    add_display_item "Device ${dev} Parameters"      GUI_DEV${dev}_SIZE         PARAMETER ""
    add_display_item "Device ${dev} Parameters"      GUI_DEV${dev}_SPEED        PARAMETER ""
    add_display_item "Device ${dev} Parameters"      GUI_DEV${dev}_DQ_WIDTH     PARAMETER ""
    add_display_item "Device ${dev} Parameters"      GUI_DEV${dev}_WRAP_SUPPORT PARAMETER ""
    add_display_item "Device ${dev} Parameters"      GUI_DEV${dev}_NON_DEFAULT  PARAMETER ""


    add_display_item "Device ${dev} Timings"         GUI_DEV${dev}_T_ACC        PARAMETER ""
    add_display_item "Device ${dev} Timings"         GUI_DEV${dev}_T_RWR        PARAMETER ""
    add_display_item "Device ${dev} Timings"         GUI_DEV${dev}_T_CSS        PARAMETER ""
    add_display_item "Device ${dev} Timings"         GUI_DEV${dev}_T_CSH        PARAMETER ""


    #----------------------------------------------------------
    #Memory device info
    #----------------------------------------------------------
    proc_add_parameter     GUI_DEV${dev}_NAME         String "No device configured" "" true  "Device ${dev} Parameters"
    set_parameter_property GUI_DEV${dev}_NAME         DISPLAY_NAME "Device" ;
    set_parameter_property GUI_DEV${dev}_NAME         DESCRIPTION  \
        "The current configuration of the Memory Memory controller for this chip select.\
        A Memory device may be physically connected to this chip select, but not configured by the XSPI_MC instance.\
        In which case the XSPI_MC will never issue memory transfer requests to the Memory device connected to this chip select."

    proc_add_parameter     GUI_DEV${dev}_SIZE         Integer 0 Megabytes true  "Device ${dev} Parameters"
    set_parameter_property GUI_DEV${dev}_SIZE         DISPLAY_NAME "Device storage capacity" ;
    set_parameter_property GUI_DEV${dev}_SIZE         DESCRIPTION  "Storage capacity of the configured device"

    proc_add_parameter     GUI_DEV${dev}_DQ_WIDTH     Integer 0 "" true  "Device ${dev} Parameters"
    set_parameter_property GUI_DEV${dev}_DQ_WIDTH     DISPLAY_NAME "Device DQ data width" ;
    set_parameter_property GUI_DEV${dev}_DQ_WIDTH     DESCRIPTION  "Device DQ data width"

    proc_add_parameter     GUI_DEV${dev}_SPEED        Integer 0 Megahertz true  "Device ${dev} Parameters"
    set_parameter_property GUI_DEV${dev}_SPEED        DISPLAY_NAME "Device Speed Grade" ;
    set_parameter_property GUI_DEV${dev}_SPEED        DESCRIPTION  "Maximum Device Speed supported by the configured device"

    proc_add_parameter     GUI_DEV${dev}_TYPE         String  "None" "" true  "Device ${dev} Parameters"
    set_parameter_property GUI_DEV${dev}_TYPE         DISPLAY_NAME "Memory Type" ;
    set_parameter_property GUI_DEV${dev}_TYPE         DESCRIPTION  "Memory Type"

    proc_add_parameter     GUI_DEV${dev}_WRAP_SUPPORT Integer 0 "" true  "Device ${dev} Parameters"
    set_parameter_property GUI_DEV${dev}_WRAP_SUPPORT DISPLAY_NAME "Device Wrap Support" ;
    set_parameter_property GUI_DEV${dev}_WRAP_SUPPORT DESCRIPTION  "Device Wrap Support"


    proc_add_parameter     GUI_DEV${dev}_IS_FLASH  Integer 0 "" true  "Device ${dev} Configuration"
    set_parameter_property GUI_DEV${dev}_IS_FLASH  DISPLAY_NAME "Is this Nonvolatile Flash ?" ;
    set_parameter_property GUI_DEV${dev}_IS_FLASH  VISIBLE          false ;

    proc_add_parameter     GUI_DEV${dev}_IS_XSPI   Integer 0 "" true  "Device ${dev} Configuration"
    set_parameter_property GUI_DEV${dev}_IS_XSPI   DISPLAY_NAME "Is this xSPI device ?" ;
    set_parameter_property GUI_DEV${dev}_IS_XSPI   VISIBLE      false ;


    proc_add_parameter     GUI_DEV${dev}_NON_DEFAULT  boolean true "" true  "Device ${dev} Configuration"
    set_parameter_property GUI_DEV${dev}_NON_DEFAULT  DISPLAY_NAME "Non-default configuration settings are programmed after Power-Up" ;

    #----------------------------------------------------------
    #Memory device timing
    #----------------------------------------------------------

    add_display_item "Device ${dev} Parameters"  GUI_DEV${dev} PARAMETER ""

    proc_add_parameter     GUI_DEV${dev}_T_ACC          Integer 0 Cycles true  "Device ${dev} Timings"
    set_parameter_property GUI_DEV${dev}_T_ACC          DISPLAY_NAME "Tacc" ;
    set_parameter_property GUI_DEV${dev}_T_ACC          DESCRIPTION  "Initial Latency. Please refer to the Memory specifications for more details."

    proc_add_parameter     GUI_DEV${dev}_T_RWR          Integer 0 Cycles true  "Device ${dev} Timings"
    set_parameter_property GUI_DEV${dev}_T_RWR          DISPLAY_NAME "Tcshi - Trwr" ;
    set_parameter_property GUI_DEV${dev}_T_RWR          DESCRIPTION  "Read write recovery. Please refer to the Memory specifications for more details."

    proc_add_parameter     GUI_DEV${dev}_T_CSS          Integer 0 Cycles true  "Device ${dev} Timings"
    set_parameter_property GUI_DEV${dev}_T_CSS          DISPLAY_NAME "Tcss" ;
    set_parameter_property GUI_DEV${dev}_T_CSS          DESCRIPTION  "Tcss. Please refer to the Memory specifications for more details."

    proc_add_parameter     GUI_DEV${dev}_T_CSH          Integer 0 Cycles true  "Device ${dev} Timings"
    set_parameter_property GUI_DEV${dev}_T_CSH          DISPLAY_NAME "Tcsh" ;
    set_parameter_property GUI_DEV${dev}_T_CSH          DESCRIPTION  "Tcsh. Please refer to the Memory specifications for more details."

}

#-------------------------------------------------------------------------------
#function : Device Timing Menu
#-------------------------------------------------------------------------------

proc proc_set_device_info {dev } {

    # -----------------------------------------------------------------
    # Get Device 0 parameters
    # -----------------------------------------------------------------

    #
    # set what paraeters are visible
    #
    if {$dev == 0} {
       set v_dev_name           "none"
       set v_dev_type           0
       set v_dev_speed          100
       set v_dev_size           0
       set v_dev_dq_width       8
       set v_dev_config         0x00000000
       set v_dev_timing         0x00000000
       set v_dev_non_default      0
       set v_dev_xspi_en          0
       set v_dev_wrap_en          1


       set_parameter_property     GUI_DEV${dev}_TYPE         VISIBLE false
       set_parameter_property     GUI_DEV${dev}_SIZE         VISIBLE false
       set_parameter_property     GUI_DEV${dev}_SPEED        VISIBLE false
       set_parameter_property     GUI_DEV${dev}_DQ_WIDTH     VISIBLE false
       set_parameter_property     GUI_DEV${dev}_WRAP_SUPPORT VISIBLE false
       set_parameter_property     GUI_DEV${dev}_NON_DEFAULT  VISIBLE false
       set_parameter_property     GUI_DEV${dev}_T_CSS        VISIBLE false
       set_parameter_property     GUI_DEV${dev}_T_CSH        VISIBLE false
       set_parameter_property     GUI_DEV${dev}_T_RWR        VISIBLE false
       set_parameter_property     GUI_DEV${dev}_T_ACC        VISIBLE false
       set_parameter_property     GUI_DEV${dev}_T_ACC        VISIBLE false
    } else {

    #++++++++++++++++++++++++++++++
    # Get Device Parameters
    #++++++++++++++++++++++++++++++
       set v_dev1_model [get_parameter_value GUI_DEV1_MODEL]


       set v_dev_name           $v_dev1_model
       set v_dev_type           1
       set v_dev_speed          133
       set v_dev_size           128
       set v_dev_dq_width       8
       set v_dev_config         0x00201071
       set v_dev_timing         0x0A0A0411
       set v_dev_non_default    1
       set v_dev_xspi_en        0
       set v_dev_wrap_en        0


       set_parameter_property     GUI_DEV${dev}_TYPE         VISIBLE true
       set_parameter_property     GUI_DEV${dev}_SIZE         VISIBLE true
       set_parameter_property     GUI_DEV${dev}_SPEED        VISIBLE true
       set_parameter_property     GUI_DEV${dev}_DQ_WIDTH     VISIBLE true
       set_parameter_property     GUI_DEV${dev}_WRAP_SUPPORT VISIBLE true
       set_parameter_property     GUI_DEV${dev}_NON_DEFAULT  VISIBLE true
       set_parameter_property     GUI_DEV${dev}_T_CSS        VISIBLE true
       set_parameter_property     GUI_DEV${dev}_T_CSH        VISIBLE true
       set_parameter_property     GUI_DEV${dev}_T_RWR        VISIBLE true
       set_parameter_property     GUI_DEV${dev}_T_ACC        VISIBLE true
       set_parameter_property     GUI_DEV${dev}_T_ACC        VISIBLE true
    }

    #
    # CFG Parameters
    #
       set_parameter_value     GUI_DEV${dev}_NAME         $v_dev_name
       set_parameter_value     GUI_DEV${dev}_TYPE         $v_dev_type
       set_parameter_value     GUI_DEV${dev}_SIZE         [expr $v_dev_size/8]
       set_parameter_value     GUI_DEV${dev}_SPEED        $v_dev_speed
       set_parameter_value     GUI_DEV${dev}_DQ_WIDTH     $v_dev_dq_width
       set_parameter_value     GUI_DEV${dev}_WRAP_SUPPORT $v_dev_wrap_en
       set_parameter_value     GUI_DEV${dev}_NON_DEFAULT  $v_dev_non_default
       set_parameter_value     GUI_DEV${dev}_IS_XSPI      $v_dev_xspi_en


    #
    #check whether device is flash
    #
    if {($v_dev_config & 0x1) == 0} {
       set_parameter_value     GUI_DEV${dev}_IS_FLASH  1
    } else {
       set_parameter_value     GUI_DEV${dev}_IS_FLASH  0
    }


    #
    # Timing Parameters
    #
    set_parameter_value     GUI_DEV${dev}_T_CSS    [expr ($v_dev_timing  >> 0 ) & 0xf]
    set_parameter_value     GUI_DEV${dev}_T_CSH    [expr ($v_dev_timing  >> 4 ) & 0xf]
    set_parameter_value     GUI_DEV${dev}_T_RWR    [expr (($v_dev_timing >> 8 ) + 3) & 0x1F]
    set_parameter_value     GUI_DEV${dev}_T_ACC    [expr ($v_dev_timing  >> 16) & 0x1f]
}

#-------------------------------------------------------------------------------
#function : IAVS0 configuration Menu
#-------------------------------------------------------------------------------
proc proc_add_iavs_config {NAME } {
    add_display_item "" "${NAME} Configuration" GROUP tab


    add_display_item "${NAME} Configuration" "${NAME}: Ingress Avalon port stage" GROUP ""
    add_display_item "${NAME} Configuration" "${NAME}: Ingress Avalon address/data" GROUP ""
    add_display_item "${NAME} Configuration" "${NAME}: Burst converter and address decoder stage" GROUP ""
    add_display_item "${NAME} Configuration" "${NAME}: Ingress Avalon return stage" GROUP ""

    add_display_item "${NAME}: Ingress Avalon port stage"                 GUI_${NAME}_WRITE_MODE          PARAMETER ""
    add_display_item "${NAME}: Ingress Avalon port stage"                 GUI_${NAME}_BYTEENABLE          PARAMETER ""
    add_display_item "${NAME}: Ingress Avalon port stage"                 GUI_${NAME}_PORT_MODE           PARAMETER ""
    add_display_item "${NAME}: Ingress Avalon port stage"                 GUI_${NAME}_REG_WDATA           PARAMETER ""

    add_display_item "${NAME}: Ingress Avalon address/data"               GUI_${NAME}_ADDR_WIDTH          PARAMETER ""
    add_display_item "${NAME}: Ingress Avalon address/data"               GUI_${NAME}_ADDR_UNITS          PARAMETER ""
    add_display_item "${NAME}: Ingress Avalon address/data"               GUI_${NAME}_DATA_WIDTH          PARAMETER ""

    add_display_item "${NAME}: Burst converter and address decoder stage" GUI_${NAME}_MAX_BURST_IN_WORDS  PARAMETER ""
    add_display_item "${NAME}: Burst converter and address decoder stage" GUI_${NAME}_LINEWRAP_BURST      PARAMETER ""
    add_display_item "${NAME}: Burst converter and address decoder stage" GUI_${NAME}_BURST_ON_BURST_BOUNDARIES_ONLY PARAMETER ""
    add_display_item "${NAME}: Burst converter and address decoder stage" GUI_${NAME}_BURST_ON_BURST_BOUNDARIES_AUTO PARAMETER ""

    add_display_item "${NAME}: Ingress Avalon return stage"                GUI_${NAME}_REG_RDATA           PARAMETER ""
    add_display_item "${NAME}: Ingress Avalon return stage"                GUI_${NAME}_USE_RESPONSE        PARAMETER ""

    proc_add_parameter     GUI_${NAME}_WRITE_MODE BOOLEAN true "" false  "AV Configuration"
    set_parameter_property GUI_${NAME}_WRITE_MODE         DISPLAY_NAME "Enable Avalon  write  capability" ;
    set_parameter_property GUI_${NAME}_WRITE_MODE         DESCRIPTION  \
        "Enable the Avalon  write  signals on this slave interface."

    proc_add_parameter     GUI_${NAME}_BYTEENABLE BOOLEAN true "" false  "AV Configuration"
    set_parameter_property GUI_${NAME}_BYTEENABLE DISPLAY_NAME "Enable Avalon  byte-enable  capability" ;# This is the GUI label that appears to the left of this parameter.
    set_parameter_property GUI_${NAME}_BYTEENABLE DESCRIPTION \
        "Enable the Avalon  byte-enable  signals on this slave interface. \
        The Nios II instruction bus master does NOT employ byte-enable signals. \
        In contrast, the Nios II data bus master does employs byte-enable signals."

    proc_add_parameter     GUI_${NAME}_PORT_MODE String "Read/Write" "" true  "AV Configuration"
    set_parameter_property GUI_${NAME}_PORT_MODE DISPLAY_NAME "Access capabilities"  ;# This is the GUI label that appears to the left of this parameter.
    set_parameter_property GUI_${NAME}_PORT_MODE DESCRIPTION "Informs the developer if this ingress avalon slave port supports read and/or write capabilities"

    proc_add_parameter     GUI_${NAME}_REG_WDATA BOOLEAN false "" false  "AV Configuration"
    set_parameter_property GUI_${NAME}_REG_WDATA         DISPLAY_NAME "Register Avalon write data path (generally recommended for high clock speed designs)" ;
    set_parameter_property GUI_${NAME}_REG_WDATA         DESCRIPTION  \
        "When enabled, the value of the Avalon wdata signal is cached in a 32-bit wide register.\
        Registration of the write signal can improve place-and-route results and may enable higher clock speed designs.\
        Registration of the write signal does NOT reduce write memory transfer request performance.\
        Turn write registration off to reduce circuit area requirements.\
        High Avalon clock-speed designs typically enable registration of the  wdata  signal, where as lower-clock speed Avalon designs typically do not."

    proc_add_parameter     GUI_${NAME}_REG_RDATA BOOLEAN false "" false  "AV Configuration"
    set_parameter_property GUI_${NAME}_REG_RDATA         DISPLAY_NAME "Register Avalon read data path (sometimes used to increase top clock speeds)" ;
    set_parameter_property GUI_${NAME}_REG_RDATA         DESCRIPTION  \
       "When enabled, the Avalon  rdata  signal is driven by a 32-bit wide register.\
        Registration can improve place-and-route results and may enable higher clock speed designs.\
        Registration delays the read data on the  rdata  signal by 1 clock cycle.\
        Turn read registration off to reduce circuit area requirements and improve software performance.\
        Typically most designs will NOT need to register the  rdata  signal."

    proc_add_parameter     GUI_${NAME}_USE_RESPONSE BOOLEAN false "" false  "AV Configuration"
    set_parameter_property GUI_${NAME}_USE_RESPONSE         DISPLAY_NAME "Use Avalon transaction responses" ;
#    set_parameter_property GUI_${NAME}_USE_RESPONSE         DESCRIPTION  \
#        "When enabled, the Avalon response signal will be added to the slave interface on this port. If you do not know why you need this, do not enable this capability."
    set_parameter_property GUI_${NAME}_USE_RESPONSE         DESCRIPTION  \
        "Please contact S/Labs if you require the ability to enable the Avalon response signal to the slave interface on this port. The vast majority of projects do not require this capability."
    set_parameter_property GUI_${NAME}_USE_RESPONSE         ENABLED  false


    proc_add_parameter     GUI_${NAME}_MAX_BURST_IN_WORDS INTEGER 8 "" false  "AV Configuration"

    set_parameter_property GUI_${NAME}_MAX_BURST_IN_WORDS ALLOWED_RANGES {1,8,16,32,64,128}
    set_parameter_property GUI_${NAME}_MAX_BURST_IN_WORDS DISPLAY_NAME "maxBurstSize (in words)"  ;# This is the GUI label that appears to the left of this parameter.
    set_parameter_property GUI_${NAME}_MAX_BURST_IN_WORDS DESCRIPTION \
        "Select the maximum burst length of read and/or write burst memory transfer requests on this port in words. \
        For best performance and lowest circuit area implementations, the value of maxBurstSize must be set to the value of the largest maxBurstSize of all Avalon bus masters interfaces that are connected to this slave interface."

    proc_add_parameter     GUI_${NAME}_LINEWRAP_BURST    BOOLEAN false "" false "AV Configuration"
    set_parameter_property GUI_${NAME}_LINEWRAP_BURST    ALLOWED_RANGES {"0:false" "1:true"}
    set_parameter_property GUI_${NAME}_LINEWRAP_BURST    DISPLAY_NAME "linewrapBursts" ;# This is the GUI label that appears to the left of this parameter.
    set_parameter_property GUI_${NAME}_LINEWRAP_BURST    DESCRIPTION \
        "If one or more of the Altera Avalon bus master interfaces connected to this slave port employs linewrapBursts=true, then set the \
        linewrapBursts of this slave port to true.  If none of the Altera Avalon bus master interfaces connected to this slave port employ \
        linewrapBursts=true, then we recommend setting the value of linewrapBursts for this slave port to false. \
        In Nios II applications, the Nios II/f L1 instruction cache bus master employs linewrapBursts=true, where as the L1 data cache bus master employs linewrapBursts=false. \
        In contrast, the Nios II/e does not have any internal L1 caches.\
        For Nios II/e applications we strongly recommend S/Labs range of burst capable caches, including our CA-CMS-T003 product."

    proc_add_parameter     GUI_${NAME}_BURST_ON_BURST_BOUNDARIES_ONLY    BOOLEAN false "" false "AV Configuration"
    set_parameter_property GUI_${NAME}_BURST_ON_BURST_BOUNDARIES_ONLY    ALLOWED_RANGES {"0:false" "1:true"}
    set_parameter_property GUI_${NAME}_BURST_ON_BURST_BOUNDARIES_ONLY    DISPLAY_NAME "burstOnBurstBoundariesOnly" ;# This is the GUI label that appears to the left of this parameter.
    set_parameter_property GUI_${NAME}_BURST_ON_BURST_BOUNDARIES_ONLY    DESCRIPTION \
        "Set the value of burstOnBurstBoundariesOnly=true for the slave port when all bus master interfaces connected to this port set the value of their burstOnBurstBoundariesOnly=true. \
        Otherwise, set the value of burstOnBurstBoundariesOnly to false for the slave port.  Setting burstOnBurstBoundariesOnly=true results in lower-circuit area implementations.\
        If you do not know which value to use, set burstOnBurstBoundaries=false."

    proc_add_parameter     GUI_${NAME}_BURST_ON_BURST_BOUNDARIES_AUTO    BOOLEAN true "" true "AV Configuration"
    set_parameter_property GUI_${NAME}_BURST_ON_BURST_BOUNDARIES_AUTO    ALLOWED_RANGES {"0:false" "1:true"}
    set_parameter_property GUI_${NAME}_BURST_ON_BURST_BOUNDARIES_AUTO    DISPLAY_NAME "burstOnBurstBoundariesOnly" ;# This is the GUI label that appears to the left of this parameter.
    set_parameter_property GUI_${NAME}_BURST_ON_BURST_BOUNDARIES_AUTO    DESCRIPTION \
        "Set the value of burstOnBurstBoundariesOnly=true for the slave port when all bus master interfaces connected to this port set the value of their burstOnBurstBoundariesOnly=true. \
        Otherwise, set the value of burstOnBurstBoundariesOnly to false for the slave port.  Setting burstOnBurstBoundariesOnly=true results in lower-circuit area implementations."

    proc_add_parameter     GUI_${NAME}_DATA_WIDTH INTEGER 32 "bits" false  "AV Configuration"
    set_parameter_property GUI_${NAME}_DATA_WIDTH         ALLOWED_RANGES {32}
    set_parameter_property GUI_${NAME}_DATA_WIDTH         DISPLAY_NAME "Word width" ;# This is the GUI label that appears to the left of this parameter.
    set_parameter_property GUI_${NAME}_DATA_WIDTH         DESCRIPTION "The data-path width of this Avalon slave interface"

    proc_add_parameter     GUI_${NAME}_ADDR_WIDTH INTEGER 10 "bits" true "AV Configuration"
    set_parameter_property GUI_${NAME}_ADDR_WIDTH         DISPLAY_NAME "Address width" ;# This is the GUI label that appears to the left of this parameter.
    set_parameter_property GUI_${NAME}_ADDR_WIDTH         DESCRIPTION "The width of the  address signal  of this Avalon slave interface"

    proc_add_parameter     GUI_${NAME}_ADDR_UNITS String "Words" "" false "AV Configuration"
    set_parameter_property GUI_${NAME}_ADDR_UNITS         DISPLAY_NAME "Address units" ;# This is the GUI label that appears to the left of this parameter.
    set_parameter_property GUI_${NAME}_ADDR_UNITS         DESCRIPTION  "Address units"
    set_parameter_property GUI_${NAME}_ADDR_UNITS         ENABLED      false ;

}
#-------------------------------------------------------------------------------
# connection point Conduit
#-------------------------------------------------------------------------------
proc proc_Add_Memory_Conduit_IO {v_num_chipselect } {


    set_interface_property     i_hbus_clk_0        ENABLED true
    set_interface_property     i_hbus_clk_90       ENABLED true



    #
    #Memory Signal Interface
    set_interface_property Conduit_IO associatedClock     clock
    set_interface_property Conduit_IO associatedReset     ""
    set_interface_property Conduit_IO ENABLED             true
    set_interface_property Conduit_IO EXPORT_OF           ""
    set_interface_property Conduit_IO PORT_NAME_MAP       ""
    set_interface_property Conduit_IO CMSIS_SVD_VARIABLES ""
    set_interface_property Conduit_IO SVD_ADDRESS_GROUP   ""

    #Memory signals
    add_interface_port Conduit_IO MB_CLK0    MB0_CLK0     Output 1
    add_interface_port Conduit_IO MB_CLK0n   MB0_CLK0n    Output 1
    add_interface_port Conduit_IO MB_CS1n    MB0_CS1n     Output 1
    add_interface_port Conduit_IO MB_RWDS    MB0_RWDS     Bidir  g_dqs_width
    add_interface_port Conduit_IO MB_DQ      MB0_DQ       Bidir  g_dqin_width

    add_interface_port Conduit_IO MB_RSTn    MB0_RSTn     Output 1



      set_port_property MB_CLK0          TERMINATION false
      set_port_property MB_CLK0n         TERMINATION false
      set_port_property MB_CS1n          TERMINATION false
      set_port_property MB_RWDS          TERMINATION false
      set_port_property MB_DQ            TERMINATION false

}


#######################################################################################################################
#populate fragment_list procedure

proc populate_fragment_list {signal_name signal_width mst} {
  set signal_list ""
  for { set z 0 } { $z<$signal_width} { incr z } {
    set z2 [expr $signal_width * ($mst+1) - $z - 1 ]
    append signal_list  "$signal_name@$z2 "
  }

  return $signal_list
}

proc populate_fragment_list2 {signal_name signal_width signal_index} {
  set signal_list ""

  for { set z 0 } { $z<$signal_width} { incr z } {
    set z2 [expr ($signal_width + $signal_index) - $z - 1 ]
    append signal_list  "$signal_name@$z2 "
  }

  return $signal_list
}
