#-----------------------------------------------------------
#get top level IO name
#-----------------------------------------------------------

proc proc_get_top_level_io_name {io_inst_name } {

   # Get the fanouts of the low-level module
   set fanout_collection [get_fanouts $io_inst_name]

   # Ensure there is only one fanout
   set num_fanouts [get_collection_size $fanout_collection]
   if { 1 != $num_fanouts } {
       return -code error "$io_inst_name fans out to $num_fanouts \
           nodes but must fan out to one."
   }

   # Get the name of the fanout node
   foreach_in_collection fanout_id $fanout_collection { break }
   set fanout_name [get_node_info -name $fanout_id]

   # Ensure the fanout node is an output port
   if { [catch { get_port_info -is_output_port $fanout_id } is_output] } {
       # There was an error - it does not fan out to a port
       return -code error "$io_inst_name fans out to $fanout_name \
           which is not a port"
   } elseif { ! $is_output } {
       # There is no error, but the port is not an output port
       return -code error "$fanout_name is not an output port"
   } else {
       set top_level_io_name $fanout_name
   }

return  $top_level_io_name
}


#-----------------------------------------------------------
# Get Clk connected to pin
#-----------------------------------------------------------
proc proc_get_clk_connected_to_reg { reg_name } {

   if {"device_family" == "Agilex 5"      || "device_family" == "AGILEX 5"   || 
       "device_family" == "Agilex 3"      || "device_family" == "AGILEX 3" } {

      set clk_list [get_clocks -of_objects [get_pins -compatibility_mode "${reg_name}\|clk"]]

       set clk_connected_name  ""

      foreach_in_collection clk_id  $clk_list {
        set clk_connected_name     [get_clock_info -name $clk_id]
        puts "clk_name $clk_connected_name"
      } 
   } else {
      set clk_list           [all_clocks]
      set clk_name           ""
      set clk_connected_name ""
      
      foreach_in_collection clk_id  $clk_list {
        set clk_name     [get_clock_info -name $clk_id]
      
        set check_clk_reg_connection [get_fanouts [get_pins  -compatibility_mode $clk_name] -through [get_pins -comp *${reg_name}|clk]]
      
        if {[get_collection_size $check_clk_reg_connection] > 0} {
          set clk_connected_name $clk_name
        }
      }
   }   
  return $clk_connected_name
}

#-----------------------------------------------------------
#create master clock
#-----------------------------------------------------------

#FPGA clock pin name connected to S/LABS MBMC refrence clk (in_clk)
derive_pll_clocks -create_base_clocks

#-----------------------------------------------------------
#Set clock path
#-----------------------------------------------------------
   #get hyperbus clock
     set hyperbus_clk [proc_get_clk_connected_to_reg "*ModuleName*MBMC_IO*csn_reg_s1_r*"]


   #get core clock in case it operates in Dual Clock Mode
   if {single_clock_mode == "true"} {
     set core_clk "none"
   } else {
     set core_clk [proc_get_clk_connected_to_reg "*ModuleName*MBMC_TOP*U_PWRUP_SYNC*2*"]
   }


