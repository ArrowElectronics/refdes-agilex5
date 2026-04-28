`timescale 1ps/1ps

//-----------------------------------------------------------------------------
//
//  Copyright(c) 2016 Synaptic Laboratories Limited (Synaptic Labs)
//
//  All rights reserved.
//
//  This document contains confidential and proprietary product to Synaptic Labs.
//
//  No part of this file may be copied, reproduced, disclosed or provided to
//  third parties without prior written consent of Synaptic Labs.
//
//  Synaptic Labs reserves the right to make changes in the content of this
//  file without prior notice.
//
//-----------------------------------------------------------------------------
//
//-----------------------------------------------------------------------------
//
//  THIS Verilog MODULE IS INTENDED FOR USE IN COMMERCIAL PRODUCTS.
//
//-----------------------------------------------------------------------------
//
//-----------------------------------------------------------------------------
//
//  Title          :  SLL xSPI Memory controller
//  Project        :  N/A
//
//  File           :  sll_xspi_mc_avmm_top.v
//  Author         :  Mark Bonnici
//
//  Email          :  mark.bonnici@synaptic-labs.com
//  Revision date  :  Jan/15/2017
//
//  Description    :  SLL  xSPI Memory controller top module
//
//
//  Known issues   :  None
//
//  References     :
//
//-----------------------------------------------------------------------------
//  Revision     Date         Author         Comments
//
//  Version1.0   15/Jan/2017   Mark     Initial Release
//  Version2.9   09/Mar/2017   Mark     Added MB_RSTn to  port list
//  Version 2.10 22/Mar/2017   Mark     Addded g_device_family parameter
//  Version2.11  03/May/2017   Mark     Added support for IS66WVH16M8ALL Hyper RAM initialisatiom
//  Version2.14  14/Jun/2017   Mark     changed MB_CSn to  MB_CS0n and MB_CS1n
//     																  changed input config/timing parameters depending on whether device exist
//                                      added read/write buffer configuration
//  Version 2.15  20/Jul/2017  Mark     adde g_include_var_latency variable
//  Version 3.1.2 30/Jul/2018  Mark     added g_include_dual_rwds_pin support
//  Version 3.1.5 28/Sep/2018  Mark     added phylite support
//  Version 3.1.5 28/Oct/2018  Mark     added Xcella RAM support (needs to be checked)
//  Version 3.1.5 28/Oct/2018  Mark     removed CK2  ck2_en GPO and IENOn
//  Version 3.1.5 30/Oct/2018  Mark     renamed input/output ports in modules sll_ca_xspi_mc_io and sll_ca_xspi_mc
//  Version3.1.5 30/Noc/2018   Mark     added support for distributed refresh rate configuration
//  Version3.1.10 12/Feb/2019  Mark     added g_config_sync_stages parameter
//  Version3.1.16 30/Jul/2019  Mark     added support for reg space memory stransfer
//  Version3.1.17 27/Jul/2019  Mark     added g_dev0_config_ext_i 
//  Version3.2.0  07/Oct/2019  mark     changed wrap mode as part of the incoming signals
//  Version3.2.4  19/10/202    mark     added ECC bit input 
//  Version3.3.65 19/10/202    mark      added g_support_mixed_dqin
//-----------------------------------------------------------------------------

module sll_ca_xspi_mc_top_wrapper (

   //Hyper bus clocks (externally generated)
    i_hbus_clk_0
   ,i_hbus_clk_90
    
   //outptu clocks 
   ,i_iavs0_clk
   ,i_iavs0_rstn    

   //
   //Ingress Read/write data port
   //  
   ,i_iavs0_do_rd
   ,i_iavs0_do_wr
   ,i_iavs0_addr
   ,i_iavs0_byteenable
   ,i_iavs0_burstcount
   ,i_iavs0_wdata
   ,o_iavs0_wait_request
   ,o_iavs0_rdata_valid
   ,o_iavs0_rdata
   ,o_iavs0_resp
   //
   //Hyper Bus Device Signals
   //
	 ,MB_CLK0
	 ,MB_CLK0n
	 ,MB_CS1n
	 ,MB_RWDS   
	 ,MB_DQ
	 ,MB_RSTn
   );                
 parameter g_memory_freq_in_mhz       = 100; //125 Mhz
 parameter g_iavs_freq_in_mhz         = 100; //125 Mhz
                                       
 parameter g_iavs0_addr_width         = 28;  //Address width
 parameter g_iavs0_data_width         = 32;  //Data width
 parameter g_iavs0_av_numsymbols      = 4;   //number of bytes in a word
 parameter g_iavs0_linewrap_burst     = 0;
 parameter g_iavs0_burstonboundaries  = 1;   //bursts on burst boundaries
 parameter g_iavs0_burstcount_width   = 4;   //burst count
 parameter g_iavs0_register_rdata     = 0;   //register rdata 
 parameter g_iavs0_register_wdata     = 0;   //register wdata 
 parameter g_iavs0_1k_translator      = 1;   //include 1k translator on the AVS channel                                      

 parameter g_same_iavs_memory_clk   = 1;


//Powerup timer width 
 parameter g_powerup_timer_width      =  (g_memory_freq_in_mhz< 6 ) ? 11 :
                                         (g_memory_freq_in_mhz< 12) ? 12 :
                                         (g_memory_freq_in_mhz< 25) ? 13 :
                                         (g_memory_freq_in_mhz< 51) ? 14 :
                                         (g_memory_freq_in_mhz<101) ? 15 : 16;
 
                                      
 parameter g_dqin_width               = 8;
 parameter g_dqs_width                = (g_dqin_width < 8) ? 1 : g_dqin_width/8;
                                      
 parameter g_rst_mode                 = 0;       //async reset (0) synct reset (1)

 parameter g_device_family            = "Agilex 5";   
 parameter g_fpga_vendor              = "Intel";



//hyperbus clock (externally generated)
input                                i_hbus_clk_0;
input                                i_hbus_clk_90;

   
//output clocks and resets
input                                i_iavs0_clk;
input                                i_iavs0_rstn;

//
// Read/write data port
//
input                                i_iavs0_do_rd;
input                                i_iavs0_do_wr;
input [g_iavs0_addr_width-1:0]       i_iavs0_addr ;
input [g_iavs0_av_numsymbols-1:0]    i_iavs0_byteenable;
input [g_iavs0_data_width-1:0]       i_iavs0_wdata;
input [g_iavs0_burstcount_width-1:0] i_iavs0_burstcount;
output                               o_iavs0_wait_request;
output                               o_iavs0_rdata_valid;
output  [g_iavs0_data_width-1:0]     o_iavs0_rdata ;
output [1:0]                         o_iavs0_resp;

//	
//Hyper Bus Device Siganls
//
output wire                              MB_RSTn;
output wire	                             MB_CLK0;
output wire	                             MB_CLK0n;
output wire													     MB_CS1n;
inout  wire	 [g_dqs_width -1:0]          MB_RWDS;
inout  wire	 [g_dqin_width-1:0]          MB_DQ;

 
	sll_xspi_mc_avmm_top #(         
      
       .g_iavs0_addr_width         (g_iavs0_addr_width         )
      ,.g_iavs0_data_width         (g_iavs0_data_width         )
      ,.g_iavs0_av_numsymbols      (g_iavs0_av_numsymbols      )
      ,.g_iavs0_linewrap_burst     (g_iavs0_linewrap_burst     )
      ,.g_iavs0_burstonboundaries  (g_iavs0_burstonboundaries  )
      ,.g_iavs0_burstcount_width   (g_iavs0_burstcount_width   )
      ,.g_iavs0_register_rdata     (g_iavs0_register_rdata     )
      ,.g_iavs0_register_wdata     (g_iavs0_register_wdata     )
      ,.g_iavs0_1k_translator      (g_iavs0_1k_translator      )
      
      ,.g_same_iavs_memory_clk     (g_same_iavs_memory_clk     )
       
      ,.g_powerup_timer_width      (g_powerup_timer_width      )
            
      ,.g_dqin_width               (g_dqin_width               )
      ,.g_dqs_width                (g_dqs_width                )
      
      ,.g_rst_mode                 (g_rst_mode                 )
      ,.g_device_family            (g_device_family            )
      ,.g_fpga_vendor              (g_fpga_vendor              )
	  ) U_MBMC_WRAPPER (
     .i_hbus_clk_0              (i_hbus_clk_0 )
    ,.i_hbus_clk_90             (i_hbus_clk_90)
	  ,.i_iavs0_clk               (i_iavs0_clk  )    
    ,.i_iavs0_rstn              (i_iavs0_rstn )

    //
    //Ingress Read/write data port
    //
    ,.i_iavs0_do_rd             (i_iavs0_do_rd       )
    ,.i_iavs0_do_wr             (i_iavs0_do_wr       )
    ,.i_iavs0_addr              (i_iavs0_addr        )
    ,.i_iavs0_byteenable        (i_iavs0_byteenable  )
    ,.i_iavs0_burstcount        (i_iavs0_burstcount  )
    ,.i_iavs0_wdata             (i_iavs0_wdata       )
    ,.o_iavs0_wait_request      (o_iavs0_wait_request)
    ,.o_iavs0_rdata_valid       (o_iavs0_rdata_valid )
    ,.o_iavs0_rdata             (o_iavs0_rdata       )
    ,.o_iavs0_resp              (o_iavs0_resp        )  

    //
    //Register Read/write data port
    //
    ,.i_iavsr_do_rd             (1'b0   )
    ,.i_iavsr_do_wr             (1'b0   )
    ,.i_iavsr_addr              (6'b0   )
    ,.i_iavsr_wdata             (32'b0  )
    ,.o_iavsr_rdata             (       )
    ,.o_iavsr_irq               (       )
          
    //Hyper Bus Device Siganls
   	,.MB_RSTOn                  (1'b1)
   	,.MB_INTn                   (1'b1)
   	,.MB_ECC                    (1'b0)
   	,.MB_RSTn                   (MB_RSTn )
   	,.MB_WPn                    (  )
   	,.MB_CLK0                   (MB_CLK0 )
   	,.MB_CLK0n                  (MB_CLK0n)
   	,.MB_CLK1                   ( )
   	,.MB_CLK1n                  ()
   	,.MB_CS0n                   ( )
   	,.MB_CS1n                   (MB_CS1n )
   	,.MB_RWDS                   (MB_RWDS )
   	,.MB_DQ                     (MB_DQ   )

//
// PHYlite control ports
//
    ,.wdata_oe                  ()
    ,.wdata_from_core           ()
    ,.wds_oe                    ()
    ,.wds_from_core             ()
    ,.clk_out_mux               ()
    ,.clkn_out_mux              ()
    ,.cs0n_out                  ()
    ,.cs1n_out                  ()
    ,.rdata_en                  ()
    ,.rdata_valid               (1'b0           )
    ,.rdata_to_core             (16'h0000       )
   );



endmodule