#-----------------------------------------------------------
#output clock signal name
#-----------------------------------------------------------

   if {"device_family" == "Agilex 5"      || "device_family" == "AGILEX 5"  || 
       "device_family" == "Agilex 3"      || "device_family" == "AGILEX 3" } {

    set clkp_pin_name  [get_pins -compatibility_mode *ModuleName*U_MBMC_IO*U_CLK0p*|dataout]
    set clkp_mux_name  [get_pins -compatibility_mode *ModuleName*U_MBMC_IO*U_CLK0p*|dataout]

    set clkn_pin_name  [get_pins -compatibility_mode *ModuleName*U_MBMC_IO*U_CLK0n*|dataout]
    set clkn_mux_name  [get_pins -compatibility_mode *ModuleName*U_MBMC_IO*U_CLK0n*|dataout]

    set dqout_mux_name [get_pins -compatibility_mode *ModuleName*U_MBMC_IO*U_DQ*|dataout]

    set rwds_mux_name  [get_pins -compatibility_mode *ModuleName*U_MBMC_IO*U_RWDS*fr_out_data_ddio*dataout]

   } elseif {"device_family" == "ARRIA 10"      || "device_family" == "Arria 10"     ||
       "device_family" == "Cyclone 10 GX" || "device_family" == "CYCLONE 10 GX"||
       "device_family" == "Stratix 10"    || "device_family" == "STRATIX 10"} {
#    set clkp_pin_name  [get_pins -compatibility_mode *ModuleName*U_MBMC_IO*U_CLK0p*|o]
#    set clkp_mux_name  [get_pins -compatibility_mode *ModuleName*U_MBMC_IO*U_CLK0p*muxsel]

    set clkp_pin_name  [get_pins -compatibility_mode *ModuleName*U_MBMC_IO*U_CLK0p*|dataout]
    set clkp_mux_name  [get_pins -compatibility_mode *ModuleName*U_MBMC_IO*U_CLK0p*|dataout]

#    set clkn_pin_name  [get_pins -compatibility_mode *ModuleName*U_MBMC_IO*U_CLK0n*|o]
#    set clkn_mux_name  [get_pins -compatibility_mode *ModuleName*U_MBMC_IO*U_CLK0n*muxsel]

    set clkn_pin_name  [get_pins -compatibility_mode *ModuleName*U_MBMC_IO*U_CLK0n*|dataout]
    set clkn_mux_name  [get_pins -compatibility_mode *ModuleName*U_MBMC_IO*U_CLK0n*|dataout]

#   set dqout_mux_name [get_pins -compatibility_mode *ModuleName*U_MBMC_IO*U_DQ*muxsel]
   set dqout_mux_name [get_pins -compatibility_mode *ModuleName*U_MBMC_IO*U_DQ*|dataout]

#    set rwds_mux_name  [get_pins -compatibility_mode *ModuleName*U_MBMC_IO*U_RWDS*muxsel]
    set rwds_mux_name  [get_pins -compatibility_mode *ModuleName*U_MBMC_IO*U_RWDS*|dataout]

   } elseif {"device_family" == "Max 10"     || "device_family" == "MAX 10" } { 
    set clkp_pin_name  [get_pins -compatibility_mode *ModuleName*U_MBMC_IO*U_CLK0p*|dataout]
    set clkp_mux_name  [get_pins -compatibility_mode *ModuleName*U_MBMC_IO*U_CLK0p*muxsel]

    set clkn_pin_name  [get_pins -compatibility_mode *ModuleName*U_MBMC_IO*U_CLK0n*|dataout]
    set clkn_mux_name  [get_pins -compatibility_mode *ModuleName*U_MBMC_IO*U_CLK0n*muxsel]

    set dqout_mux_name [get_pins -compatibility_mode *ModuleName*U_MBMC_IO*U_DQ*muxsel]

    set rwds_mux_name  [get_pins -compatibility_mode *ModuleName*U_MBMC_IO*U_RWDS*muxsel]


##    set clkout_pin_name  "*|U_IO|U_CLK0|*|*|output_buf.obuf\|o"
##    set clknout_pin_name "*|U_IO|U_CLK0n|*|*|output_buf.obuf\|o"
   } else {
    set clkp_pin_name  [get_pins -compatibility_mode *ModuleName*U_MBMC_IO*U_CLK0p*|dataout]
    set clkp_mux_name  [get_pins -compatibility_mode *ModuleName*U_MBMC_IO*U_CLK0p*muxsel]

    set clkn_pin_name  [get_pins -compatibility_mode *ModuleName*U_MBMC_IO*U_CLK0n*|dataout]
    set clkn_mux_name  [get_pins -compatibility_mode *ModuleName*U_MBMC_IO*U_CLK0n*muxsel]

    set dqout_mux_name [get_pins -compatibility_mode *ModuleName*U_MBMC_IO*U_DQ*muxsel]

    set rwds_mux_name  [get_pins -compatibility_mode *ModuleName*U_MBMC_IO*U_RWDS*muxsel]
   }

#-----------------------------------------------------------
# Board parameters - RWDS input maximum/minimum delay
#-----------------------------------------------------------
#
set dqs_dq_skew_list "dqs_dq_skew_info"



# AN 433: Page 24
#   Altera recommends constraining the maximum data invalid time instead of the
#   minimum data valid time.
#
#   To constrain the maximum data invalid time, you must set
#   up the output minimum delay and output maximum delay constraints. The output
#   minimum delay constraint value is the positive skew requirement, and the output
#   maximum delay constraint is the negative skew requirement. Depending on the
#   operation of your interface, you may have to adjust the constraint values or add
#   exceptions to ensure correct timing analysis, but there are no calculations required to
#   determine the initial output delay values.
#   The output minimum delay shown in Figure 34 corresponds to the minimum tCO
#   requirement, which is the earliest time that data can change after the clock edge.
#   When you constrain the maximum data invalid time, the earliest time that data can
#   change after the clock edge is the positive skew time. The output maximum delay
#   shown in Figure 34 corresponds to the tCO requirement, which is the latest time that
#   data changes after the clock edge. When you constrain the maximum data invalid
#   time, the latest time that data changes occur is skew requirement, which is before the
#   clock edge. To express that time as occurring after the clock edge, you must use the
#   negative slack value.
#   Note:   If you use this approach to constrain the maximum data invalid time and you use the
#           PrimeTime software, you must modify your output maximum and minimum delay
#           values to work around a limitation of the PrimeTime software. Using an output
#           maximum delay value that is less than the corresponding output minimum delay
#           value results in incorrect timing analysis. The following sections describe constraint
#           modifications necessary for each combination of edge capture and alignment. For an
#           appropriate workaround, refer to the section that corresponds to the operation of your
#           interface.
# ...
#   Same-Edge Capture Center-Aligned Output
#   Figure 45 shows the default setup and hold relationships that are analyzed in a
#   same-edge capture, center-aligned output. Red arrows indicate setup relationships,
#   and blue arrows indicate hold relationships.
#   ...
#   The value you use for the maximum and minimum delay exceptions must include the
#   skew between the clocks. In those cases in which skew is negligible, __such as when you
#   use ALTDDIO_OUT megafunctions for both the data and clock outputs, you can use
#   zero for the skew__. You must not use zero for the skew when a PLL output drives
#   directly off chip, for example.
#
set dq_out_max_dly    0.0  ;#CLK-DOUT input maximum delay
set dq_out_min_dly   -0.0  ;#CLK-DOUT input minimim delay


#derive clocks and clock uncertainty
derive_clock_uncertainty

#-----------------------------------------------------------
#get rwds in port names
#-----------------------------------------------------------

set rwds_num_pins  [get_collection_size $rwds_mux_name]

set rwds_in_port_list ""
foreach_in_collection name_id  $rwds_mux_name {
    set pin_name  [get_pin_info -name $name_id]
    set port_name [proc_get_top_level_io_name $pin_name]

    lappend rwds_in_port_list $port_name
}

#-----------------------------------------------------
#get Hbus clk0p out port names
#-----------------------------------------------------------
set clkp_out_ports     [proc_get_top_level_io_name $clkp_mux_name]
set clkp_out_names     [get_ports -no_case -nowarn $clkp_out_ports]
set clkp_out_port_list ""

foreach_in_collection name_id  $clkp_out_names {
    set port_name [get_port_info -name $name_id]
    lappend clkp_out_port_list $port_name
}

#-----------------------------------------------------
#get clkp_out_source pin names
#-----------------------------------------------------
set clkp_out_source      $clkp_pin_name
set clkp_out_source_list ""

foreach_in_collection name_id  $clkp_out_source {
    set pin_name [get_pin_info -name $name_id]
    lappend clkp_out_source_list $pin_name
}


#-----------------------------------------------------
#check whether Clock N is connected
#-----------------------------------------------------------
if { [get_collection_size $clkn_mux_name] < 1} {
   set enable_clkn 0
 }  else {
   set enable_clkn 1
}

if {$enable_clkn == 1} {

#-----------------------------------------------------
#get Hbus clk0n out port names
#-----------------------------------------------------------
  set clkn_out_ports     [proc_get_top_level_io_name $clkn_mux_name]
  set clkn_out_names     [get_ports -no_case -nowarn $clkn_out_ports]
  set clkn_out_port_list ""

  foreach_in_collection name_id  $clkn_out_names {
      set port_name [get_port_info -name $name_id]
      lappend clkn_out_port_list $port_name
  }

#-----------------------------------------------------
#get clkn_out_source pin names
#-----------------------------------------------------
  set clkn_out_source      $clkn_pin_name
  set clkn_out_source_list ""

  foreach_in_collection name_id  $clkn_out_source {
      set pin_name [get_pin_info -name $name_id]
      lappend clkn_out_source_list $pin_name
  }

}

#-----------------------------------------------------
#get dq port names
#-----------------------------------------------------

set dq_pin_list  ""
foreach_in_collection name_id $dqout_mux_name {
    set pin_name    [get_pin_info -name $name_id]
    lappend dq_pin_list $pin_name
}

set dq_size  [llength $dq_pin_list]
set dq_size  [expr $dq_size/$rwds_num_pins]


#
#loop over number of instantiated controllers
for {set mb_cs 0} {$mb_cs < $rwds_num_pins} {incr mb_cs} {

   #
   #set rwds clock pin as either RWDS
   #
   set HB_rwds_in_ports   [lindex $rwds_in_port_list    $mb_cs]
   set MB_clkp_out_ports  [lindex $clkp_out_port_list   $mb_cs]
   set MB_clkp_out_source [lindex $clkp_out_source_list $mb_cs]

   #
   #disable timing attribute if pin is not actually connected
   #
   if {$MB_clkp_out_source == ""} {
     set disable_clk_out_timing 1
   } else {
     set disable_clk_out_timing 0
   }

   set MB_DQ_dqs_skew     [lindex $dqs_dq_skew_list $mb_cs]

   set virt_rwds_clk_name ModuleName_virt_rds_clk${mb_cs}
   set rwds_clk_name      ModuleName_rds_clk${mb_cs}
   set clkout_clk_name    ModuleName_clkout${mb_cs}

##   puts "mb_cs $mb_cs HB_rwds_in_ports $HB_rwds_in_ports virt_rwds_clk_name $virt_rwds_clk_name rwds_clk_name $rwds_clk_name"

   #-----------------------------------------------------------
   #virtual input clock with same phase as real clock due to edge aligned input
   #-----------------------------------------------------------
   create_clock -name $virt_rwds_clk_name -period dqs_clk_freq_in_ns

   #-----------------------------------------------------------
   #Actual RDS clocks
   #-----------------------------------------------------------
   create_clock -name $rwds_clk_name  -period dqs_clk_freq_in_ns ${HB_rwds_in_ports}

   #-----------------------------------------------------------
   #Output Clock -  MB_CLK0-MB_CLK0n
   #-----------------------------------------------------------
   if  {$disable_clk_out_timing==0} {

      create_generated_clock -name $clkout_clk_name   -source ${MB_clkp_out_source}   -divide_by 1 -multiply_by 1 -invert ${MB_clkp_out_ports}

      # Clock Uncertainty is accounted for by the ...pathjitter parameters
      set_clock_uncertainty -to [ get_clocks $clkout_clk_name  ] 0

      if {$enable_clkn == 1} {
         set MB_clkn_out_source [lindex $clkn_out_source_list $mb_cs]
         set MB_clkn_out_ports  [lindex $clkn_out_port_list $mb_cs]
         set clknout_clk_name   ModuleName_clknout${mb_cs}

         create_generated_clock -name $clknout_clk_name  -source ${MB_clkn_out_source}  -divide_by 1 -multiply_by 1 -invert ${MB_clkn_out_ports}

        # Clock Uncertainty is accounted for by the ...pathjitter parameters
        set_clock_uncertainty -to [ get_clocks $clknout_clk_name  ] 0
      }
   }

   #-----------------------------------------------------------
   #RWDS timing
   #-----------------------------------------------------------
   set dq_start_idx [expr $dq_size*$mb_cs]
   set dq_end_idx   [expr $dq_start_idx+$dq_size]

   for {set dq_idx $dq_start_idx} {$dq_idx < $dq_end_idx} {incr dq_idx} {
      set MB_DQ_pin         [lindex $dq_pin_list $dq_idx]
      set MB_DQ_port_name   [proc_get_top_level_io_name $MB_DQ_pin]
      set MB_DQ_port        [get_ports -no_case -nowarn $MB_DQ_port_name]

##      puts "virt_rwds_clk_name $virt_rwds_clk_name MB_DQ_pin $MB_DQ_pin : MB_DQ_port_name $MB_DQ_port_name MB_DQ_port $MB_DQ_port"
      #-----------------------------------------------------------
      #Input Delay
      #-----------------------------------------------------------
      set_input_delay -clock [get_clocks $virt_rwds_clk_name]             -max ${MB_DQ_dqs_skew} ${MB_DQ_port}
      set_input_delay -clock [get_clocks $virt_rwds_clk_name] -clock_fall -max ${MB_DQ_dqs_skew} ${MB_DQ_port} -add_delay

      set_input_delay -clock [get_clocks $virt_rwds_clk_name]             -min -${MB_DQ_dqs_skew} ${MB_DQ_port} -add_delay
      set_input_delay -clock [get_clocks $virt_rwds_clk_name] -clock_fall -min -${MB_DQ_dqs_skew} ${MB_DQ_port} -add_delay

      #-----------------------------------------------------------
      #Output Delay
      #-----------------------------------------------------------
      if  {$disable_clk_out_timing==0} {
         set_output_delay -clock [get_clocks $clkout_clk_name] -min $dq_out_min_dly ${MB_DQ_port}
         set_output_delay -clock [get_clocks $clkout_clk_name] -max $dq_out_max_dly ${MB_DQ_port}
         set_output_delay -clock [get_clocks $clkout_clk_name] -min $dq_out_min_dly ${MB_DQ_port} -clock_fall -add_delay
         set_output_delay -clock [get_clocks $clkout_clk_name] -max $dq_out_max_dly ${MB_DQ_port} -clock_fall -add_delay
      }   

   }

   set_multicycle_path -setup -end -rise_from [get_clocks $virt_rwds_clk_name] -rise_to [get_clocks $rwds_clk_name] 0
   set_multicycle_path -setup -end -fall_from [get_clocks $virt_rwds_clk_name] -fall_to [get_clocks $rwds_clk_name] 0

   set_false_path  -fall_from [get_clocks $virt_rwds_clk_name] -rise_to [get_clocks $rwds_clk_name] -setup
   set_false_path  -rise_from [get_clocks $virt_rwds_clk_name] -fall_to [get_clocks $rwds_clk_name] -setup
   set_false_path  -fall_from [get_clocks $virt_rwds_clk_name] -fall_to [get_clocks $rwds_clk_name] -hold
   set_false_path  -rise_from [get_clocks $virt_rwds_clk_name] -rise_to [get_clocks $rwds_clk_name] -hold


   #-----------------------------------------------------------
   #setting false paths from RWDS to other clocks
   #-----------------------------------------------------------
   set_false_path -from [get_clocks $rwds_clk_name] -to   [get_clocks ${hyperbus_clk}]
   set_false_path -to   [get_clocks $rwds_clk_name] -from [get_clocks ${hyperbus_clk}]
}

#-----------------------------------------------------------
#setting false paths from Core clock to hyperbus clock
#-----------------------------------------------------------
  if {single_clock_mode == "false"} {

     set_false_path  -from  [get_clocks ${hyperbus_clk}]  -to  [get_clocks ${core_clk}]
     set_false_path  -from  [get_clocks ${core_clk}]      -to  [get_clocks ${hyperbus_clk}]
  }


#-----------------------------------------------------------
#On Arria 10, C10GX the oe is registered
#-----------------------------------------------------------

 if {"device_family" == "ARRIA 10"      || "device_family" == "Arria 10"      || 
     "device_family" == "Cyclone 10 GX" || "device_family" == "CYCLONE 10 GX" ||
     "device_family" == "Stratix 10"    || "device_family" == "STRATIX 10" ||
     "device_family" == "Agilex 5"      || "device_family" == "AGILEX 5"   || 
     "device_family" == "Agilex 3"      || "device_family" == "AGILEX 3"} {
    set_multicycle_path -from {*ModuleName**U_MBMC_TOP|*|mbmc_io_dq_tri_en} -to {*ModuleName*U_MBMC_IO|*U_DQ|*.altera_gpio_bit_i|oe_path.oe_path_fr.oe_reg}   -setup -end 2
    set_multicycle_path -from {*ModuleName**U_MBMC_TOP|*|mbmc_io_dq_tri_en} -to {*ModuleName*U_MBMC_IO|*U_DQ|*.altera_gpio_bit_i|oe_path.oe_path_fr.oe_reg}   -hold  -end 2
 }

#-----------------------------------------------------------
#On CycleneV, the oe is registered
#-----------------------------------------------------------
if {"device_family" == "Cyclone V"  | "device_family" == "CYCLONE V"} {
   set_false_path -from {*ModuleName*U_MBMC_IO*dq_out_tri_180_r[*]} -to {*ModuleName*U_MBMC_IO*U_DQ*dffe1a[*]}
}

#-----------------------------------------------------------
# On Cyclone V, set false path on the mbmc_io_rds_valid_r signal
#-----------------------------------------------------------
if {"device_family" == "Cyclone V"     || "device_family" == "CYCLONE V" } {
   set_false_path -from [get_registers *ModuleName**mbmc_io_rds_valid_r]
}


#-----------------------------------------------------------
#setting false paths from inclk to reset
#-----------------------------------------------------------
set_false_path -from {*iavs0_rstn_*}
set_false_path -from {*mbmc_reset_ff3*}

set_false_path -to   {*iavs0_rstn_*}

